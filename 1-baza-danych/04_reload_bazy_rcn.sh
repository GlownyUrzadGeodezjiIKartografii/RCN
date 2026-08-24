#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - pelne odtworzenie bazy danych
# Debian / PostgreSQL 18
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"
PG_DB="rcn"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PREPARE_SCRIPT="${SCRIPT_DIR}/01_przygotowanie_bazy_rcn.sh"
IMPORT_SCRIPT="${SCRIPT_DIR}/02_import_struktury_rcn.sh"
MAPSERVER_SCRIPT="${SCRIPT_DIR}/03_konfiguracja_uzytkownika_mapserver.sh"
SQL_FILE="${SCRIPT_DIR}/struktura_uslugi_rcn.sql"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

echo "============================================================"
echo " RCN - RELOAD BAZY DANYCH"
echo "============================================================"
echo
echo "UWAGA!"
echo "Ten skrypt:"
echo "  1. USUNIE CALA baze danych rcn wraz ze wszystkimi danymi,"
echo "  2. utworzy baze rcn ponownie,"
echo "  3. wlaczy PostGIS,"
echo "  4. zaimportuje strukture uslugi_rcn,"
echo "  5. ponownie nada uprawnienia uzytkownikowi MapServer ms_rcn."
echo
echo "Operacji usuniecia danych nie mozna cofnac."
echo

read -r -p "Czy na pewno chcesz usunac i odtworzyc baze rcn? [T/N]: " CONFIRM

case "${CONFIRM}" in
    T|t) ;;
    *)
        echo
        echo "Operacja anulowana."
        exit 0
        ;;
esac

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

[[ -x "${PG_BIN}/psql" ]] || error "Nie znaleziono ${PG_BIN}/psql."
[[ -x "${PREPARE_SCRIPT}" ]] || error "Nie znaleziono lub brak prawa wykonywania: ${PREPARE_SCRIPT}"
[[ -x "${IMPORT_SCRIPT}" ]] || error "Nie znaleziono lub brak prawa wykonywania: ${IMPORT_SCRIPT}"
[[ -x "${MAPSERVER_SCRIPT}" ]] || error "Nie znaleziono lub brak prawa wykonywania: ${MAPSERVER_SCRIPT}"
[[ -f "${SQL_FILE}" ]] || error "Nie znaleziono: ${SQL_FILE}"

info "Sprawdzanie polaczenia z PostgreSQL..."
sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "SELECT version();"

info "Zamykanie aktywnych polaczen i usuwanie bazy ${PG_DB}..."
sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "DROP DATABASE IF EXISTS ${PG_DB} WITH (FORCE);"

ok "Baza ${PG_DB} zostala usunieta."

info "Ponowne przygotowanie bazy ${PG_DB}..."
"${PREPARE_SCRIPT}"

info "Ponowny import struktury ${PG_DB}..."
"${IMPORT_SCRIPT}"

info "Ponowne nadawanie uprawnien dla MapServera..."
"${MAPSERVER_SCRIPT}"

echo
echo "============================================================"
echo " SUKCES"
echo " Baza rcn zostala usunieta i odtworzona od nowa."
echo " Uprawnienia ms_rcn zostaly ponownie skonfigurowane."
echo "============================================================"
