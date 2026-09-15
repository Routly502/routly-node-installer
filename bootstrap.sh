#!/usr/bin/env bash
# Public one-command bootstrap for a fresh Routly Node host.
set -euo pipefail
umask 077

REPOSITORY=${ROUTLY_DISTRIBUTION_REPOSITORY:-Routly502/routly-node-installer}
API_URL="https://api.github.com/repos/$REPOSITORY/releases/latest"
RAW_URL="https://raw.githubusercontent.com/$REPOSITORY/main"
WORK=

say() { printf '\n==> %s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
cleanup() { [[ -z "${WORK:-}" ]] || rm -rf -- "$WORK"; }
trap cleanup EXIT

[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] ||
  fail "Routly requiere Linux amd64."
[[ $EUID -eq 0 ]] || fail "Ejecute este comando con sudo."
[[ -r /etc/os-release ]] || fail "No se pudo identificar Ubuntu."
. /etc/os-release
[[ ${ID:-} == ubuntu ]] || fail "Routly requiere Ubuntu."
awk -v v="${VERSION_ID:-0}" 'BEGIN { exit !(v+0 >= 22.04) }' ||
  fail "Routly requiere Ubuntu 22.04 o una versión posterior."
[[ ! -e /opt/routly/current ]] ||
  fail "Routly ya está instalado. Use el actualizador desde Routly Control."

say "Instalando dependencias de Ubuntu"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg nginx openssl postgresql postgresql-client \
  python3 tar gzip util-linux

if ! command -v node >/dev/null || ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)'; then
  say "Instalando Node.js 22"
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
    gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
  chmod 0644 /etc/apt/keyrings/nodesource.gpg
  printf '%s\n' \
    'deb [arch=amd64 signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main' \
    > /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install -y --no-install-recommends nodejs
fi

say "Preparando PostgreSQL"
systemctl enable --now postgresql
DB_PASSWORD=$(openssl rand -base64 36 | tr -d '\n' | tr '/+' '_-')
runuser -u postgres -- psql -v ON_ERROR_STOP=1 -v db_password="$DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE routly LOGIN PASSWORD %L', :'db_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'routly') \gexec
SELECT format('ALTER ROLE routly WITH LOGIN PASSWORD %L', :'db_password') \gexec
SELECT 'CREATE DATABASE routly OWNER routly'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'routly') \gexec
SQL

WORK=$(mktemp -d /tmp/routly-bootstrap.XXXXXX)
say "Localizando el último Routly Node publicado"
curl -fsSL "$API_URL" -o "$WORK/release.json"
VERSION=$(python3 - "$WORK/release.json" <<'PY'
import json, re, sys
tag = json.load(open(sys.argv[1], encoding="utf-8")).get("tag_name", "")
version = tag[1:] if tag.startswith("v") else tag
if not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", version):
    raise SystemExit("El último Release no tiene una versión semántica válida")
print(version)
PY
)
ARCHIVE="routly-node-$VERSION-linux-amd64.tar.gz"
BASE="https://github.com/$REPOSITORY/releases/download/v$VERSION"

say "Descargando Routly $VERSION"
curl -fL --retry 3 --retry-all-errors "$BASE/$ARCHIVE" -o "$WORK/$ARCHIVE"
curl -fL --retry 3 --retry-all-errors "$BASE/$ARCHIVE.sha256" -o "$WORK/$ARCHIVE.sha256"
curl -fsSL "$RAW_URL/install.sh" -o "$WORK/install.sh"
curl -fsSL "$RAW_URL/validate-package.sh" -o "$WORK/validate-package.sh"
chmod 0755 "$WORK/install.sh" "$WORK/validate-package.sh"

EXPECTED=$(python3 - "$WORK/$ARCHIVE.sha256" "$ARCHIVE" <<'PY'
import re, sys
line = open(sys.argv[1], encoding="ascii").read()
match = re.fullmatch(r"([0-9a-f]{64})  ([^/\n]+)\n?", line)
if not match or match.group(2) != sys.argv[2]:
    raise SystemExit("El checksum publicado es inválido")
print(match.group(1))
PY
)

say "Creando configuración local segura"
install -d -m 0750 /etc/routly
SESSION_SECRET=$(openssl rand -hex 48)
ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '\n' | tr '/+' '_-')
cat > /etc/routly/routly.env <<EOF
NODE_ENV=production
HOST=127.0.0.1
PORT=4100
LOG_LEVEL=info
ROUTLY_NODE_MODE=node
DATABASE_URL=postgresql://routly:${DB_PASSWORD}@127.0.0.1:5432/routly
SESSION_SECRET=${SESSION_SECRET}
ROUTLY_INITIAL_ADMIN_PASSWORD=${ADMIN_PASSWORD}
ROUTLY_CONTROL_URL=
ROUTLY_INSTALLATION_ID=
ROUTLY_ACTIVATION_SECRET=
ROUTLY_LICENSE_KEY_ID=
ROUTLY_LICENSE_PUBLIC_KEY=
ROUTLY_LICENSE_PREVIOUS_KEY_ID=
ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY=
ROUTLY_LICENSE_PREVIOUS_VALID_UNTIL=
ROUTLY_CONTROL_INSTALLATION_ID=
ROUTLY_CONTROL_INSTALLATION_TOKEN=
ROUTLY_VERSION_URL=http://127.0.0.1:4100/api/version
ROUTLY_UPDATE_ORIGIN=
ROUTLY_CONTROL_POLL_MS=60000
DEFAULT_OBJECT_STORAGE_BUCKET_ID=
PRIVATE_OBJECT_DIR=
PUBLIC_OBJECT_SEARCH_PATHS=
ROUTER_ALERT_EMAIL_WEBHOOK_URL=
ROUTER_ALERT_SMS_WEBHOOK_URL=
EOF
chmod 0640 /etc/routly/routly.env

say "Validando e instalando Routly"
"$WORK/install.sh" "$WORK/$ARCHIVE" "$EXPECTED"

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
printf '\nRoutly %s quedó instalado.\n' "$VERSION"
printf 'Abra: http://%s/\n' "${SERVER_IP:-localhost}"
printf 'Usuario inicial: admin\n'
printf 'Contraseña temporal: %s\n' "$ADMIN_PASSWORD"
printf 'Debe cambiar la contraseña al iniciar sesión por primera vez.\n'