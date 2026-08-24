#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - import struktury uslugi
# Debian / PostgreSQL 18
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"
PG_DATA="/var/lib/postgresql/${PG_MAJOR}/main"
PG_CLUSTER="main"
PG_DB="rcn"
RCN_SCHEMA="uslugi_rcn"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/struktura_uslugi_rcn.sql"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[BLAD] Import zostal przerwany w linii %s.\n" "$LINENO" >&2' ERR

echo "============================================================"
echo " RCN - import struktury uslugi"
echo "============================================================"

[[ -f "${SQL_FILE}" ]] \
  || error "Nie znaleziono ${SQL_FILE}. Plik struktura_uslugi_rcn.sql musi byc w tym samym katalogu."

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

[[ -x "${PG_BIN}/psql" ]] \
  || error "Nie znaleziono ${PG_BIN}/psql. Najpierw uruchom 00_instalacja_postgresql_postgis.sh."

if ! sudo test -s "${PG_DATA}/PG_VERSION"; then
    error "Nie znaleziono klastra PostgreSQL w ${PG_DATA}."
fi

CLUSTER_VERSION="$(sudo cat "${PG_DATA}/PG_VERSION")"
[[ "${CLUSTER_VERSION}" == "${PG_MAJOR}" ]] \
  || error "Wykryto klaster PostgreSQL ${CLUSTER_VERSION}, wymagany ${PG_MAJOR}."

if ! pg_lsclusters --no-header 2>/dev/null | awk '$1=="18" && $2=="main" {print $4}' | grep -qx online; then
    warn "Klaster ${PG_MAJOR}/${PG_CLUSTER} nie jest aktywny. Uruchamiam..."
    sudo pg_ctlcluster "${PG_MAJOR}" "${PG_CLUSTER}" start
fi

DB_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1 FROM pg_database WHERE datname='${PG_DB}'
        );"
)"

[[ "${DB_EXISTS}" == "t" ]] \
  || error "Baza ${PG_DB} nie istnieje. Najpierw uruchom 01_przygotowanie_bazy_rcn.sh."

POSTGIS_ENABLED="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1 FROM pg_extension WHERE extname='postgis'
        );"
)"

[[ "${POSTGIS_ENABLED}" == "t" ]] \
  || error "PostGIS nie jest wlaczony w bazie ${PG_DB}."

SCHEMA_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1
          FROM information_schema.schemata
          WHERE schema_name='${RCN_SCHEMA}'
        );"
)"

if [[ "${SCHEMA_EXISTS}" == "t" ]]; then
    warn "Schemat ${RCN_SCHEMA} juz istnieje."
    warn "Dla bezpieczenstwa import zostanie pominiety."
    info "Przechodze do weryfikacji istniejacej struktury."
else
    info "Importowanie struktury z ${SQL_FILE}..."
    sudo -u postgres "${PG_BIN}/psql" \
      -d "${PG_DB}" \
      -v ON_ERROR_STOP=1 \
      < "${SQL_FILE}"
    ok "Import pliku SQL zostal zakonczony."
fi

info "Weryfikacja struktury..."

SCHEMA_OK="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1
          FROM information_schema.schemata
          WHERE schema_name='${RCN_SCHEMA}'
        );"
)"

[[ "${SCHEMA_OK}" == "t" ]] || error "Nie znaleziono schematu ${RCN_SCHEMA}."

sudo -u postgres "${PG_BIN}/psql" \
  -d "${PG_DB}" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT 'tabele' AS typ, COUNT(*) AS liczba
        FROM information_schema.tables
        WHERE table_schema='${RCN_SCHEMA}'
      UNION ALL
      SELECT 'widoki', COUNT(*)
        FROM information_schema.views
        WHERE table_schema='${RCN_SCHEMA}'
      UNION ALL
      SELECT 'widoki materializowane', COUNT(*)
        FROM pg_matviews
        WHERE schemaname='${RCN_SCHEMA}';"

sudo -u postgres "${PG_BIN}/psql" \
  -d "${PG_DB}" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT current_database() AS baza,
             PostGIS_Version() AS wersja_postgis;"

echo
echo "============================================================"
echo " Struktura RCN zostala zweryfikowana poprawnie."
echo "============================================================"
