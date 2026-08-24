#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN - konfiguracja uzytkownika PostgreSQL dla MapServera
# Debian / PostgreSQL 18
#
# Uzytkownik ms_rcn otrzymuje w bazie rcn tylko:
# - CONNECT do bazy rcn,
# - USAGE na schemat uslugi_rcn,
# - SELECT na:
#     uslugi_rcn.mv_dzialki
#     uslugi_rcn.mv_budynki
#     uslugi_rcn.mv_lokale
#
# Skrypt NIE nadaje praw INSERT / UPDATE / DELETE / CREATE.
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"
PG_DB="rcn"
RCN_SCHEMA="uslugi_rcn"
MAP_USER="ms_rcn"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

trap 'printf "\n[BLAD] Konfiguracja uzytkownika MapServer zostala przerwana w linii %s.\n" "$LINENO" >&2' ERR

echo "============================================================"
echo " RCN - konfiguracja uzytkownika MapServer"
echo "============================================================"

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

[[ -x "${PG_BIN}/psql" ]] || error "Nie znaleziono ${PG_BIN}/psql."

DB_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres -Atq -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname='${PG_DB}');"
)"
[[ "${DB_EXISTS}" == "t" ]] || error "Baza ${PG_DB} nie istnieje."

SCHEMA_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" -Atq -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (
          SELECT 1 FROM information_schema.schemata
          WHERE schema_name='${RCN_SCHEMA}'
        );"
)"
[[ "${SCHEMA_EXISTS}" == "t" ]] || error "Schemat ${RCN_SCHEMA} nie istnieje. Najpierw uruchom 02_import_struktury_rcn.sh."

for VIEW_NAME in mv_dzialki mv_budynki mv_lokale; do
    EXISTS="$(
      sudo -u postgres "${PG_BIN}/psql" \
        -d "${PG_DB}" -Atq -v ON_ERROR_STOP=1 \
        -c "SELECT to_regclass('${RCN_SCHEMA}.${VIEW_NAME}') IS NOT NULL;"
    )"
    [[ "${EXISTS}" == "t" ]] || error "Nie znaleziono ${RCN_SCHEMA}.${VIEW_NAME}."
done

ROLE_EXISTS="$(
  sudo -u postgres "${PG_BIN}/psql" \
    -d postgres -Atq -v ON_ERROR_STOP=1 \
    -c "SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${MAP_USER}');"
)"

if [[ "${ROLE_EXISTS}" != "t" ]]; then
    echo
    echo "Tworzenie uzytkownika PostgreSQL ${MAP_USER}."
    read -r -s -p "Podaj haslo dla ${MAP_USER}: " MAP_PASSWORD
    echo
    read -r -s -p "Powtorz haslo: " MAP_PASSWORD_2
    echo

    [[ -n "${MAP_PASSWORD}" ]] || error "Haslo nie moze byc puste."
    [[ "${MAP_PASSWORD}" == "${MAP_PASSWORD_2}" ]] || error "Hasla nie sa zgodne."

    # Escaping pojedynczego apostrofu do literału SQL.
    MAP_PASSWORD_SQL="${MAP_PASSWORD//\'/\'\'}"

    sudo -u postgres "${PG_BIN}/psql" \
      -d postgres \
      -v ON_ERROR_STOP=1 \
      -c "CREATE ROLE ${MAP_USER} LOGIN PASSWORD '${MAP_PASSWORD_SQL}';"

    unset MAP_PASSWORD MAP_PASSWORD_2 MAP_PASSWORD_SQL
    ok "Utworzono uzytkownika ${MAP_USER}."
else
    ok "Uzytkownik ${MAP_USER} juz istnieje. Haslo nie zostanie zmienione."
fi

info "Nadawanie minimalnych uprawnien dla MapServera..."

sudo -u postgres "${PG_BIN}/psql" \
  -d "${PG_DB}" \
  -v ON_ERROR_STOP=1 <<SQL
REVOKE ALL ON SCHEMA ${RCN_SCHEMA} FROM ${MAP_USER};
REVOKE ALL ON ALL TABLES IN SCHEMA ${RCN_SCHEMA} FROM ${MAP_USER};

GRANT CONNECT ON DATABASE ${PG_DB} TO ${MAP_USER};
GRANT USAGE ON SCHEMA ${RCN_SCHEMA} TO ${MAP_USER};

GRANT SELECT ON TABLE
    ${RCN_SCHEMA}.mv_dzialki,
    ${RCN_SCHEMA}.mv_budynki,
    ${RCN_SCHEMA}.mv_lokale
TO ${MAP_USER};
SQL

info "Weryfikacja uprawnien..."

sudo -u postgres "${PG_BIN}/psql" \
  -d "${PG_DB}" \
  -v ON_ERROR_STOP=1 \
  -c "SELECT
        has_database_privilege('${MAP_USER}', '${PG_DB}', 'CONNECT') AS connect_rcn,
        has_schema_privilege('${MAP_USER}', '${RCN_SCHEMA}', 'USAGE') AS usage_schema,
        has_table_privilege('${MAP_USER}', '${RCN_SCHEMA}.mv_dzialki', 'SELECT') AS select_mv_dzialki,
        has_table_privilege('${MAP_USER}', '${RCN_SCHEMA}.mv_budynki', 'SELECT') AS select_mv_budynki,
        has_table_privilege('${MAP_USER}', '${RCN_SCHEMA}.mv_lokale', 'SELECT') AS select_mv_lokale;"

echo
echo "============================================================"
echo " Uzytkownik ${MAP_USER} jest skonfigurowany."
echo
echo " UWAGA:"
echo " Dostep sieciowy nalezy skonfigurowac osobno w:"
echo "   /etc/postgresql/18/main/postgresql.conf"
echo "   /etc/postgresql/18/main/pg_hba.conf"
echo "============================================================"
