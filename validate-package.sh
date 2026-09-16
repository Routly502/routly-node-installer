#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 && $# -le 2 ]] ||
  { echo "usage: $0 ARCHIVE.tar.gz [EXPECTED_SHA256]" >&2; exit 2; }
ARCHIVE=$1
EXPECTED=${2:-}
SIDECAR="$ARCHIVE.sha256"
[[ -f "$ARCHIVE" ]] || { echo "Archive not found: $ARCHIVE" >&2; exit 2; }
[[ -f "$SIDECAR" ]] || { echo "Checksum sidecar not found: $SIDECAR" >&2; exit 2; }
for command in node python3 sha256sum; do
  command -v "$command" >/dev/null || { echo "Missing prerequisite: $command" >&2; exit 2; }
done

ARCHIVE_BASENAME=$(basename "$ARCHIVE")
mapfile -t CHECKSUM_LINES < "$SIDECAR"
[[ ${#CHECKSUM_LINES[@]} -eq 1 ]] || { echo "Checksum sidecar must contain one line" >&2; exit 1; }
[[ "${CHECKSUM_LINES[0]}" =~ ^([0-9a-f]{64})\ \ ([^/]+)$ ]] ||
  { echo "Malformed checksum sidecar" >&2; exit 1; }
SIDECAR_HASH=${BASH_REMATCH[1]}
[[ "${BASH_REMATCH[2]}" == "$ARCHIVE_BASENAME" ]] ||
  { echo "Checksum sidecar filename mismatch" >&2; exit 1; }
if [[ -n "$EXPECTED" ]]; then
  [[ "$EXPECTED" =~ ^[0-9a-f]{64}$ ]] || { echo "Expected SHA-256 is malformed" >&2; exit 2; }
  [[ "$EXPECTED" == "$SIDECAR_HASH" ]] || { echo "Expected SHA-256 does not match sidecar" >&2; exit 1; }
fi
ACTUAL_HASH=$(sha256sum "$ARCHIVE" | awk '{print $1}')
[[ "$ACTUAL_HASH" == "$SIDECAR_HASH" ]] || { echo "Archive SHA-256 mismatch" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
python3 - "$ARCHIVE" "$TMP/regular-files" "$TMP/all-paths" <<'PY'
import posixpath
import sys
import tarfile

archive, regular_out, paths_out = sys.argv[1:]
with tarfile.open(archive, "r:gz") as package:
    members = package.getmembers()

canonical = {}
symlinks = set()
regular = []
for member in members:
    name = member.name[2:] if member.name.startswith("./") else member.name
    if name == "." and member.isdir():
        continue
    if not name or name.startswith("/") or name != posixpath.normpath(name) or ".." in name.split("/"):
        raise SystemExit(f"unsafe archive path: {member.name!r}")
    if name in canonical:
        raise SystemExit(f"duplicate archive path: {name}")
    canonical[name] = member
    if member.islnk() or member.isdev() or member.isfifo():
        raise SystemExit(f"unsupported archive entry type: {name}")
    if not (member.isfile() or member.isdir() or member.issym()):
        raise SystemExit(f"unsupported archive entry type: {name}")
    if member.isfile():
        regular.append(name)
    elif member.issym():
        symlinks.add(name)

for name, member in canonical.items():
    parts = name.split("/")
    if any("/".join(parts[:index]) in symlinks for index in range(1, len(parts))):
        raise SystemExit(f"archive entry traverses a symlink: {name}")
    if member.issym():
        api_modules = "/api/node_modules/"
        if api_modules not in f"/{name}/" or posixpath.isabs(member.linkname):
            raise SystemExit(f"symlink outside packaged node_modules: {name}")
        target = posixpath.normpath(posixpath.join(posixpath.dirname(name), member.linkname))
        if target.startswith("../") or api_modules not in f"/{target}/" or target not in canonical:
            raise SystemExit(f"unsafe or missing symlink target: {name} -> {member.linkname}")

with open(regular_out, "w", encoding="utf-8") as output:
    output.write("".join(f"{name}\n" for name in sorted(regular)))
with open(paths_out, "w", encoding="utf-8") as output:
    output.write("".join(f"{name}\n" for name in sorted(canonical)))
PY

if grep -E '(^|/)\.git(hub|ignore|attributes|keep)?(/|$)|(^|/)\.env($|/)' "$TMP/all-paths"; then
  echo "Forbidden repository metadata or environment file in package" >&2
  exit 1
fi
if grep -v '/node_modules/' "$TMP/all-paths" |
  grep -Ei '(^|/).*(secret|password|token|credential|database).*($|/)'; then
  echo "Forbidden or secret-looking path in package" >&2
  exit 1
fi

tar --no-same-owner --no-same-permissions -xzf "$ARCHIVE" -C "$TMP"
node - "$TMP" "$TMP/regular-files" "$ARCHIVE_BASENAME" <<'NODE'
const fs = require("node:fs");
const crypto = require("node:crypto");
const path = require("node:path");
const [root, inventoryPath, archiveName] = process.argv.slice(2);
const semver = "(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)";
const archiveMatch = archiveName.match(new RegExp(`^routly-node-(${semver})-linux-amd64\\.tar\\.gz$`));
if (!archiveMatch) throw Error("invalid archive filename");
const version = archiveMatch[1];
const manifestRelative = `opt/routly/releases/${version}/release-manifest.json`;
const manifestPath = path.join(root, manifestRelative);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
if (manifest.product !== "routly-node" || manifest.version !== version ||
    manifest.platform !== "linux" || manifest.architecture !== "amd64" ||
    manifest.packageSchemaVersion !== 1) throw Error("manifest identity mismatch");
const releasePath = `/opt/routly/releases/${version}`;
if (manifest.releasePath !== releasePath || manifest.agentStatus !== "dormant") {
  throw Error("invalid release metadata");
}
const expectedComponents = {
  web: `${releasePath}/web`,
  api: `${releasePath}/api`,
  agent: `${releasePath}/agent`,
};
if (JSON.stringify(manifest.components) !== JSON.stringify(expectedComponents)) {
  throw Error("invalid component paths");
}
if (!Array.isArray(manifest.files)) throw Error("manifest files must be an array");
const allowedHostIntegrations = new Map([
  ["etc/nginx/sites-available/routly.conf", ["etc/nginx/sites-available/routly.conf", 0o644]],
  ["etc/sudoers.d/routly-package-updater", ["etc/sudoers.d/routly-package-updater", 0o440]],
  ["usr/bin/routly-migrate.mjs", ["usr/bin/routly-migrate", 0o755]],
  ["usr/bin/routly-migration-plan.mjs", ["usr/bin/routly-migration-plan.mjs", 0o644]],
  ["usr/bin/routly-package-updater.mjs", ["usr/bin/routly-package-updater", 0o755]],
   ["usr/bin/routly-uninstall", ["usr/bin/routly-uninstall", 0o755]],
  ["usr/lib/routly/validate-package.sh", ["usr/lib/routly/validate-package.sh", 0o755]],
  ["usr/lib/systemd/system/routly-api.service", ["usr/lib/systemd/system/routly-api.service", 0o644]],
  ["usr/lib/systemd/system/routly-control-agent.service", ["usr/lib/systemd/system/routly-control-agent.service", 0o644]],
  ["usr/lib/sysusers.d/routly.conf", ["usr/lib/sysusers.d/routly.conf", 0o644]],
  ["usr/lib/tmpfiles.d/routly.conf", ["usr/lib/tmpfiles.d/routly.conf", 0o644]],
]);
if (!Array.isArray(manifest.hostIntegrations)) throw Error("invalid host integration list");
const integrationSources = new Set();
const integrationTargets = new Set();
for (const integration of manifest.hostIntegrations) {
  const allowed = allowedHostIntegrations.get(integration?.source);
  if (!allowed || integration.target !== allowed[0] || integration.mode !== allowed[1] ||
      integrationSources.has(integration.source) || integrationTargets.has(integration.target)) {
    throw Error("invalid host integration mapping");
  }
  integrationSources.add(integration.source);
  integrationTargets.add(integration.target);
}
const allowed = [
  `opt/routly/releases/${version}/`,
  "etc/routly/",
  "etc/nginx/sites-available/",
  "usr/lib/systemd/system/",
  "usr/lib/tmpfiles.d/",
  "usr/lib/sysusers.d/",
  "usr/lib/routly/",
  "usr/bin/",
  "etc/sudoers.d/",
];
const listed = new Set();
for (const file of manifest.files) {
  if (!file || typeof file.path !== "string" || !/^[0-9a-f]{64}$/.test(file.sha256) ||
      file.path.startsWith("/") || path.posix.normalize(file.path) !== file.path ||
      !allowed.some(prefix => file.path.startsWith(prefix)) || listed.has(file.path)) {
    throw Error(`invalid manifest file entry: ${file?.path}`);
  }
  listed.add(file.path);
  const absolute = path.join(root, file.path);
  if (!fs.lstatSync(absolute).isFile()) throw Error(`manifest entry is not a regular file: ${file.path}`);
  const actual = crypto.createHash("sha256").update(fs.readFileSync(absolute)).digest("hex");
  if (actual !== file.sha256) throw Error(`checksum mismatch: ${file.path}`);
}
const regular = fs.readFileSync(inventoryPath, "utf8").trim().split("\n").filter(Boolean);
const expected = regular.filter(file => file !== manifestRelative).sort();
const actual = [...listed].sort();
if (JSON.stringify(actual) !== JSON.stringify(expected)) {
  throw Error("manifest does not exactly cover every regular package file");
}
for (const integration of manifest.hostIntegrations) {
  if (!listed.has(integration.source)) throw Error(`host integration is not covered by manifest: ${integration.source}`);
}
NODE
echo "Package validation passed: $ARCHIVE"