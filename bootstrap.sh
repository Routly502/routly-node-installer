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
PARTIAL_INSTALL=0
if [[ -e /etc/routly/routly.env ]]; then
  [[ -s /etc/routly/bootstrap-enrollment.json ]] ||
    fail "Ya existe una configuración local. No se sobrescribió ninguna credencial."
  PARTIAL_INSTALL=1
fi

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

if [[ $PARTIAL_INSTALL == 0 ]]; then
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
fi

WORK=$(mktemp -d /tmp/routly-bootstrap.XXXXXX)
install -d -m 0750 /etc/routly
if [[ -s /etc/routly/bootstrap-enrollment.json ]]; then
  say "Reutilizando la inscripción segura de un intento anterior"
  cp /etc/routly/bootstrap-enrollment.json "$WORK/enrollment.json"
elif [[ -s /etc/routly/bootstrap-enrollment-request.json ]]; then
  say "Reintentando el canje seguro de un intento anterior"
  cp /etc/routly/bootstrap-enrollment-request.json "$WORK/enroll-request.json"
  CONTROL_URL=$(python3 - "$WORK/enroll-request.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["controlUrl"])
PY
  )
  curl -fsS --proto '=https' --tlsv1.2 \
    -H 'content-type: application/json' \
    --data-binary "@$WORK/enroll-request.json" \
    "$CONTROL_URL/api/control/licensing/enroll" \
    -o "$WORK/enrollment.json" ||
    fail "Routly Control rechazó el código o no está disponible."
  chmod 0600 "$WORK/enrollment.json"
  install -m 0600 "$WORK/enrollment.json" /etc/routly/bootstrap-enrollment.json
  rm -f /etc/routly/bootstrap-enrollment-request.json
