#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - instalacja PostgreSQL 18 i PostGIS 3
# System docelowy: Debian 12 lub nowszy
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"
PG_DATA="/var/lib/postgresql/${PG_MAJOR}/main"
PG_CLUSTER="main"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[BLAD] Instalacja zostala przerwana w linii %s.\n" "$LINENO" >&2' ERR

echo "============================================================"
echo " RCN - instalacja PostgreSQL ${PG_MAJOR} i PostGIS"
echo " Debian"
echo "============================================================"

[[ -r /etc/os-release ]] || error "Nie mozna odczytac /etc/os-release."
# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "debian" ]] || error "Ten skrypt jest przeznaczony dla Debiana."
ok "Wykryto: ${PRETTY_NAME:-Debian}"

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

info "Instalacja narzedzi wymaganych do konfiguracji repozytorium..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg postgresql-common

info "Konfiguracja oficjalnego repozytorium PostgreSQL PGDG..."
sudo install -d /usr/share/postgresql-common/pgdg

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo gpg --dearmor --yes -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg

CODENAME="${VERSION_CODENAME:-}"
[[ -n "${CODENAME}" ]] || error "Nie mozna ustalic VERSION_CODENAME z /etc/os-release."

echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null

sudo apt-get update

info "Instalacja PostgreSQL ${PG_MAJOR} i PostGIS..."
sudo apt-get install -y \
  "postgresql-${PG_MAJOR}" \
  "postgresql-client-${PG_MAJOR}" \
  "postgresql-contrib" \
  "postgresql-${PG_MAJOR}-postgis-3" \
  "postgresql-${PG_MAJOR}-postgis-3-scripts"

[[ -x "${PG_BIN}/psql" ]] || error "Nie znaleziono ${PG_BIN}/psql po instalacji."
ok "$("${PG_BIN}/psql" --version)"

info "Sprawdzanie klastra PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}..."

if pg_lsclusters --no-header 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_MAJOR} ${PG_CLUSTER}"; then
    ok "Klaster ${PG_MAJOR}/${PG_CLUSTER} juz istnieje."
else
    info "Tworzenie klastra ${PG_MAJOR}/${PG_CLUSTER}..."
    sudo pg_createcluster "${PG_MAJOR}" "${PG_CLUSTER}" --start
fi

if ! sudo test -s "${PG_DATA}/PG_VERSION"; then
    error "Nie znaleziono ${PG_DATA}/PG_VERSION."
fi

CLUSTER_VERSION="$(sudo cat "${PG_DATA}/PG_VERSION")"
[[ "${CLUSTER_VERSION}" == "${PG_MAJOR}" ]] \
  || error "Wykryto klaster PostgreSQL ${CLUSTER_VERSION}, oczekiwano ${PG_MAJOR}."

info "Uruchamianie PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

if ! pg_lsclusters --no-header 2>/dev/null | awk '$1=="18" && $2=="main" {print $4}' | grep -qx online; then
    warn "Klaster nie jest online. Proba uruchomienia..."
    sudo pg_ctlcluster "${PG_MAJOR}" "${PG_CLUSTER}" start
fi

pg_lsclusters

info "Weryfikacja serwera PostgreSQL..."
sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "SELECT version();"

info "Sprawdzanie dostepnosci rozszerzenia PostGIS..."
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
  || error "Rozszerzenie PostGIS nie jest dostepne dla PostgreSQL ${PG_MAJOR}."

ok "PostgreSQL ${PG_MAJOR} i PostGIS sa zainstalowane poprawnie."

echo
echo "============================================================"
echo " Nastepny krok:"
echo "   ./01_przygotowanie_bazy_rcn.sh"
echo "============================================================"
