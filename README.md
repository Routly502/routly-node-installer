# Routly distribution update protocol

## Instalación de Ubuntu con un solo comando

El repositorio público de instalación publica `bootstrap.sh`, `install.sh`,
`validate-package.sh` y artefactos inmutables por cada versión marcada con un
GitHub Release. En un servidor Ubuntu
22.04 LTS o posterior, el ISP ejecuta solamente:

```sh
curl -fsSL https://raw.githubusercontent.com/Routly502/routly-node-installer/main/bootstrap.sh | sudo bash
```

Para reinstalar una instalación usando su llave pública estable `rlic1`, el
mismo comando acepta la llave pegada en el prompt (no es necesario preservar
variables con `sudo`):

```sh
curl -fsSL https://raw.githubusercontent.com/Routly502/routly-node-installer/main/bootstrap.sh | sudo bash
# Código de activación: rlic1....
```

El bootstrap solo contacta al Control oficial
`https://routly-isp-management.replit.app`; una llave con otro origen se
rechaza antes de realizar cualquier solicitud de red.

El bootstrap instala Node.js 22, nginx y PostgreSQL; crea credenciales locales
aleatorias; descarga el último archivo versionado; valida su SHA-256 y su
manifiesto; ejecuta el instalador auditado; y muestra la URL y contraseña
temporal. Nunca se solicita ni almacena una credencial de GitHub en el servidor.
El API y PostgreSQL permanecen en loopback; solamente nginx sirve la interfaz
administrativa en `http://IP/admin`. La raíz no expone la administración y
`/cliente` queda reservado para el futuro portal de suscriptores.

## Routly Node package (roadmap step 5)

`package-release.sh` creates a non-installing Ubuntu package. It supports Ubuntu
22.04 LTS and newer on Linux amd64, with Node.js 22 or newer, nginx, and an external
PostgreSQL 14+ service. PostgreSQL is never included. The build host needs
`pnpm` 10, GNU tar, gzip, sha256sum, Python 3, and the checked-out workspace
dependencies.

```sh
SOURCE_DATE_EPOCH=1700000000 distribution/package-release.sh 1.2.3 ./dist
distribution/validate-package.sh ./dist/routly-node-1.2.3-linux-amd64.tar.gz
# An installer must also pass the SHA-256 obtained from trusted Control metadata:
distribution/validate-package.sh ./dist/routly-node-1.2.3-linux-amd64.tar.gz EXPECTED_SHA256
```

The archive contains `/opt/routly/releases/1.2.3/{web,api,agent}`,
`/etc/routly/routly.env.example`, an nginx site template, systemd units, and
declarative sysusers/tmpfiles definitions. The API listens on loopback
(`HOST=127.0.0.1`); nginx serves the SPA and proxies `/api` without rewriting
the path. Services log to journald. Agent state belongs in
`/var/lib/routly/agent`. The `routly` service account owns runtime state;
release files are root-owned and immutable in normal operation.

The installer and uninstaller are `install.sh` and `uninstall.sh` and are
distributed alongside the archive (they are not payload files and therefore do
not change the archive manifest). `install.sh` is strictly for an initial
installation; it refuses to replace an existing `/opt/routly/current`.
All upgrades go through the signed package updater. Install only with a trusted checksum:

```sh
sudo distribution/install.sh ./dist/routly-node-1.2.3-linux-amd64.tar.gz SHA256
sudo distribution/uninstall.sh
```

Installation validates the archive before extraction, takes one shared lock for
install/update/uninstall, atomically switches `/opt/routly/current`, preserves
an existing environment file, and enables only the API and nginx. The Control
agent is enabled only when its HTTPS origin, installation credential, and
pinned Ed25519 release key are configured. It downloads into
`/var/lib/routly/agent/staging` and invokes only the root-owned fixed package
updater; it cannot execute release-provided commands.
`ROUTLY_FILESYSTEM_ROOT` plus command-path variables such as
`ROUTLY_SYSTEMCTL_COMMAND` are available for no-root integration tests.

The environment file includes
`ROUTLY_NODE_MODE=node`, local authentication, database, licensing, storage,
and Control-agent settings. Routly Node does not use Clerk; Clerk remains
exclusive to Routly Control. Never put secrets in the package or source tree.
Each new installation requires a unique `ROUTLY_INITIAL_ADMIN_PASSWORD` in the
root-owned environment file and forces replacement after the first login.
The installer requires a configured `DATABASE_URL`, then applies the immutable
ordered Node migrations from the release before enabling API or nginx. The
runner reads the root-owned environment file as data (never by sourcing it),
uses a transaction/advisory lock, and records SHA-256 migration entries.
PostgreSQL content, `/etc/routly`, and `/var/lib/routly` (including uploads,
agent state, and backups) are retained by the uninstaller. No purge mode exists
in step 5.

The manifest records the exact version, platform, architecture, component
paths, and SHA-256 checksums. Builds use sorted tar entries, uid/gid zero, and
`SOURCE_DATE_EPOCH` (or the documented fallback epoch) so identical inputs
produce identical archives. Source maps, git metadata, state, databases, and
environment files are excluded.

