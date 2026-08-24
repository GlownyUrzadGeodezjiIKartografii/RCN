#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - usuniecie PostgreSQL 18 / PostGIS z testowego Debiana
# UWAGA: operacja destrukcyjna.
# ============================================================

PG_MAJOR="18"
PG_DATA="/var/lib/postgresql/${PG_MAJOR}"
PG_CONF="/etc/postgresql/${PG_MAJOR}"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

echo "============================================================"
echo " CZYSZCZENIE TESTOWEGO DEBIANA"
echo " PostgreSQL ${PG_MAJOR} / PostGIS"
echo "============================================================"
echo
echo "UWAGA: zostana usuniete bazy PostgreSQL ${PG_MAJOR} i konfiguracja."
read -r -p "Aby kontynuowac, wpisz dokladnie: CZYSTY_DEBIAN : " CONFIRM
[[ "${CONFIRM}" == "CZYSTY_DEBIAN" ]] || { echo "Operacja anulowana."; exit 0; }

[[ -r /etc/os-release ]] || error "Brak /etc/os-release."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "debian" ]] || error "Skrypt jest przeznaczony dla Debiana."

command -v sudo >/dev/null 2>&1 || error "Brak sudo."
sudo -v

if command -v pg_dropcluster >/dev/null 2>&1 && \
   pg_lsclusters --no-header 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_MAJOR} main"; then
    info "Usuwanie klastra ${PG_MAJOR}/main..."
    sudo pg_dropcluster --stop "${PG_MAJOR}" main
fi

info "Usuwanie pakietow PostgreSQL ${PG_MAJOR} i PostGIS..."
sudo apt-get purge -y \
  "postgresql-${PG_MAJOR}" \
  "postgresql-client-${PG_MAJOR}" \
  "postgresql-${PG_MAJOR}-postgis-3" \
  "postgresql-${PG_MAJOR}-postgis-3-scripts" || true

sudo apt-get autoremove -y --purge || true

if [[ -d "${PG_DATA}" ]]; then
    warn "Pozostal katalog ${PG_DATA}; usuwam."
    sudo rm -rf --one-file-system "${PG_DATA}"
fi

if [[ -d "${PG_CONF}" ]]; then
    warn "Pozostal katalog ${PG_CONF}; usuwam."
    sudo rm -rf --one-file-system "${PG_CONF}"
fi

info "Usuwanie repozytorium PGDG dodanego przez skrypt..."
sudo rm -f /etc/apt/sources.list.d/pgdg.list
sudo rm -f /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg
sudo apt-get update

echo
echo "============================================================"
echo " Czyszczenie zakonczone."
echo "============================================================"
