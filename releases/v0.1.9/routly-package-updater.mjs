#!/usr/bin/env node
/*
 * The only privileged update entry point.  It intentionally uses absolute
 * executable paths and fixed argument shapes; release files are data, never
 * programs.  ROUTLY_*_COMMAND overrides exist solely for disposable
 * integration tests and must still be absolute paths.
 */
import { createHash, randomBytes, verify as verifySignature } from "node:crypto";
import { existsSync, lstatSync, readFileSync, mkdirSync, renameSync, unlinkSync, writeFileSync, openSync, fsyncSync, closeSync, readdirSync, readlinkSync, copyFileSync, chmodSync, rmSync } from "node:fs";
import { join, resolve, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { buildMigrationScript, loadMigrationPlan } from "./routly-migration-plan.mjs";
const TEST_MODE = process.env.ROUTLY_TEST_MODE === "1";
// PostgreSQL and journal files contain customer data and update state. Ensure
// every newly created file is private even when systemd or sudo supplies a
// permissive inherited umask.
process.umask(0o077);
const ROOT = process.env.ROUTLY_FILESYSTEM_ROOT || "/";
if (!TEST_MODE && (ROOT !== "/" || Object.keys(process.env).some(k => /^ROUTLY_(SYSTEMCTL|PG_DUMP|PG_RESTORE|PSQL|CURL|FLOCK)_COMMAND$/.test(k)))) {
  throw Error("test filesystem and command overrides require ROUTLY_TEST_MODE=1 with a non-root filesystem");
}
const at = p => ROOT === "/" ? p : join(ROOT, p);
const cmd = (name, fallback) => { const p = process.env[`ROUTLY_${name}_COMMAND`] || fallback; if (!p.startsWith("/")) throw Error(`${name} command must be absolute`); return p; };
const SYSTEMCTL = cmd("SYSTEMCTL", "/usr/bin/systemctl"), PGDUMP = cmd("PG_DUMP", "/usr/bin/pg_dump");
const PGRESTORE = cmd("PG_RESTORE", "/usr/bin/pg_restore"), PSQL = cmd("PSQL", "/usr/bin/psql");
const CURL = cmd("CURL", "/usr/bin/curl"), FLOCK = cmd("FLOCK", "/usr/bin/flock");
const STAGING = at("/var/lib/routly/agent/staging"), RELEASES = at("/opt/routly/releases");
const CURRENT = at("/opt/routly/current"), BACKUPS = at("/var/lib/routly/backups");
const UPDATER = at("/var/lib/routly/updater");
const JOURNAL = join(UPDATER, "update-journal.json"), LOCK = at("/run/lock/routly.lock");
const PUBKEY = at("/etc/routly/release-signing-public.pem"), ENVFILE = at("/etc/routly/routly.env");
const INSTANCE_ID = at("/etc/routly/instance-id");
const HOST_INTEGRATION_ALLOWLIST = new Map([
  ["etc/nginx/sites-available/routly.conf", ["etc/nginx/sites-available/routly.conf", 0o644]],
  ["etc/sudoers.d/routly-package-updater", ["etc/sudoers.d/routly-package-updater", 0o440]],
  ["usr/bin/routly-migrate.mjs", ["usr/bin/routly-migrate", 0o755]],
  ["usr/bin/routly-migration-plan.mjs", ["usr/bin/routly-migration-plan.mjs", 0o644]],
  ["usr/bin/routly-package-updater.mjs", ["usr/bin/routly-package-updater", 0o755]],
  ["usr/lib/routly/validate-package.sh", ["usr/lib/routly/validate-package.sh", 0o755]],
  ["usr/lib/systemd/system/routly-api.service", ["usr/lib/systemd/system/routly-api.service", 0o644]],
  ["usr/lib/systemd/system/routly-control-agent.service", ["usr/lib/systemd/system/routly-control-agent.service", 0o644]],
  ["usr/lib/sysusers.d/routly.conf", ["usr/lib/sysusers.d/routly.conf", 0o644]],
  ["usr/lib/tmpfiles.d/routly.conf", ["usr/lib/tmpfiles.d/routly.conf", 0o644]],
]);
const semver = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const ownedByRoot = st => st.uid === 0 || (process.env.ROUTLY_TEST_MODE === "1" && st.uid === process.getuid());
const fail = m => { console.error(`routly-package-updater: ${m}`); process.exitCode = 1; throw Error(m); };
const syncFile = path => { const fd = openSync(path, "r"); try { fsyncSync(fd); } finally { closeSync(fd); } };
const syncDirectory = path => { const fd = openSync(path, "r"); try { fsyncSync(fd); } finally { closeSync(fd); } };
function syncTree(path) {
  const stat = lstatSync(path);
  if (stat.isSymbolicLink()) return;
  if (stat.isFile()) return syncFile(path);
  if (!stat.isDirectory()) throw Error(`unsupported release entry: ${path}`);
  for (const name of readdirSync(path)) syncTree(join(path, name));
  syncDirectory(path);
}
function switchCurrentRelease(targetVersion, suffix) {
  const next = `${CURRENT}.${suffix}-${process.pid}`;
  try { unlinkSync(next); } catch {}
  run("/bin/ln", ["-s", `/opt/routly/releases/${targetVersion}`, next]);
  renameSync(next, CURRENT);
  syncDirectory(dirname(CURRENT));
}
function ensureInstanceIdentity() {
  mkdirSync(dirname(INSTANCE_ID), { recursive: true, mode: 0o755 });
  if (existsSync(INSTANCE_ID)) {
    const st = lstatSync(INSTANCE_ID);
    if (!st.isFile() || !ownedByRoot(st) || (st.mode & 0o077) || !/^[a-f0-9]{64}\n?$/i.test(readFileSync(INSTANCE_ID, "utf8"))) throw Error("unsafe instance identity");
    return;
  }
  const temporary = `${INSTANCE_ID}.new-${process.pid}`;
  const fd = openSync(temporary, "wx", 0o600);
  try { writeFileSync(fd, `${randomBytes(32).toString("hex")}\n`); fsyncSync(fd); } finally { closeSync(fd); }
  renameSync(temporary, INSTANCE_ID);
}
const run = (program, args, options = {}) => { const r = spawnSync(program, args, { stdio: "inherit", ...options }); if (r.error || r.status !== 0) throw Error(`${program} failed (${r.status ?? r.error?.message})`); };
const probeArgs = endpoint => ["--fail", "--silent", "--show-error", "--retry", "20", "--retry-connrefused",
  "--retry-delay", "1", "--retry-max-time", "60", "--connect-timeout", "2", "--max-time", "5",
  `http://127.0.0.1:${port}${endpoint}`];
const readProbe = endpoint => {
  const result = spawnSync(CURL, probeArgs(endpoint), { encoding: "utf8" });
  if (result.error || result.status !== 0) throw Error(`${CURL} failed (${result.status ?? result.error?.message})`);
  return result.stdout.trim().replace(/^"|"$/g, "");
};
const journal = phase => {
  mkdirSync(UPDATER, { recursive: true, mode: 0o700 });
  try { const old = lstatSync(JOURNAL); if (!old.isFile() || !ownedByRoot(old) || (old.mode & 0o077)) throw Error("unsafe journal"); } catch (e) { if (e.code !== "ENOENT") throw e; }
  const temporary = join(UPDATER, `.journal-${process.pid}-${phase}`);
  const fd = openSync(temporary, "wx", 0o600); writeFileSync(fd, JSON.stringify({ phase, version, previousVersion, backup: backupPath, hostBackup: hostBackupPath, port, at: new Date().toISOString() }) + "\n"); fsyncSync(fd); closeSync(fd); renameSync(temporary, JOURNAL); syncDirectory(UPDATER);
  // Simulate abrupt power loss only after the recovery record and everything
  // the phase depends on have reached durable storage.
  if (TEST_MODE && process.env.ROUTLY_TEST_EXIT_AFTER_PHASE === phase) process.exit(86);
};
const readJournal = () => {
  if (!existsSync(JOURNAL)) return null;
  const st = lstatSync(JOURNAL);
  if (!st.isFile() || !ownedByRoot(st) || (st.mode & 0o077)) throw Error("unsafe journal");
  const value = JSON.parse(readFileSync(JOURNAL, "utf8"));
  if (!semver.test(value.version) || !semver.test(value.previousVersion) ||
      !["validated", "downloaded", "backed_up", "stopped", "migrating", "migrated", "host_integrating", "activated", "healthy", "rolled_back", "manual_intervention"].includes(value.phase)) {
    throw Error("invalid update journal");
  }
  return value;
};
const removeJournal = () => {
  try { unlinkSync(JOURNAL); syncDirectory(UPDATER); }
  catch (e) { if (e.code !== "ENOENT") throw e; }
};
function validateHostIntegrations(manifest) {
  const integrations = manifest.hostIntegrations;
  if (!Array.isArray(integrations)) throw Error("invalid host integration list");
  const sources = new Set(), targets = new Set();
  for (const integration of integrations) {
    const allowed = HOST_INTEGRATION_ALLOWLIST.get(integration?.source);
    if (!allowed || integration.target !== allowed[0] || integration.mode !== allowed[1] ||
        sources.has(integration.source) || targets.has(integration.target)) {
      throw Error("invalid host integration mapping");
    }
    sources.add(integration.source);
    targets.add(integration.target);
  }
  const files = new Set(manifest.files?.map(file => file.path));
  if (integrations.some(integration => !files.has(integration.source))) throw Error("host integration is not verified by manifest");
  return integrations;
}
function safeHostTarget(relative) {
  const target = at(`/${relative}`);
  let parent = dirname(target);
  while (parent !== ROOT && parent !== "/") {
    if (existsSync(parent) && lstatSync(parent).isSymbolicLink()) throw Error(`host integration parent is a symlink: ${relative}`);
    parent = dirname(parent);
  }
  if (existsSync(target) && (!lstatSync(target).isFile() || lstatSync(target).isSymbolicLink())) throw Error(`unsafe host integration target: ${relative}`);
  return target;
}
function installHostIntegrations(work, integrations) {
  const pendingBackupPath = join(UPDATER, `host-backup-${version}-${process.pid}`);
  mkdirSync(pendingBackupPath, { recursive: true, mode: 0o700 });
  const absent = [], modes = {};
  for (const { source: sourcePath, target: targetPath } of integrations) {
    const source = join(work, sourcePath), target = safeHostTarget(targetPath);
    if (!lstatSync(source).isFile()) throw Error(`host integration source is not a file: ${sourcePath}`);
    if (existsSync(target)) {
      modes[targetPath] = lstatSync(target).mode & 0o777;
      const backup = join(pendingBackupPath, targetPath);
      mkdirSync(dirname(backup), { recursive: true, mode: 0o700 });
      copyFileSync(target, backup);
      chmodSync(backup, 0o600);
      syncFile(backup);
      syncDirectory(dirname(backup));
    } else absent.push(targetPath);
  }
  const statePath = join(pendingBackupPath, "state.json");
  writeFileSync(statePath, JSON.stringify({ targets: integrations.map(value => value.target), absent, modes }) + "\n", { mode: 0o600 });
  syncFile(statePath);
  syncDirectory(pendingBackupPath);
  syncDirectory(UPDATER);
  hostBackupPath = pendingBackupPath;
  journal("host_integrating");
  for (const { source: sourcePath, target: targetPath, mode } of integrations) {
    const source = join(work, sourcePath), target = safeHostTarget(targetPath);
    mkdirSync(dirname(target), { recursive: true, mode: 0o755 });
    const temporary = `${target}.routly-new-${process.pid}`;
    copyFileSync(source, temporary);
    chmodSync(temporary, mode);
    syncFile(temporary);
    renameSync(temporary, target);
    syncDirectory(dirname(target));
  }
}
function restoreHostIntegrations(path) {
  if (!path || !existsSync(join(path, "state.json"))) throw Error("host integration backup unavailable");
  const state = JSON.parse(readFileSync(join(path, "state.json"), "utf8"));
  const allowedTargets = new Set([...HOST_INTEGRATION_ALLOWLIST.values()].map(([target]) => target));
  for (const relative of state.targets) {
    if (!allowedTargets.has(relative)) throw Error("unsafe host integration backup");
    const target = safeHostTarget(relative);
    if (state.absent.includes(relative)) {
      try { unlinkSync(target); syncDirectory(dirname(target)); } catch (e) { if (e.code !== "ENOENT") throw e; }
    } else {
      const source = join(path, relative), temporary = `${target}.routly-restore-${process.pid}`;
      copyFileSync(source, temporary);
      if (!Number.isInteger(state.modes?.[relative])) throw Error("host integration backup mode unavailable");
      chmodSync(temporary, state.modes[relative]);
      syncFile(temporary);
      renameSync(temporary, target);
      syncDirectory(dirname(target));
    }
  }
}
const parseDatabaseUrl = () => {
  if (!existsSync(ENVFILE)) throw Error("root-owned environment file is missing");
  const st = lstatSync(ENVFILE); if (!ownedByRoot(st) || (st.mode & 0o002)) throw Error("environment file ownership or mode is unsafe");
  const line = readFileSync(ENVFILE, "utf8").split(/\r?\n/).find(x => /^\s*DATABASE_URL\s*=/.test(x));
  if (!line) throw Error("DATABASE_URL is required for safe update");
  const value = line.replace(/^\s*DATABASE_URL\s*=\s*/, "").trim().replace(/^(['"])(.*)\1$/, "$2");
  if (!value || /[\r\n]/.test(value)) throw Error("invalid DATABASE_URL");
  return value;
};
if (process.argv.length !== 3 || !semver.test(process.argv[2])) throw Error("usage: <exact-version>");
if (!process.env.ROUTLY_LOCK_HELD) {
  mkdirSync(join(at("/run"), "lock"), { recursive: true, mode: 0o755 });
  const locked = spawnSync(FLOCK, ["-n", LOCK, process.execPath, new URL(import.meta.url).pathname, process.argv[2]], {
    stdio: "inherit", env: { ...process.env, ROUTLY_LOCK_HELD: "1" },
  });
  process.exit(locked.status ?? 1);
}
const version = process.argv[2], archive = join(STAGING, `routly-node-${version}-linux-amd64.tar.gz`);
let previousVersion = "0.0.0", backupPath = "", hostBackupPath = "", port = 4100;
let archiveSnapshot = "";
let apiStopped = false, backupVerified = false;
try {
  /*
   * The journal is the recovery record, not a progress log.  A process can
   * disappear between any two commands, so an old record is completed before
   * accepting a new request.  Pre-stop records are safe to discard; every
   * later record leaves the service stopped until its rollback is verified.
   */
  const interrupted = readJournal();
  if (interrupted?.phase === "manual_intervention") {
    throw Error("MANUAL INTERVENTION REQUIRED: unresolved prior update recovery");
  }
  if (interrupted && interrupted.phase !== "healthy" && interrupted.phase !== "rolled_back") {
    previousVersion = interrupted.previousVersion;
    backupPath = interrupted.backup || "";
    hostBackupPath = interrupted.hostBackup || "";
    port = interrupted.port || 4100;
    if (["stopped", "backed_up"].includes(interrupted.phase)) {
      try { run(SYSTEMCTL, ["restart", "routly-api.service"]); run(CURL, probeArgs("/api/healthz")); removeJournal(); }
      catch (e) { journal("manual_intervention"); throw Error(`MANUAL INTERVENTION REQUIRED: ${e.message}`); }
    } else if (["migrating", "migrated", "host_integrating", "activated"].includes(interrupted.phase)) {
      try {
        run(SYSTEMCTL, ["stop", "routly-api.service"]);
        if (existsSync(CURRENT) && !lstatSync(CURRENT).isSymbolicLink()) throw Error("current release path is not a symlink");
        if (previousVersion !== "0.0.0" && existsSync(join(RELEASES, previousVersion))) {
          switchCurrentRelease(previousVersion, "recovery");
        }
        if (hostBackupPath) {
          restoreHostIntegrations(hostBackupPath);
          run(SYSTEMCTL, ["daemon-reload"]);
        }
        if (!backupPath || !existsSync(backupPath)) throw Error("verified backup unavailable");
        const db = parseDatabaseUrl();
        run(PGRESTORE, ["--list", backupPath]);
        run(PGRESTORE, ["--single-transaction", "--clean", "--if-exists", "--no-owner", "--dbname", db, backupPath]);
        run(SYSTEMCTL, ["restart", "routly-api.service"]);
        run(CURL, probeArgs("/api/healthz"));
        const prior = readProbe("/api/version");
        if (prior !== previousVersion) throw Error(`rollback reported ${prior}, expected ${previousVersion}`);
        journal("rolled_back"); removeJournal();
      } catch (e) {
        journal("manual_intervention");
        throw Error(`MANUAL INTERVENTION REQUIRED: ${e.message}`);
      }
    } else removeJournal();
  } else if (interrupted) removeJournal();
  let currentStat;
  try { currentStat = lstatSync(CURRENT); } catch (e) { if (e.code !== "ENOENT") throw e; }
  if (currentStat) {
    if (!currentStat.isSymbolicLink()) throw Error("current release path is not a symlink");
    const target = readlinkSync(CURRENT);
    if (!target.startsWith("/opt/routly/releases/")) throw Error("current release symlink target is not an absolute release path");
    previousVersion = target.slice("/opt/routly/releases/".length);
    if (!semver.test(previousVersion) || target !== `/opt/routly/releases/${previousVersion}`) {
      throw Error("current release symlink target is not an exact strict-semver release");
    }
  }
  if (!semver.test(previousVersion)) throw Error("current release is not strict semver");
  const stagingOwner = lstatSync(STAGING).uid;
  for (const p of [archive, join(STAGING, "release-metadata.json"), join(STAGING, "release-metadata.sig")]) {
    const st = lstatSync(p); if (!st.isFile() || st.uid !== stagingOwner || (st.mode & 0o002)) throw Error("unsafe staging file");
  }
  const metadataBytes = readFileSync(join(STAGING, "release-metadata.json"));
  const signatureBytes = readFileSync(join(STAGING, "release-metadata.sig"));
  const meta = JSON.parse(metadataBytes);
  if (meta.version !== version || !/^https:\/\//.test(meta.artifactUrl) || !/^[0-9a-f]{64}$/.test(meta.packageSha256)) throw Error("invalid release metadata");
  const canonical = JSON.stringify({ version, artifactUrl: meta.artifactUrl, packageSha256: meta.packageSha256 }) + "\n";
  if (!existsSync(PUBKEY) || !verifySignature(null, Buffer.from(canonical), readFileSync(PUBKEY), signatureBytes)) throw Error("release signature verification failed");
  mkdirSync(UPDATER, { recursive: true, mode: 0o700 });
  const snapshotDirectory = join(UPDATER, `verified-${version}-${process.pid}`);
  mkdirSync(snapshotDirectory, { mode: 0o700 });
  archiveSnapshot = join(snapshotDirectory, basename(archive));
  const snapshotTemporary = `${archiveSnapshot}.new`;
  copyFileSync(archive, snapshotTemporary);
  chmodSync(snapshotTemporary, 0o600);
  syncFile(snapshotTemporary);
  renameSync(snapshotTemporary, archiveSnapshot);
  syncDirectory(snapshotDirectory);
  syncDirectory(UPDATER);
  if (createHash("sha256").update(readFileSync(archiveSnapshot)).digest("hex") !== meta.packageSha256) throw Error("package checksum mismatch");
  const validator = at("/usr/lib/routly/validate-package.sh");
  const sidecar = `${archive}.sha256`;
  if (!existsSync(validator)) throw Error("package validator is missing");
  if (!existsSync(sidecar)) throw Error("package checksum sidecar is missing");
  const snapshotSidecar = `${archiveSnapshot}.sha256`;
  writeFileSync(snapshotSidecar, `${meta.packageSha256}  ${basename(archiveSnapshot)}\n`, { mode: 0o600 });
  syncFile(snapshotSidecar);
  run(validator, [archiveSnapshot, meta.packageSha256]);
  journal("validated");
  const work = join(UPDATER, `candidate-${version}-${process.pid}`); mkdirSync(work, { recursive: true, mode: 0o700 });
  run("/usr/bin/tar", ["--no-same-owner", "--no-same-permissions", "-xzf", archiveSnapshot, "-C", work]);
  const candidate = join(work, "opt/routly/releases", version), manifest = join(candidate, "release-manifest.json");
  if (!existsSync(manifest) || !existsSync(join(candidate, "migrations"))) throw Error("release manifest or immutable migrations missing");
  const hostIntegrations = validateHostIntegrations(JSON.parse(readFileSync(manifest, "utf8")));
  journal("downloaded");
  const db = parseDatabaseUrl();
  const portLine = readFileSync(ENVFILE, "utf8").split(/\r?\n/).find(x => /^\s*PORT\s*=/.test(x));
  port = portLine ? Number(portLine.replace(/^\s*PORT\s*=\s*/, "").trim()) : 4100;
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw Error("invalid PORT");
  mkdirSync(BACKUPS, { recursive: true, mode: 0o700 });
  backupPath = join(BACKUPS, `routly-${new Date().toISOString().replace(/[-:TZ.]/g, "").slice(0, 14)}-${previousVersion}.dump`);
   run(SYSTEMCTL, ["stop", "routly-api.service"]); apiStopped = true; journal("stopped");
   run(PGDUMP, ["--format=custom", "--file", backupPath, db]);
  const bst = lstatSync(backupPath); if (!ownedByRoot(bst) || (bst.mode & 0o077)) throw Error("backup permissions are unsafe");
  run(PGRESTORE, ["--list", backupPath]);
  syncFile(backupPath);
  syncDirectory(BACKUPS);
  backupVerified = true; journal("backed_up");
   const plan = loadMigrationPlan(join(candidate, "migrations"));
   journal("migrating");
   const generated = join(UPDATER, `migrations-${process.pid}.sql`);
   writeFileSync(generated, buildMigrationScript(plan), { mode: 0o600 });
   try { run(PSQL, [db, "-v", "ON_ERROR_STOP=1", "-f", generated]); } finally { try { unlinkSync(generated); } catch {} }
  journal("migrated");
  const installed = join(RELEASES, version); mkdirSync(RELEASES, { recursive: true, mode: 0o755 }); if (existsSync(installed)) throw Error("release already installed");
   syncTree(candidate);
   renameSync(candidate, installed);
   syncDirectory(RELEASES);
   installHostIntegrations(work, hostIntegrations);
   switchCurrentRelease(version, "new"); journal("activated");
  ensureInstanceIdentity();
  run(SYSTEMCTL, ["daemon-reload"]); run(SYSTEMCTL, ["restart", "routly-api.service"]);
  run(CURL, probeArgs("/api/healthz"));
  const check = readProbe("/api/version");
  if (check !== version) throw Error(`health reported ${check}, expected ${version}`);
  journal("healthy");
  // Retention is deliberately performed only after the new service has passed
  // both probes.  Never delete evidence needed by an in-flight rollback.
  const retained = readdirSync(BACKUPS).filter(name => /^routly-.*\.dump$/.test(name)).sort().reverse();
  for (const name of retained.slice(5)) {
    const p = join(BACKUPS, name);
    const st = lstatSync(p);
    if (st.isFile() && st.uid === 0 && (st.mode & 0o077) === 0) unlinkSync(p);
  }
  removeJournal();
  if (hostBackupPath) rmSync(hostBackupPath, { recursive: true, force: true });
  if (archiveSnapshot) {
    rmSync(dirname(archiveSnapshot), { recursive: true, force: true });
  }
} catch (error) {
  console.error(error.message);
   if (apiStopped && !backupVerified) {
     try { run(SYSTEMCTL, ["restart", "routly-api.service"]); run(CURL, probeArgs("/api/healthz")); removeJournal(); }
     catch (restartError) { journal("manual_intervention"); console.error(`MANUAL INTERVENTION REQUIRED: ${restartError.message}`); }
   } else if (!apiStopped || !backupVerified) { process.exitCode = 1; }
  else try {
    run(SYSTEMCTL, ["stop", "routly-api.service"]);
    if (previousVersion !== "0.0.0" && existsSync(join(RELEASES, previousVersion))) switchCurrentRelease(previousVersion, "rollback");
    if (hostBackupPath) {
      restoreHostIntegrations(hostBackupPath);
      run(SYSTEMCTL, ["daemon-reload"]);
    }
    if (backupPath && existsSync(backupPath)) {
      const db = parseDatabaseUrl();
       run(PGRESTORE, ["--list", backupPath]);
       run(PGRESTORE, ["--single-transaction", "--clean", "--if-exists", "--no-owner", "--dbname", db, backupPath]);
      run(SYSTEMCTL, ["restart", "routly-api.service"]);
      run(CURL, probeArgs("/api/healthz"));
      const prior = readProbe("/api/version");
      if (prior !== previousVersion) throw Error(`rollback reported ${prior}, expected ${previousVersion}`);
      journal("rolled_back");
    }
    else throw Error("verified backup unavailable");
  } catch (rollbackError) { journal("manual_intervention"); console.error(`MANUAL INTERVENTION REQUIRED: ${rollbackError.message}`); }
  process.exitCode = 1;
}