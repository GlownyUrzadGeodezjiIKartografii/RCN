#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - reset Etapu 1
# Usuniecie PostgreSQL 18 / PostGIS z testowego Debiana.
#
# UWAGA:
# - operacja destrukcyjna,
# - usuwa klaster PostgreSQL 18/main wraz z bazami i rolami,
# - usuwa baze rcn i schemat uslugi_rcn,
# - NIE usuwa repozytorium ~/RCN,
# - NIE usuwa aplikacji RCN Importer z Etapu 2.
# ============================================================

PG_MAJOR="18"
PG_CLUSTER="main"
PG_DATA="/var/lib/postgresql/${PG_MAJOR}"
PG_CONF="/etc/postgresql/${PG_MAJOR}"
PGDG_LIST="/etc/apt/sources.list.d/pgdg.list"
PGDG_KEY="/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

echo "============================================================"
echo " RCN - RESET ETAPU 1"
echo " PostgreSQL ${PG_MAJOR} / PostGIS"
echo "============================================================"
echo
echo "Skrypt usunie:"
echo "  - klaster PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}"
echo "  - wszystkie bazy i role znajdujace sie w tym klastrze"
echo "  - baze rcn i schemat uslugi_rcn"
echo "  - pakiety PostgreSQL ${PG_MAJOR} i PostGIS"
echo "  - konfiguracje PostgreSQL ${PG_MAJOR}"
echo "  - repozytorium PGDG dodane podczas instalacji"
echo
echo "Skrypt NIE usuwa:"
echo "  - repozytorium ~/RCN"
echo "  - aplikacji /opt/gugik/rcn-importer"
echo "  - uzytkownika systemowego rcn-importer"
echo "  - jednostek systemd RCN Importer"
echo
echo "UWAGA: operacji nie mozna cofnac."
echo

read -r -p "Aby kontynuowac, wpisz dokladnie: CZYSTY_DEBIAN : " CONFIRM

if [[ "${CONFIRM}" != "CZYSTY_DEBIAN" ]]; then
    echo "Operacja anulowana."
    exit 0
fi

[[ -r /etc/os-release ]] || error "Brak /etc/os-release."

# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "debian" ]] || error "Skrypt jest przeznaczony dla Debiana."

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."

info "Weryfikacja uprawnien administratora..."
sudo -v

# ------------------------------------------------------------
# 1. Usuniecie klastra PostgreSQL 18/main
# ------------------------------------------------------------

if command -v pg_dropcluster >/dev/null 2>&1 && \
   command -v pg_lsclusters >/dev/null 2>&1 && \
   pg_lsclusters --no-header 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_MAJOR} ${PG_CLUSTER}"; then

    info "Usuwanie klastra PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}..."
    sudo pg_dropcluster --stop "${PG_MAJOR}" "${PG_CLUSTER}"
    ok "Usunieto klaster PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}."
else
    ok "Klaster PostgreSQL ${PG_MAJOR}/${PG_CLUSTER} nie istnieje lub narzedzia klastra nie sa dostepne."
fi

# ------------------------------------------------------------
# 2. Usuniecie pakietow PostgreSQL/PostGIS
# ------------------------------------------------------------

info "Usuwanie pakietow PostgreSQL ${PG_MAJOR} i PostGIS..."

sudo apt-get purge -y \
    "postgresql-${PG_MAJOR}" \
    "postgresql-client-${PG_MAJOR}" \
    "postgresql-${PG_MAJOR}-postgis-3" \
    "postgresql-${PG_MAJOR}-postgis-3-scripts" || true

info "Usuwanie niepotrzebnych zaleznosci..."
sudo apt-get autoremove -y --purge || true

# ------------------------------------------------------------
# 3. Usuniecie pozostalych katalogow PostgreSQL 18
# ------------------------------------------------------------

if [[ -d "${PG_DATA}" ]]; then
    warn "Pozostal katalog ${PG_DATA}; usuwam."
    sudo rm -rf --one-file-system "${PG_DATA}"
    ok "Usunieto ${PG_DATA}."
else
    ok "Katalog ${PG_DATA} nie istnieje."
fi

if [[ -d "${PG_CONF}" ]]; then
    warn "Pozostal katalog ${PG_CONF}; usuwam."
    sudo rm -rf --one-file-system "${PG_CONF}"
    ok "Usunieto ${PG_CONF}."
else
    ok "Katalog ${PG_CONF} nie istnieje."
fi

# ------------------------------------------------------------
# 4. Usuniecie repozytorium PGDG
# ------------------------------------------------------------

info "Usuwanie repozytorium PGDG dodanego podczas instalacji..."

if [[ -e "${PGDG_LIST}" ]]; then
    sudo rm -f "${PGDG_LIST}"
    ok "Usunieto ${PGDG_LIST}."
else
    ok "Plik ${PGDG_LIST} nie istnieje."
fi

if [[ -e "${PGDG_KEY}" ]]; then
    sudo rm -f "${PGDG_KEY}"
    ok "Usunieto ${PGDG_KEY}."
else
    ok "Plik ${PGDG_KEY} nie istnieje."
fi

info "Aktualizacja informacji o pakietach..."
sudo apt-get update

# ------------------------------------------------------------
# 5. Weryfikacja
# ------------------------------------------------------------

echo
echo "============================================================"
echo " WERYFIKACJA"
echo "============================================================"

LEFT=0

if [[ -e "${PG_DATA}" ]]; then
    warn "Katalog ${PG_DATA} nadal istnieje."
    LEFT=1
else
    ok "Brak katalogu ${PG_DATA}."
fi

if [[ -e "${PG_CONF}" ]]; then
    warn "Katalog ${PG_CONF} nadal istnieje."
    LEFT=1
else
    ok "Brak katalogu ${PG_CONF}."
fi

if [[ -e "${PGDG_LIST}" ]]; then
    warn "Plik ${PGDG_LIST} nadal istnieje."
    LEFT=1
else
    ok "Brak pliku ${PGDG_LIST}."
fi

if [[ -e "${PGDG_KEY}" ]]; then
    warn "Plik ${PGDG_KEY} nadal istnieje."
    LEFT=1
else
    ok "Brak pliku ${PGDG_KEY}."
fi

if command -v pg_lsclusters >/dev/null 2>&1 && \
   pg_lsclusters --no-header 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_MAJOR} ${PG_CLUSTER}"; then
    warn "Klaster PostgreSQL ${PG_MAJOR}/${PG_CLUSTER} nadal istnieje."
    LEFT=1
else
    ok "Brak klastra PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}."
fi

echo
info "Repozytorium ~/RCN oraz Etap 2 nie zostaly usuniete."

echo
if (( LEFT == 0 )); then
    echo "============================================================"
    echo " RESET ETAPU 1 ZAKONCZONY POPRAWNIE"
    echo
    echo " Mozesz ponownie rozpoczac instalacje bazy danych"
    echo " zgodnie z instrukcja Etapu 1."
    echo "============================================================"
else
    echo "============================================================"
    echo " RESET ETAPU 1 ZAKONCZONY Z OSTRZEZENIAMI"
    echo " Sprawdz pozycje oznaczone [UWAGA]."
    echo "============================================================"
fi
