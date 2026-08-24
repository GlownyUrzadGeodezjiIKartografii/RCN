#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - przygotowanie bazy danych rcn
# Debian / PostgreSQL 18
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"
PG_DATA="/var/lib/postgresql/${PG_MAJOR}/main"
PG_CLUSTER="main"
PG_DB="rcn"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[BLAD] Przygotowanie bazy zostalo przerwane w linii %s.\n" "$LINENO" >&2' ERR

echo "============================================================"
echo " RCN - przygotowanie bazy danych PostgreSQL"
echo "============================================================"

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

[[ -x "${PG_BIN}/psql" ]] || error "Nie znaleziono ${PG_BIN}/psql."
[[ -x "${PG_BIN}/createdb" ]] || error "Nie znaleziono ${PG_BIN}/createdb."
[[ -x "${PG_BIN}/pg_isready" ]] || error "Nie znaleziono ${PG_BIN}/pg_isready."

ok "$("${PG_BIN}/psql" --version)"

if ! sudo test -s "${PG_DATA}/PG_VERSION"; then
    error "Nie znaleziono klastra PostgreSQL w ${PG_DATA}. Uruchom 00_instalacja_postgresql_postgis.sh."
fi

CLUSTER_VERSION="$(sudo cat "${PG_DATA}/PG_VERSION")"
[[ "${CLUSTER_VERSION}" == "${PG_MAJOR}" ]] \
  || error "Wykryto klaster PostgreSQL ${CLUSTER_VERSION}, a skrypt wymaga ${PG_MAJOR}."

if ! pg_lsclusters --no-header 2>/dev/null | awk '$1=="18" && $2=="main" {print $4}' | grep -qx online; then
    warn "Klaster ${PG_MAJOR}/${PG_CLUSTER} nie jest aktywny. Uruchamiam..."
    sudo pg_ctlcluster "${PG_MAJOR}" "${PG_CLUSTER}" start
fi

sudo systemctl enable postgresql >/dev/null

info "Sprawdzanie gotowosci PostgreSQL..."
sudo -u postgres "${PG_BIN}/pg_isready" -d postgres \
  || error "Serwer PostgreSQL nie odpowiada."

info "Sprawdzanie dostepnosci PostGIS..."
POSTGIS_AVAILABLE="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1
          FROM pg_available_extensions
          WHERE name='postgis'
        );"
)"

[[ "${POSTGIS_AVAILABLE}" == "t" ]] \
  || error "PostGIS nie jest dostepny dla PostgreSQL ${PG_MAJOR}."

info "Sprawdzanie bazy danych ${PG_DB}..."
DB_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1 FROM pg_database WHERE datname='${PG_DB}'
        );"
)"

if [[ "${DB_EXISTS}" == "t" ]]; then
    ok "Baza ${PG_DB} juz istnieje. Pomijam tworzenie."
else
    info "Tworzenie bazy ${PG_DB}..."
    sudo -u postgres "${PG_BIN}/createdb" --encoding=UTF8 "${PG_DB}"
    ok "Baza ${PG_DB} zostala utworzona."
fi

POSTGIS_ENABLED="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1 FROM pg_extension WHERE extname='postgis'
        );"
)"

if [[ "${POSTGIS_ENABLED}" == "t" ]]; then
    ok "PostGIS jest juz wlaczony w bazie ${PG_DB}."
else
    info "Wlaczanie rozszerzenia PostGIS..."
    sudo -u postgres "${PG_BIN}/psql" \
      -d "${PG_DB}" \
      -v ON_ERROR_STOP=1 \
      -c "CREATE EXTENSION postgis;"
fi

info "Weryfikacja..."
sudo -u postgres "${PG_BIN}/psql" \
  -d "${PG_DB}" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT current_database() AS baza,
             current_setting('server_version') AS wersja_postgresql,
             PostGIS_Version() AS wersja_postgis;"

echo
echo "============================================================"
echo " Baza ${PG_DB} jest przygotowana poprawnie."
echo " Nastepny krok:"
echo "   ./02_import_struktury_rcn.sh"
echo "============================================================"