The included Control agent is marked `dormant` in the manifest and must not be
enabled yet. Its package-aware privileged updater and atomic activation/rollback
helper belong to roadmap step 6. The service unit includes a condition that
prevents startup until that helper exists.

Control is only a coordinator. It queues an immutable release; after step 6,
each ISP's authenticated polling agent will perform its own code update and
report its observed version and attempt result.

## Control and Ubuntu agent setup (roadmap step 7)

Configure Routly Control with these server environment variables (never commit either
secret or display the private key):

* `ROUTLY_UPDATE_ORIGIN` — the exact HTTPS origin serving signed archives, for
  example `https://updates.example.net` (scheme, host, and optional port only;
  no path, query, or fragment).
* `ROUTLY_RELEASE_SIGNING_PRIVATE_KEY` — the signing key used by Control.
* Optionally `ROUTLY_CONTROL_URL` and
  `ROUTLY_RELEASE_SIGNING_PUBLIC_KEY_PATH` (the latter defaults to
  `/etc/routly/release-signing-public.pem`).

The Control readiness panel reports missing configuration without revealing key
contents. An administrator binds the installation to its ISP account and plan,
then generates a one-time enrollment code. The code expires after 15 minutes.
The public bootstrap reads it from the terminal without echo, exchanges it over
HTTPS from a permission-restricted request file, and receives the installation
identity, license trust, update trust, and agent credential as one package.
Control stores only hashes of the one-time code and agent credential.

The bootstrap writes the agent token to the root-owned environment file and the
release public key to `/etc/routly/release-signing-public.pem`; neither private
signing key leaves Control. A partially completed run keeps its already redeemed
package under `/etc/routly` with mode 0600, so retrying does not consume another
code. A completed installation refuses to overwrite its valid local credentials.

The Ubuntu agent must have these exact variables:

The agent sends `POST /api/control/agent/installations/{id}/heartbeat` with `X-Routly-Installation-Token`, its running strict semantic `currentVersion`, and status. A non-null assignment provides the immutable tag, commit SHA, and archive SHA-256. It persists one attempt ID and any unsent terminal report atomically, then resumes that same assignment after a process restart. Retrying the same attempt ID is idempotent.

## Installation agent

The agent requires
`ROUTLY_CONTROL_URL`, `ROUTLY_CONTROL_INSTALLATION_ID`,
`ROUTLY_CONTROL_INSTALLATION_TOKEN`, `ROUTLY_VERSION_URL`,
`ROUTLY_UPDATE_ORIGIN`, and activation and
updater commands supplied by later roadmap work. `ROUTLY_VERSION_URL` must
point to that ISP installation's local `GET /api/version` endpoint, never to
Routly Control. Agent state belongs under `/var/lib/routly/agent`.

For existing Replit/GitHub-linked installations, the GitHub-linked deployment
remains responsible for deployment and restarts. That legacy process does not
install this Ubuntu archive.

## Safe code-only rollout

Copy `update-from-release.sh` into the private `routly-distribution` repository and invoke it with the assigned `githubTag` and `artifactChecksum`. It refuses dirty code, malformed tags/checksums, untagged rollback states, checksum mismatches, dependency/build failures, and failed health checks. It restores the prior immutable code tag automatically on failure.

Ubuntu step 6 takes a mode-0600 PostgreSQL custom-format backup, verifies it
with `pg_restore --list`, runs only the ordered migrations packaged in the
release, and restores that same backup during rollback while the API is
stopped. Failed releases, journals, backups, and logs are retained. The
installer/update path never copies secrets, uploads, or object storage.

## Publishing

Use strict `X.Y.Z` versions and an immutable `vX.Y.Z` tag. Record the tag's 40-hex commit SHA and SHA-256 from `git archive --format=tar vX.Y.Z | sha256sum` in Control. Control rejects missing metadata, mismatched version/tag values, duplicate versions, and non-monotonic publication. Tag verification is local; Control intentionally does not call GitHub.

## License signing key rotation

Start a transition by configuring Control with the new `ROUTLY_LICENSE_PRIVATE_KEY` and `ROUTLY_LICENSE_KEY_ID`, plus the retiring key in `ROUTLY_LICENSE_PREVIOUS_PRIVATE_KEY`, `ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY`, and `ROUTLY_LICENSE_PREVIOUS_KEY_ID`. Set `ROUTLY_LICENSE_PREVIOUS_VALID_UNTIL` to the end of the overlap as an ISO timestamp.

During the overlap, Control attaches a transition signed by the previous key to activation and refresh responses. Each installation verifies that transition using its existing trust, saves both identified public keys automatically, and accepts licenses from either key. After the deadline, Control stops publishing the transition and installations reject licenses signed by the retired key. No reinstall or manual database edit is required.

Keep the previous private key configured only for the overlap. After every active installation has refreshed and the deadline has passed, remove all four `ROUTLY_LICENSE_PREVIOUS_*` settings from Control.
