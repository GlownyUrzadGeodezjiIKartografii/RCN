#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - instalacja PostgreSQL 18 i PostGIS 3
# System docelowy: Debian 13 lub nowszy
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

# ============================================================
# Weryfikacja systemu
# ============================================================

[[ -r /etc/os-release ]] || error "Nie mozna odczytac /etc/os-release."

# shellcheck disable=SC1091
source /etc/os-release

[[ "${ID:-}" == "debian" ]] \
  || error "Ten skrypt jest przeznaczony dla Debiana."

ok "Wykryto: ${PRETTY_NAME:-Debian}"

command -v sudo >/dev/null 2>&1 \
  || error "Nie znaleziono polecenia sudo."

sudo -v

# ============================================================
# Instalacja narzedzi wymaganych do konfiguracji repozytorium
# ============================================================

info "Instalacja narzedzi wymaganych do konfiguracji repozytorium..."

sudo apt-get update

sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  postgresql-common

# ============================================================
# Konfiguracja oficjalnego repozytorium PostgreSQL PGDG
# ============================================================

info "Konfiguracja oficjalnego repozytorium PostgreSQL PGDG..."

sudo install -d /usr/share/postgresql-common/pgdg

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo gpg --dearmor --yes \
      -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg

CODENAME="${VERSION_CODENAME:-}"

[[ -n "${CODENAME}" ]] \
  || error "Nie mozna ustalic VERSION_CODENAME z /etc/os-release."

echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null

sudo apt-get update

# ============================================================
# Instalacja PostgreSQL, PostGIS i modulu passwordcheck
# ============================================================

info "Instalacja PostgreSQL ${PG_MAJOR}, PostGIS i modulow dodatkowych..."

sudo apt-get install -y \
  "postgresql-${PG_MAJOR}" \
  "postgresql-client-${PG_MAJOR}" \
  "postgresql-contrib-${PG_MAJOR}" \
  "postgresql-${PG_MAJOR}-postgis-3" \
  "postgresql-${PG_MAJOR}-postgis-3-scripts"

[[ -x "${PG_BIN}/psql" ]] \
  || error "Nie znaleziono ${PG_BIN}/psql po instalacji."

ok "$("${PG_BIN}/psql" --version)"

# ============================================================
# Sprawdzenie i uruchomienie klastra PostgreSQL
# ============================================================

info "Sprawdzanie klastra PostgreSQL ${PG_MAJOR}/${PG_CLUSTER}..."

if pg_lsclusters --no-header 2>/dev/null \
  | awk '{print $1" "$2}' \
  | grep -qx "${PG_MAJOR} ${PG_CLUSTER}"; then

    ok "Klaster ${PG_MAJOR}/${PG_CLUSTER} juz istnieje."

else
    info "Tworzenie klastra ${PG_MAJOR}/${PG_CLUSTER}..."

    sudo pg_createcluster \
      "${PG_MAJOR}" \
      "${PG_CLUSTER}" \
      --start
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

if ! pg_lsclusters --no-header 2>/dev/null \
  | awk -v ver="${PG_MAJOR}" -v cluster="${PG_CLUSTER}" \
      '$1==ver && $2==cluster {print $4}' \
  | grep -qx online; then

    warn "Klaster nie jest online. Proba uruchomienia..."

    sudo pg_ctlcluster \
      "${PG_MAJOR}" \
      "${PG_CLUSTER}" \
      start
fi

pg_lsclusters

# ============================================================
# Weryfikacja PostgreSQL
# ============================================================

info "Weryfikacja serwera PostgreSQL..."

sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "SELECT version();"

# ============================================================
# Weryfikacja PostGIS
# ============================================================

info "Sprawdzanie dostepnosci rozszerzenia PostGIS..."

POSTGIS_AVAILABLE="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1
          FROM pg_available_extensions
          WHERE name = 'postgis'
        );"
)"

[[ "${POSTGIS_AVAILABLE}" == "t" ]] \
  || error "Rozszerzenie PostGIS nie jest dostepne dla PostgreSQL ${PG_MAJOR}."

ok "Rozszerzenie PostGIS jest dostepne."

# ============================================================
# Konfiguracja bezpieczenstwa hasel PostgreSQL
# ============================================================

info "Konfiguracja polityki bezpieczenstwa hasel PostgreSQL..."

PASSWORDCHECK_LIB="${PG_BIN%/bin}/lib/passwordcheck.so"

