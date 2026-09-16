#!/usr/bin/env bash
# Install one validated Routly Node release.  This is deliberately a shell
# installer (rather than a package-manager hook) so that the same operation can
# be audited and exercised in a disposable filesystem.
set -euo pipefail
umask 022

usage() { echo "usage: $0 PACKAGE.tar.gz EXPECTED_SHA256" >&2; exit 2; }
[[ $# -eq 2 ]] || usage
ARCHIVE=$1
EXPECTED=$2
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=${ROUTLY_FILESYSTEM_ROOT:-/}
[[ "$ROOT" == /* ]] || { echo "ROUTLY_FILESYSTEM_ROOT must be absolute" >&2; exit 2; }
ROOT=${ROOT%/}; [[ -n "$ROOT" ]] || ROOT=/

command_path() {
  local variable=$1 default=$2 value
  value=${!variable:-$default}
  [[ "$value" == /* ]] || { echo "$variable must be an absolute path" >&2; exit 2; }
  printf '%s' "$value"
}
FLOCK=$(command_path ROUTLY_FLOCK_COMMAND /usr/bin/flock)
SYSTEMCTL=$(command_path ROUTLY_SYSTEMCTL_COMMAND /usr/bin/systemctl)
NGINX=$(command_path ROUTLY_NGINX_COMMAND /usr/sbin/nginx)
SYSUSERS=$(command_path ROUTLY_SYSUSERS_COMMAND /usr/bin/systemd-sysusers)
TMPFILES=$(command_path ROUTLY_TMPFILES_COMMAND /usr/bin/systemd-tmpfiles)
TAR=$(command_path ROUTLY_TAR_COMMAND /usr/bin/tar)
PSQL=$(command_path ROUTLY_PSQL_COMMAND /usr/bin/psql)

[[ "$EXPECTED" =~ ^[0-9a-f]{64}$ ]] || { echo "Expected SHA-256 is malformed" >&2; exit 2; }
[[ -f "$ARCHIVE" ]] || { echo "Archive not found: $ARCHIVE" >&2; exit 2; }
[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] ||
  { echo "Routly requires Linux amd64" >&2; exit 1; }
if [[ ${ROUTLY_TEST_MODE:-0} != 1 && "$ROOT" == / ]]; then
  [[ $EUID -eq 0 ]] || { echo "Installer must run as root" >&2; exit 1; }
fi
if [[ -f "$ROOT/etc/os-release" ]]; then
  . "$ROOT/etc/os-release"
  [[ ${ID:-} == ubuntu ]] || { echo "Routly requires Ubuntu" >&2; exit 1; }
  version=${VERSION_ID:-0}
  awk -v v="$version" 'BEGIN { exit !(v+0 >= 22.04) }' ||
    { echo "Routly requires Ubuntu 22.04 or newer" >&2; exit 1; }
fi
for required in "$FLOCK" "$SYSTEMCTL" "$NGINX" "$SYSUSERS" "$TMPFILES" "$TAR" "$PSQL"; do
  [[ -x "$required" ]] || { [[ ${ROUTLY_TEST_MODE:-0} == 1 ]] || {
    echo "Missing prerequisite command: $required" >&2; exit 1; }; }
done

LOCK_DIR="$ROOT/run/lock"
mkdir -p "$LOCK_DIR"
exec 9>"$LOCK_DIR/routly.lock"
"$FLOCK" 9

"$SCRIPT_DIR/validate-package.sh" "$ARCHIVE" "$EXPECTED"
base=$(basename "$ARCHIVE")
[[ "$base" =~ ^routly-node-([0-9]+\.[0-9]+\.[0-9]+)-linux-amd64\.tar\.gz$ ]] ||
  { echo "Invalid Routly archive filename" >&2; exit 1; }
VERSION=${BASH_REMATCH[1]}
if [[ -e "$ROOT/opt/routly/current" || -L "$ROOT/opt/routly/current" ]]; then
  [[ -L "$ROOT/opt/routly/current" ]] || { echo "Routly is already installed; use the signed package updater" >&2; exit 1; }
  current_target=$(readlink "$ROOT/opt/routly/current")
  [[ "$current_target" =~ ^/opt/routly/releases/[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    { echo "Routly current symlink is unsafe; use the signed package updater" >&2; exit 1; }
  echo "Routly is already installed; install.sh is for initial installation only. Use the signed package updater." >&2
  exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/routly-install.XXXXXX")
cleanup() { rm -rf -- "$WORK"; }
trap cleanup EXIT
"$TAR" --no-same-owner --no-same-permissions -xzf "$ARCHIVE" -C "$WORK"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
# The validator has already constrained archive paths.  Copy only the package
# roots used by this installer, never an archive-controlled destination.
for root in "opt/routly/releases/$VERSION" etc/routly \
  etc/nginx/sites-available etc/sudoers.d usr/lib/systemd/system usr/lib/tmpfiles.d usr/lib/sysusers.d usr/lib/routly usr/bin; do
  [[ -e "$WORK/$root" ]] || continue
  mkdir -p "$STAGE/$(dirname "$root")"
  cp -a --no-preserve=ownership "$WORK/$root" "$STAGE/$(dirname "$root")/"
done
RELEASE="$ROOT/opt/routly/releases/$VERSION"
mkdir -p "$ROOT/opt/routly/releases" "$ROOT/etc/nginx/sites-enabled"
[[ -d "$STAGE/opt/routly/releases/$VERSION" ]] ||
  { echo "Package has no release payload" >&2; exit 1; }
[[ -f "$STAGE/usr/bin/routly-migrate.mjs" ]] ||
  { echo "Package has no PostgreSQL migration runner" >&2; exit 1; }
[[ -f "$STAGE/usr/bin/routly-migration-plan.mjs" ]] ||
  { echo "Package has no PostgreSQL migration plan module" >&2; exit 1; }

OLD_CURRENT=
if [[ -L "$ROOT/opt/routly/current" ]]; then OLD_CURRENT=$(readlink "$ROOT/opt/routly/current"); fi
CURRENT_TMP="$ROOT/opt/routly/.current.$$"
rollback() {
  rm -f -- "$CURRENT_TMP"
  if [[ -n "$OLD_CURRENT" ]]; then ln -s -- "$OLD_CURRENT" "$CURRENT_TMP" && mv -Tf -- "$CURRENT_TMP" "$ROOT/opt/routly/current"; else rm -f -- "$ROOT/opt/routly/current"; fi
}
trap 'rollback || true; cleanup' EXIT

rm -rf -- "$RELEASE"
mkdir -p "$(dirname "$RELEASE")"
cp -a --no-preserve=ownership "$STAGE/opt/routly/releases/$VERSION" "$ROOT/opt/routly/releases/"
chown -R root:root -- "$RELEASE" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
find "$RELEASE" -type d -exec chmod 0755 {} +
# Keep host identity outside the database and create it before either service
# can start. Atomic creation preserves an identity supplied by an older install.
INSTANCE_ID_FILE="$ROOT/etc/routly/instance-id"
mkdir -p "$(dirname "$INSTANCE_ID_FILE")"
if [[ -e "$INSTANCE_ID_FILE" ]]; then
  [[ -f "$INSTANCE_ID_FILE" && "$(stat -c '%a' "$INSTANCE_ID_FILE")" == 600 &&
     ( ${ROUTLY_TEST_MODE:-0} == 1 || "$(stat -c '%u' "$INSTANCE_ID_FILE")" == 0 ) ]] ||
    { echo "Unsafe existing Routly instance identity" >&2; exit 1; }
else
  tmp_instance="$ROOT/etc/routly/.instance-id.$$"
  (umask 077; openssl rand -hex 32 > "$tmp_instance")
  mv -f -- "$tmp_instance" "$INSTANCE_ID_FILE"
fi
find "$RELEASE" -type f -exec chmod 0644 {} +
ln -s -- "/opt/routly/releases/$VERSION" "$CURRENT_TMP"
mv -Tf -- "$CURRENT_TMP" "$ROOT/opt/routly/current"

install_file() {
  local src=$1 dest=$2 mode=$3
  mkdir -p -- "$(dirname "$dest")"
  cp --no-preserve=ownership "$src" "$dest"
  chown root:root -- "$dest" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
  chmod "$mode" "$dest"
}
for f in "$STAGE/usr/lib/systemd/system/routly-api.service" "$STAGE/usr/lib/systemd/system/routly-control-agent.service"; do
  [[ -f "$f" ]] && install_file "$f" "$ROOT/usr/lib/systemd/system/$(basename "$f")" 0644
done
install_file "$STAGE/etc/nginx/sites-available/routly.conf" "$ROOT/etc/nginx/sites-available/routly.conf" 0644
if [[ -f "$STAGE/usr/bin/routly-package-updater.mjs" ]]; then
  install_file "$STAGE/usr/bin/routly-package-updater.mjs" "$ROOT/usr/bin/routly-package-updater" 0755
  [[ -f "$STAGE/usr/lib/routly/validate-package.sh" ]] ||
    { echo "Package validator is missing" >&2; exit 1; }
  install_file "$STAGE/usr/lib/routly/validate-package.sh" "$ROOT/usr/lib/routly/validate-package.sh" 0755
  install_file "$STAGE/etc/sudoers.d/routly-package-updater" "$ROOT/etc/sudoers.d/routly-package-updater" 0440
fi
if [[ -f "$STAGE/usr/bin/routly-uninstall" ]]; then
  install_file "$STAGE/usr/bin/routly-uninstall" "$ROOT/usr/bin/routly-uninstall" 0755
fi
if [[ -f "$STAGE/usr/bin/routly-migrate.mjs" ]]; then
  install_file "$STAGE/usr/bin/routly-migrate.mjs" "$ROOT/usr/bin/routly-migrate" 0755
fi
if [[ -f "$STAGE/usr/bin/routly-migration-plan.mjs" ]]; then
  install_file "$STAGE/usr/bin/routly-migration-plan.mjs" "$ROOT/usr/bin/routly-migration-plan.mjs" 0644
fi
ln -sfn -- /etc/nginx/sites-available/routly.conf "$ROOT/etc/nginx/sites-enabled/routly.conf"
# Ubuntu enables its welcome site by default. On a dedicated Routly Node host it
# would otherwise win the catch-all request before Routly's server block.
default_site="$ROOT/etc/nginx/sites-enabled/default"
if [[ -L "$default_site" ]]; then
  default_target=$(readlink "$default_site")
  case "$default_target" in
    /etc/nginx/sites-available/default|../sites-available/default)
      rm -f -- "$default_site"
      ;;
  esac
fi
for f in "$STAGE/usr/lib/tmpfiles.d/routly.conf" "$STAGE/usr/lib/sysusers.d/routly.conf"; do
  [[ -f "$f" ]] && install_file "$f" "$ROOT/${f#"$STAGE/"}" 0644
done
# Create the account immediately after installing its declarative definition,
# before any ownership is assigned to routly.
"$SYSUSERS" --root="$ROOT" "$ROOT/usr/lib/sysusers.d/routly.conf"
mkdir -p "$ROOT/etc/routly"
mkdir -p "$ROOT/var/lib/routly/agent/staging" "$ROOT/var/lib/routly/backups"
mkdir -p "$ROOT/var/lib/routly/updater"
chmod 0700 "$ROOT/var/lib/routly/agent" "$ROOT/var/lib/routly/agent/staging" "$ROOT/var/lib/routly/backups" 2>/dev/null || true
if [[ ! -e "$ROOT/etc/routly/routly.env" ]]; then
  install_file "$STAGE/etc/routly/routly.env.example" "$ROOT/etc/routly/routly.env" 0640
fi
chown root:routly -- "$ROOT/etc/routly/routly.env" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
"$TMPFILES" --root="$ROOT" --create "$ROOT/usr/lib/tmpfiles.d/routly.conf"
chown routly:routly "$ROOT/var/lib/routly/agent" "$ROOT/var/lib/routly/agent/staging" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
chown root:root "$ROOT/var/lib/routly/updater" "$ROOT/var/lib/routly/backups" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
"$NGINX" -t
env_file="$ROOT/etc/routly/routly.env"
database_url=$(grep -E '^DATABASE_URL=' "$env_file" | head -n 1 | cut -d= -f2- || true)
if [[ -z "$database_url" || "$database_url" == *"CHANGE_ME"* || "$database_url" == *"example"* ||
      "$database_url" == *"localhost:5432/routly"* ]]; then
  echo "DATABASE_URL must be configured with the Routly PostgreSQL connection before enabling services" >&2
  exit 1
fi
MIGRATIONS="$RELEASE/migrations"
ROUTLY_MIGRATION_LOCK_HELD=1 "$ROOT/usr/bin/routly-migrate" "$MIGRATIONS"
schema_check=$("$PSQL" "$database_url" -v ON_ERROR_STOP=1 -At -c \
  "SELECT CASE WHEN to_regclass('public.customers') IS NOT NULL AND to_regclass('public.app_users') IS NOT NULL THEN 1 ELSE 0 END;" 2>/dev/null) ||
  { echo "Routly PostgreSQL compatibility check failed: customers and app_users tables are required" >&2; exit 1; }
[[ "$schema_check" == 1 ]] ||
  { echo "Routly PostgreSQL compatibility check failed: customers and app_users tables are required" >&2; exit 1; }
"$SYSTEMCTL" daemon-reload
"$SYSTEMCTL" enable --now routly-api.service
"$SYSTEMCTL" enable --now nginx
"$SYSTEMCTL" reload nginx
env_ready=0
if [[ -f "$ROOT/etc/routly/routly.env" ]] &&
   grep -qE '^ROUTLY_CONTROL_URL=https://' "$ROOT/etc/routly/routly.env" &&
   grep -qE '^ROUTLY_CONTROL_INSTALLATION_ID=[^[:space:]]+' "$ROOT/etc/routly/routly.env" &&
   grep -qE '^ROUTLY_CONTROL_INSTALLATION_TOKEN=[^[:space:]]+' "$ROOT/etc/routly/routly.env" &&
   grep -qE '^ROUTLY_UPDATE_ORIGIN=https://' "$ROOT/etc/routly/routly.env"; then env_ready=1; fi
if [[ -s "$ROOT/etc/routly/release-signing-public.pem" && $env_ready == 1 ]]; then
  "$SYSTEMCTL" enable --now routly-control-agent.service
else
  "$SYSTEMCTL" disable --now routly-control-agent.service 2>/dev/null || true
fi
trap - EXIT
cleanup
echo "Installed Routly $VERSION"