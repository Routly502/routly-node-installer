#!/usr/bin/env bash
# Remove Routly.  Purge is deliberately a resumable state machine: after the
# database has been dropped it never consults the deleted environment again.
set -euo pipefail
ROOT=${ROUTLY_FILESYSTEM_ROOT:-/}; ROOT=${ROOT%/}; [[ -n "$ROOT" ]] || ROOT=/
PURGE=0
if [[ ${1:-} == --purge && $# -eq 1 ]]; then PURGE=1
elif [[ $# -ne 0 ]]; then echo "usage: $0 [--purge]" >&2; exit 2
fi
path() { local v=$1 d=$2 x=${!1:-$2}; [[ "$x" == /* ]] || exit 2; printf '%s' "$x"; }
FLOCK=$(path ROUTLY_FLOCK_COMMAND /usr/bin/flock)
SYSTEMCTL=$(path ROUTLY_SYSTEMCTL_COMMAND /usr/bin/systemctl)
PSQL=$(path ROUTLY_PSQL_COMMAND /usr/bin/psql)
RUNUSER=$(path ROUTLY_RUNUSER_COMMAND /usr/sbin/runuser)
DROPDB=$(path ROUTLY_DROPDB_COMMAND /usr/bin/dropdb)
USERDEL=$(path ROUTLY_USERDEL_COMMAND /usr/sbin/userdel)
GETENT=$(path ROUTLY_GETENT_COMMAND /usr/bin/getent)
LOCK="$ROOT/run/lock"; mkdir -p "$LOCK"; exec 9>"$LOCK/routly.lock"; "$FLOCK" 9
[[ ${ROUTLY_TEST_MODE:-0} == 1 || $EUID -eq 0 ]] || { echo "Uninstaller must run as root" >&2; exit 1; }

JOURNAL_DIR="$ROOT/var/lib/routly-uninstall"
JOURNAL="$JOURNAL_DIR/journal"
if [[ $PURGE == 0 && -e "$JOURNAL" ]]; then
  echo "A data purge is incomplete; rerun this command with --purge." >&2
  exit 1
fi
if [[ $PURGE == 1 ]]; then
  mkdir -p "$JOURNAL_DIR"
  chmod 0700 "$JOURNAL_DIR"
  [[ ${ROUTLY_TEST_MODE:-0} == 1 || ( "$(stat -c '%u' "$JOURNAL_DIR")" == 0 && "$(stat -c '%a' "$JOURNAL_DIR")" == 700 ) ]] ||
    { echo "Unsafe purge journal directory" >&2; exit 1; }
fi
write_phase() {
  local next_phase=$1 tmp="$JOURNAL.tmp.$$"
  printf '%s\n' "$next_phase" >"$tmp"
  chmod 0600 "$tmp"
  chown root:root "$tmp" "$JOURNAL_DIR" 2>/dev/null || [[ ${ROUTLY_TEST_MODE:-0} == 1 ]]
  mv -f -- "$tmp" "$JOURNAL"
  sync -f "$JOURNAL"
  phase=$next_phase
  if [[ ${ROUTLY_TEST_MODE:-0} == 1 && ${ROUTLY_TEST_EXIT_AFTER_PHASE:-} == "$next_phase" ]]; then exit 86; fi
}
phase=
if [[ -f "$JOURNAL" ]]; then
  [[ $(stat -c '%a' "$JOURNAL") == 600 &&
     ( ${ROUTLY_TEST_MODE:-0} == 1 || "$(stat -c '%u' "$JOURNAL")" == 0 ) ]] ||
    { echo "Unsafe purge journal" >&2; exit 1; }
  phase=$(cat "$JOURNAL")
  case "$phase" in verified|stopped|dropped|files_removed|account_removed) ;;
    *) echo "Invalid purge journal" >&2; exit 1 ;; esac
fi

if [[ $PURGE == 1 ]]; then
  [[ ${ROUTLY_PURGE_CONFIRM:-} == PURGE_ROUTLY_DATA ]] ||
    { echo "Purge is destructive. Set ROUTLY_PURGE_CONFIRM=PURGE_ROUTLY_DATA to continue." >&2; exit 1; }
  [[ -x "$PSQL" && -x "$RUNUSER" && -x "$DROPDB" ]] ||
    { echo "Cannot purge safely: PostgreSQL reset commands are unavailable." >&2; exit 1; }
  unset PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD PGSSLMODE PGOPTIONS PGSERVICE PGSERVICEFILE

  # Reconcile the only unavoidable crash window: PostgreSQL may commit the
  # drop immediately before the durable journal advances from stopped.
  if [[ "$phase" == stopped ]]; then
    database_state=$("$RUNUSER" -u postgres -- env -u PGHOST -u PGPORT -u PGDATABASE -u PGUSER \
      -u PGPASSWORD -u PGSSLMODE -u PGOPTIONS -u PGSERVICE -u PGSERVICEFILE \
      "$PSQL" --host=/var/run/postgresql --port=5432 --dbname=postgres -v ON_ERROR_STOP=1 -At -c \
      "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_database WHERE datname='routly') THEN 'PRESENT' ELSE 'ABSENT' END;" 2>/dev/null) ||
      { echo "Cannot reconcile the Routly database state." >&2; exit 1; }
    case "$database_state" in
      ABSENT) write_phase dropped ;;
      PRESENT) ;;
      *) echo "Cannot reconcile the Routly database state." >&2; exit 1 ;;
    esac
  fi

  if [[ -z "$phase" || "$phase" == verified ]]; then
    ENV_FILE="$ROOT/etc/routly/routly.env"
    [[ -r "$ENV_FILE" ]] || { echo "Cannot purge safely: environment file is missing." >&2; exit 1; }
    DATABASE_URL=$(grep -E '^DATABASE_URL=' "$ENV_FILE" | head -n1 | cut -d= -f2- || true)
    python3 /dev/fd/3 <<<"$DATABASE_URL" 3<<'PY' >/dev/null ||
import re, sys
if not re.fullmatch(r"postgresql://routly:[A-Za-z0-9_-]+@127\.0\.0\.1:5432/routly", sys.stdin.read().strip()):
    raise SystemExit(1)
PY
      { echo "Cannot purge safely: DATABASE_URL must be the dedicated local Routly database." >&2; exit 1; }
    # Do not inherit caller connection settings.  The socket and port are
    # explicit, and the database name is the literal Routly database only.
    safety=$("$RUNUSER" -u postgres -- env -u PGHOST -u PGPORT -u PGDATABASE -u PGUSER \
      -u PGPASSWORD -u PGSSLMODE -u PGOPTIONS -u PGSERVICE -u PGSERVICEFILE \
      "$PSQL" --host=/var/run/postgresql --port=5432 --dbname=routly -v ON_ERROR_STOP=1 -At -c "
      SELECT CASE WHEN
        (SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname='routly') = 'routly'
        AND NOT EXISTS (
          SELECT 1 FROM pg_namespace
          WHERE nspname <> 'public'
            AND nspname <> 'information_schema'
            AND nspname NOT LIKE 'pg_%'
        )
      THEN 'SAFE' ELSE 'UNSAFE' END;" 2>/dev/null) ||
      { echo "Cannot purge safely: PostgreSQL ownership/schema verification failed." >&2; exit 1; }
    [[ "$safety" == SAFE ]] || { echo "Cannot purge safely: unexpected database owner or schema." >&2; exit 1; }
    write_phase verified
  fi

  if [[ "$phase" != dropped && "$phase" != files_removed && "$phase" != account_removed ]]; then
    # A successful stop is not sufficient: both units must report inactive.
    "$SYSTEMCTL" disable --now routly-api.service
    "$SYSTEMCTL" disable --now routly-control-agent.service
    for unit in routly-api.service routly-control-agent.service; do
      unit_state=$("$SYSTEMCTL" is-active "$unit" 2>/dev/null || true)
      case "$unit_state" in inactive|failed) ;;
        *) echo "$unit did not reach an inactive state" >&2; exit 1 ;;
      esac
    done
    write_phase stopped
  fi
  if [[ "$phase" != dropped && "$phase" != files_removed && "$phase" != account_removed ]]; then
    unset PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD PGSSLMODE PGOPTIONS PGSERVICE PGSERVICEFILE
    "$RUNUSER" -u postgres -- env -u PGHOST -u PGPORT -u PGDATABASE -u PGUSER \
      -u PGPASSWORD -u PGSSLMODE -u PGOPTIONS -u PGSERVICE -u PGSERVICEFILE \
      "$DROPDB" --host=/var/run/postgresql --port=5432 --force --if-exists routly
    write_phase dropped
  fi
fi

# Filesystem cleanup is safe to repeat and does not require /etc/routly.
rm -f -- "$ROOT/opt/routly/current"
for f in routly-api.service routly-control-agent.service; do rm -f -- "$ROOT/usr/lib/systemd/system/$f"; done
rm -f -- "$ROOT/usr/bin/routly-package-updater" "$ROOT/usr/bin/routly-uninstall" \
  "$ROOT/etc/sudoers.d/routly-package-updater" "$ROOT/usr/bin/routly-migrate" \
  "$ROOT/usr/bin/routly-migration-plan.mjs" "$ROOT/usr/lib/routly/validate-package.sh"
rm -f -- "$ROOT/etc/nginx/sites-enabled/routly.conf" "$ROOT/etc/nginx/sites-available/routly.conf"
rm -f -- "$ROOT/usr/lib/sysusers.d/routly.conf" "$ROOT/usr/lib/tmpfiles.d/routly.conf"
rm -rf -- "$ROOT/opt/routly/releases"
if [[ $PURGE == 1 ]]; then
  rm -rf -- "$ROOT/etc/routly" "$ROOT/var/lib/routly" "$ROOT/opt/routly"
  write_phase files_removed
  # If interrupted after userdel but before the next journal write, the
  # account is already absent and this rerun is complete rather than an error.
  if [[ "$phase" != files_removed ]] || "$GETENT" passwd routly >/dev/null 2>&1; then
    "$USERDEL" routly
  fi
  if "$GETENT" passwd routly >/dev/null 2>&1; then echo "routly OS account still exists" >&2; exit 1; fi
  write_phase account_removed
else
  echo "Retained: $ROOT/etc/routly and $ROOT/var/lib/routly"
fi
"$SYSTEMCTL" daemon-reload || true
"${ROUTLY_NGINX_COMMAND:-/usr/sbin/nginx}" -s reload 2>/dev/null || true
if [[ $PURGE == 1 ]]; then
  rm -rf -- "$JOURNAL_DIR"
  echo "Purged Routly code, state, database, and account."
else
  echo "Routly code and managed integration files removed."
fi