# Sprawdzenie dostepnosci modulu passwordcheck.
# Jezeli z jakiegos powodu modul nie jest dostepny,
# zostanie podjeta proba jego doinstalowania.
if [[ ! -f "${PASSWORDCHECK_LIB}" ]]; then

    warn "Nie znaleziono modulu passwordcheck."
    info "Instalacja modulu passwordcheck dla PostgreSQL ${PG_MAJOR}..."

    sudo apt-get update
    sudo apt-get install -y "postgresql-contrib-${PG_MAJOR}"
fi

[[ -f "${PASSWORDCHECK_LIB}" ]] \
  || error "Nie udalo sie zainstalowac modulu passwordcheck: ${PASSWORDCHECK_LIB}"

ok "Modul passwordcheck jest dostepny."

# ============================================================
# Konfiguracja SCRAM-SHA-256
# ============================================================

info "Konfiguracja SCRAM-SHA-256 dla nowych hasel..."

sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "ALTER SYSTEM SET password_encryption = 'scram-sha-256';"

# ============================================================
# Wlaczenie passwordcheck
# ============================================================

info "Konfiguracja modulu passwordcheck..."

CURRENT_SHARED_LIBRARIES="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SHOW shared_preload_libraries;"
)"

if [[ "${CURRENT_SHARED_LIBRARIES}" != *"passwordcheck"* ]]; then

    if [[ -z "${CURRENT_SHARED_LIBRARIES}" ]]; then
        NEW_SHARED_LIBRARIES="\$libdir/passwordcheck"
    else
        NEW_SHARED_LIBRARIES="${CURRENT_SHARED_LIBRARIES},\$libdir/passwordcheck"
    fi

    sudo -u postgres "${PG_BIN}/psql" \
      -d postgres \
      -v ON_ERROR_STOP=1 \
      -c "ALTER SYSTEM SET shared_preload_libraries = '${NEW_SHARED_LIBRARIES}';"

else
    ok "Modul passwordcheck jest juz skonfigurowany."
fi

# Modul passwordcheck wymaga restartu PostgreSQL.
info "Restart PostgreSQL po konfiguracji kontroli hasel..."

sudo pg_ctlcluster \
  "${PG_MAJOR}" \
  "${PG_CLUSTER}" \
  restart

# ============================================================
# Minimalna dlugosc hasla
# ============================================================

info "Ustawianie minimalnej dlugosci hasla..."

sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "ALTER SYSTEM SET passwordcheck.min_password_length = 12;"

sudo -u postgres "${PG_BIN}/psql" \
  -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "SELECT pg_reload_conf();"

# ============================================================
# Weryfikacja konfiguracji bezpieczenstwa
# ============================================================

info "Weryfikacja konfiguracji bezpieczenstwa hasel..."

PASSWORD_ENCRYPTION="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SHOW password_encryption;"
)"

MIN_PASSWORD_LENGTH="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SHOW passwordcheck.min_password_length;"
)"

SHARED_LIBRARIES="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres \
    -Atq \
    -v ON_ERROR_STOP=1 \
    -c "SHOW shared_preload_libraries;"
)"

[[ "${PASSWORD_ENCRYPTION}" == "scram-sha-256" ]] \
  || error "Nie udalo sie ustawic password_encryption = scram-sha-256."

[[ "${MIN_PASSWORD_LENGTH}" == "12" ]] \
  || error "Nie udalo sie ustawic minimalnej dlugosci hasla na 12."

[[ "${SHARED_LIBRARIES}" == *"passwordcheck"* ]] \
  || error "Modul passwordcheck nie zostal poprawnie zaladowany."

ok "Polityka bezpieczenstwa hasel PostgreSQL zostala skonfigurowana."
ok "Minimalna dlugosc nowego hasla: 12 znakow."
ok "Nowe hasla beda przechowywane przy uzyciu SCRAM-SHA-256."
ok "Modul passwordcheck jest aktywny."

# ============================================================
# Koniec instalacji
# ============================================================

echo
echo "============================================================"
echo " Instalacja zakonczona pomyslnie"
echo "============================================================"
echo
echo " PostgreSQL ${PG_MAJOR} i PostGIS zostaly zainstalowane."
echo
echo " Skonfigurowano zabezpieczenia hasel PostgreSQL:"
echo "   - aktywowano modul passwordcheck,"
echo "   - minimalna dlugosc nowego hasla: 12 znakow,"
echo "   - nowe hasla sa przechowywane przy uzyciu SCRAM-SHA-256."
echo
echo " Administrator powinien stosowac silne i unikalne hasla"
echo " zgodnie z zasadami bezpieczenstwa obowiazujacymi"
echo " w organizacji."
echo
echo "============================================================"
echo

ok "PostgreSQL ${PG_MAJOR} i PostGIS sa zainstalowane poprawnie."