else
  printf 'Código de activación: '
  IFS= read -r -s ENROLLMENT_CODE </dev/tty || fail "No se pudo leer el código de activación."
  printf '\n'
  [[ "$ENROLLMENT_CODE" == rly1.*.* ]] || fail "El código de activación no tiene un formato válido."
  CONTROL_PART=${ENROLLMENT_CODE#rly1.}
  CONTROL_PART=${CONTROL_PART%%.*}
  ENROLLMENT_SECRET=${ENROLLMENT_CODE##*.}
  CONTROL_URL=$(python3 - "$CONTROL_PART" <<'PY'
import base64, sys
try:
    value = sys.argv[1]
    print(base64.urlsafe_b64decode(value + "=" * (-len(value) % 4)).decode("utf-8"))
except Exception:
    raise SystemExit("El código de activación no tiene un origen válido")
PY
  )
  [[ "$CONTROL_URL" == https://* && "$CONTROL_URL" != *[$' \t\r\n']* ]] ||
    fail "El código de activación no contiene un origen HTTPS válido."
  REDEMPTION_ID=$(openssl rand -hex 24)
  printf '%s' "$ENROLLMENT_SECRET" |
    python3 -c 'import json, os, sys
path = sys.argv[1]
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, "w", encoding="utf-8") as output:
    json.dump({"secret": sys.stdin.read(), "redemptionId": sys.argv[2], "controlUrl": sys.argv[3]}, output)' "$WORK/enroll-request.json" "$REDEMPTION_ID" "$CONTROL_URL"
  install -m 0600 "$WORK/enroll-request.json" /etc/routly/bootstrap-enrollment-request.json
  unset ENROLLMENT_CODE ENROLLMENT_SECRET CONTROL_PART REDEMPTION_ID
  say "Vinculando esta instalación con Routly Control"
  curl -fsS --proto '=https' --tlsv1.2 \
    -H 'content-type: application/json' \
    --data-binary "@$WORK/enroll-request.json" \
    "$CONTROL_URL/api/control/licensing/enroll" \
    -o "$WORK/enrollment.json" ||
    fail "Routly Control rechazó el código o no está disponible."
  chmod 0600 "$WORK/enrollment.json"
  install -m 0600 "$WORK/enrollment.json" /etc/routly/bootstrap-enrollment.json
  rm -f /etc/routly/bootstrap-enrollment-request.json
fi

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
BASE="$RAW_URL/releases/v$VERSION"

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
if [[ $PARTIAL_INSTALL == 1 ]]; then
  say "Conservando las credenciales locales del intento anterior"
else
SESSION_SECRET=$(openssl rand -hex 48)
ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '\n' | tr '/+' '_-')
python3 - "$WORK/enrollment.json" /etc/routly/enrollment.env /etc/routly/release-signing-public.pem <<'PY'
import base64, json, os, re, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
required = ("controlUrl", "installationId", "activationSecret", "installationToken",
            "licenseKeyId", "licensePublicKeyBase64", "updateOrigin",
            "releaseSigningPublicKeyBase64")
if any(key not in data for key in required):
    raise SystemExit("Routly Control devolvió una configuración incompleta")
if not isinstance(data["installationId"], int) or data["installationId"] <= 0:
    raise SystemExit("Routly Control devolvió una identidad inválida")
safe = re.compile(r"^[A-Za-z0-9._~:/+-]+$")
base64_value = re.compile(r"^[A-Za-z0-9+/]+={0,2}$")
for key in ("controlUrl", "activationSecret", "installationToken", "licenseKeyId", "updateOrigin"):
    if not isinstance(data[key], str) or not safe.fullmatch(data[key]):
        raise SystemExit("Routly Control devolvió un valor de configuración inválido")
values = {
    "ROUTLY_CONTROL_URL": data["controlUrl"],
    "ROUTLY_INSTALLATION_ID": str(data["installationId"]),
    "ROUTLY_ACTIVATION_SECRET": data["activationSecret"],
    "ROUTLY_LICENSE_KEY_ID": data["licenseKeyId"],
    "ROUTLY_LICENSE_PUBLIC_KEY_BASE64": data["licensePublicKeyBase64"],
    "ROUTLY_LICENSE_PREVIOUS_KEY_ID": data.get("previousLicenseKeyId", ""),
    "ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY_BASE64": data.get("previousLicensePublicKeyBase64", ""),
    "ROUTLY_LICENSE_PREVIOUS_VALID_UNTIL": data.get("previousLicenseValidUntil", ""),
    "ROUTLY_CONTROL_INSTALLATION_ID": str(data["installationId"]),
    "ROUTLY_CONTROL_INSTALLATION_TOKEN": data["installationToken"],
    "ROUTLY_UPDATE_ORIGIN": data["updateOrigin"],
}
for value in values.values():
    if value and ("\n" in value or "\r" in value):
        raise SystemExit("Routly Control devolvió un valor no seguro")
for key in ("ROUTLY_LICENSE_PUBLIC_KEY_BASE64", "ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY_BASE64"):
    if values[key] and not base64_value.fullmatch(values[key]):
        raise SystemExit("Routly Control devolvió una clave de licencia codificada inválida")
for key, value in values.items():
    if value and not key.endswith("_BASE64") and not safe.fullmatch(value):
        raise SystemExit("Routly Control devolvió un valor no seguro")
with open(sys.argv[2], "w", encoding="utf-8") as output:
    for key, value in values.items():
        output.write(f"{key}={value}\n")
release_key = base64.b64decode(data["releaseSigningPublicKeyBase64"], validate=True)
if b"BEGIN PUBLIC KEY" not in release_key:
    raise SystemExit("Routly Control devolvió una clave de actualización inválida")
with open(sys.argv[3], "wb") as output:
    output.write(release_key)
os.chmod(sys.argv[2], 0o600)
os.chmod(sys.argv[3], 0o644)
PY
. /etc/routly/enrollment.env
cat > /etc/routly/routly.env <<EOF
NODE_ENV=production
HOST=127.0.0.1
PORT=4100
LOG_LEVEL=info
ROUTLY_NODE_MODE=node
DATABASE_URL=postgresql://routly:${DB_PASSWORD}@127.0.0.1:5432/routly
SESSION_SECRET=${SESSION_SECRET}
ROUTLY_INITIAL_ADMIN_PASSWORD=${ADMIN_PASSWORD}
ROUTLY_CONTROL_URL=${ROUTLY_CONTROL_URL}
ROUTLY_INSTALLATION_ID=${ROUTLY_INSTALLATION_ID}
ROUTLY_ACTIVATION_SECRET=${ROUTLY_ACTIVATION_SECRET}
ROUTLY_LICENSE_KEY_ID=${ROUTLY_LICENSE_KEY_ID}
ROUTLY_LICENSE_PUBLIC_KEY=
ROUTLY_LICENSE_PUBLIC_KEY_BASE64=${ROUTLY_LICENSE_PUBLIC_KEY_BASE64}
ROUTLY_LICENSE_PREVIOUS_KEY_ID=${ROUTLY_LICENSE_PREVIOUS_KEY_ID}
ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY=
ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY_BASE64=${ROUTLY_LICENSE_PREVIOUS_PUBLIC_KEY_BASE64}
ROUTLY_LICENSE_PREVIOUS_VALID_UNTIL=${ROUTLY_LICENSE_PREVIOUS_VALID_UNTIL}
ROUTLY_CONTROL_INSTALLATION_ID=${ROUTLY_CONTROL_INSTALLATION_ID}
ROUTLY_CONTROL_INSTALLATION_TOKEN=${ROUTLY_CONTROL_INSTALLATION_TOKEN}
ROUTLY_VERSION_URL=http://127.0.0.1:4100/api/version
ROUTLY_UPDATE_ORIGIN=${ROUTLY_UPDATE_ORIGIN}
ROUTLY_CONTROL_POLL_MS=60000
DEFAULT_OBJECT_STORAGE_BUCKET_ID=
PRIVATE_OBJECT_DIR=
PUBLIC_OBJECT_SEARCH_PATHS=
ROUTER_ALERT_EMAIL_WEBHOOK_URL=
ROUTER_ALERT_SMS_WEBHOOK_URL=
EOF
chmod 0640 /etc/routly/routly.env
rm -f /etc/routly/enrollment.env
unset ROUTLY_ACTIVATION_SECRET ROUTLY_CONTROL_INSTALLATION_TOKEN
fi

say "Validando e instalando Routly"
"$WORK/install.sh" "$WORK/$ARCHIVE" "$EXPECTED"
rm -f /etc/routly/bootstrap-enrollment.json

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
printf '\nRoutly %s quedó instalado.\n' "$VERSION"
printf 'Abra: http://%s/admin\n' "${SERVER_IP:-localhost}"
printf 'Usuario inicial: admin\n'
if [[ $PARTIAL_INSTALL == 0 ]]; then
  printf 'Contraseña temporal: %s\n' "$ADMIN_PASSWORD"
  printf 'Debe cambiar la contraseña al iniciar sesión por primera vez.\n'
else
  printf 'Se conservaron las credenciales locales creadas en el intento anterior.\n'
fi