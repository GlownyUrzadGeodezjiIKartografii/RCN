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
# Skrypt NIE nadaje praw:
# - INSERT,
# - UPDATE,
# - DELETE,
# - CREATE.
#
# Haslo uzytkownika ms_rcn musi:
# - miec co najmniej 12 znakow,
# - zawierac mala litere,
# - zawierac wielka litere,
# - zawierac cyfre,
# - zawierac znak specjalny,
# - nie zawierac nazwy uzytkownika ms_rcn.
# ============================================================

PG_MAJOR="18"
PG_BIN="/usr/lib/postgresql/${PG_MAJOR}/bin"

PG_DB="rcn"
RCN_SCHEMA="uslugi_rcn"
MAP_USER="ms_rcn"

MIN_PASSWORD_LENGTH=12


# ============================================================
# Funkcje pomocnicze
# ============================================================

info() {
    printf '\n[INFO] %s\n' "$*"
}

ok() {
    printf '[OK]   %s\n' "$*"
}

warn() {
    printf '[UWAGA] %s\n' "$*"
}

error() {
    printf '[BLAD] %s\n' "$*" >&2
    exit 1
}


trap '
    printf "\n[BLAD] Konfiguracja uzytkownika MapServer zostala przerwana w linii %s.\n" "$LINENO" >&2
' ERR


echo "============================================================"
echo " RCN - konfiguracja uzytkownika MapServer"
echo "============================================================"


# ============================================================
# 1. Weryfikacja srodowiska
# ============================================================

info "Weryfikacja srodowiska..."

command -v sudo >/dev/null 2>&1 \
    || error "Nie znaleziono polecenia sudo."

sudo -v

[[ -x "${PG_BIN}/psql" ]] \
    || error "Nie znaleziono ${PG_BIN}/psql."

ok "Srodowisko jest gotowe."


# ============================================================
# 2. Weryfikacja bazy rcn
# ============================================================

info "Sprawdzanie bazy ${PG_DB}..."

DB_EXISTS="$(
    sudo -u postgres "${PG_BIN}/psql" \
        -d postgres \
        -Atq \
        -v ON_ERROR_STOP=1 \
        -c "SELECT EXISTS (
              SELECT 1
              FROM pg_database
              WHERE datname='${PG_DB}'
            );"
)"

[[ "${DB_EXISTS}" == "t" ]] \
    || error "Baza ${PG_DB} nie istnieje."

ok "Baza ${PG_DB} istnieje."


# ============================================================
# 3. Weryfikacja schematu
# ============================================================

info "Sprawdzanie schematu ${RCN_SCHEMA}..."

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

[[ "${SCHEMA_EXISTS}" == "t" ]] \
    || error "Schemat ${RCN_SCHEMA} nie istnieje. Najpierw uruchom 02_import_struktury_rcn.sh."

ok "Schemat ${RCN_SCHEMA} istnieje."


# ============================================================
# 4. Weryfikacja wymaganych widokow materializowanych
# ============================================================

info "Sprawdzanie wymaganych widokow materializowanych..."

for VIEW_NAME in \
    mv_dzialki \
    mv_budynki \
    mv_lokale
do
    EXISTS="$(
        sudo -u postgres "${PG_BIN}/psql" \
            -d "${PG_DB}" \
            -Atq \
            -v ON_ERROR_STOP=1 \
            -c "SELECT to_regclass('${RCN_SCHEMA}.${VIEW_NAME}') IS NOT NULL;"
    )"

    [[ "${EXISTS}" == "t" ]] \
        || error "Nie znaleziono ${RCN_SCHEMA}.${VIEW_NAME}."

    ok "Znaleziono ${RCN_SCHEMA}.${VIEW_NAME}."
done


# ============================================================
# 5. Weryfikacja konfiguracji SCRAM
# ============================================================

info "Weryfikacja konfiguracji hasel PostgreSQL..."

PASSWORD_ENCRYPTION_DB="$(
    sudo -u postgres "${PG_BIN}/psql" \
        -d postgres \
        -Atq \
        -v ON_ERROR_STOP=1 \
        -c "SHOW password_encryption;"
)"

[[ "${PASSWORD_ENCRYPTION_DB}" == "scram-sha-256" ]] \
    || error "PostgreSQL nie jest skonfigurowany do zapisywania nowych hasel przy uzyciu SCRAM-SHA-256."

ok "Nowe hasla sa zapisywane przy uzyciu SCRAM-SHA-256."


# ============================================================
# 6. Sprawdzenie, czy uzytkownik ms_rcn juz istnieje
# ============================================================

info "Sprawdzanie uzytkownika ${MAP_USER}..."

ROLE_EXISTS="$(
    sudo -u postgres "${PG_BIN}/psql" \
        -d postgres \
        -Atq \
        -v ON_ERROR_STOP=1 \
        -c "SELECT EXISTS (
              SELECT 1
              FROM pg_roles
              WHERE rolname='${MAP_USER}'
            );"
)"


# ============================================================
# 7. Utworzenie uzytkownika i ustawienie silnego hasla
# ============================================================

if [[ "${ROLE_EXISTS}" != "t" ]]; then

    echo
    echo "Tworzenie uzytkownika PostgreSQL ${MAP_USER}."
    echo
    echo "Haslo musi:"
    echo " - miec co najmniej ${MIN_PASSWORD_LENGTH} znakow,"
    echo " - zawierac co najmniej jedna mala litere,"
    echo " - zawierac co najmniej jedna wielka litere,"
    echo " - zawierac co najmniej jedna cyfre,"
    echo " - zawierac co najmniej jeden znak specjalny,"
    echo " - nie zawierac nazwy uzytkownika ${MAP_USER}."
    echo

    while true; do

        read -r -s -p "Podaj haslo dla ${MAP_USER}: " MAP_PASSWORD
        echo

        read -r -s -p "Powtorz haslo: " MAP_PASSWORD_2
        echo


        # ----------------------------------------------------
        # Zgodnosc hasel
        # ----------------------------------------------------

        if [[ "${MAP_PASSWORD}" != "${MAP_PASSWORD_2}" ]]; then
            warn "Podane hasla nie sa identyczne."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Minimalna dlugosc
        # ----------------------------------------------------

        if (( ${#MAP_PASSWORD} < MIN_PASSWORD_LENGTH )); then
            warn "Haslo musi miec co najmniej ${MIN_PASSWORD_LENGTH} znakow."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Mala litera
        # ----------------------------------------------------

        if [[ ! "${MAP_PASSWORD}" =~ [[:lower:]] ]]; then
            warn "Haslo musi zawierac co najmniej jedna mala litere."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Wielka litera
        # ----------------------------------------------------

        if [[ ! "${MAP_PASSWORD}" =~ [[:upper:]] ]]; then
            warn "Haslo musi zawierac co najmniej jedna wielka litere."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Cyfra
        # ----------------------------------------------------

        if [[ ! "${MAP_PASSWORD}" =~ [[:digit:]] ]]; then
            warn "Haslo musi zawierac co najmniej jedna cyfre."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Znak specjalny
        # ----------------------------------------------------

        if [[ ! "${MAP_PASSWORD}" =~ [^[:alnum:]] ]]; then
            warn "Haslo musi zawierac co najmniej jeden znak specjalny."
            echo
            continue
        fi


        # ----------------------------------------------------
        # Haslo nie moze zawierac nazwy uzytkownika
        # ----------------------------------------------------

        MAP_PASSWORD_LOWER="${MAP_PASSWORD,,}"
        MAP_USER_LOWER="${MAP_USER,,}"

        if [[ "${MAP_PASSWORD_LOWER}" == *"${MAP_USER_LOWER}"* ]]; then
            warn "Haslo nie moze zawierac nazwy uzytkownika ${MAP_USER}."
            echo
            continue
        fi


        # Wszystkie wymagania zostaly spelnione.
        break
    done


    # ========================================================
    # 8. Utworzenie roli
    # ========================================================

    info "Tworzenie uzytkownika ${MAP_USER}..."

    # Zabezpieczenie pojedynczych apostrofow w hasle.
    MAP_PASSWORD_SQL="${MAP_PASSWORD//\'/\'\'}"

    # SQL przekazujemy przez stdin.
    # Haslo nie jest przekazywane jako argument procesu psql.
    printf "CREATE ROLE %s LOGIN PASSWORD '%s';\n" \
        "${MAP_USER}" \
        "${MAP_PASSWORD_SQL}" \
        | sudo -u postgres "${PG_BIN}/psql" \
            -d postgres \
            -v ON_ERROR_STOP=1 \
            >/dev/null

    unset MAP_PASSWORD
    unset MAP_PASSWORD_2
    unset MAP_PASSWORD_SQL
    unset MAP_PASSWORD_LOWER
    unset MAP_USER_LOWER

    ok "Utworzono uzytkownika ${MAP_USER}."


    # ========================================================
    # 9. Weryfikacja SCRAM dla utworzonego uzytkownika
    # ========================================================

    info "Weryfikacja sposobu przechowywania hasla ${MAP_USER}..."

    SCRAM_OK="$(
        sudo -u postgres "${PG_BIN}/psql" \
            -d postgres \
            -Atq \
            -v ON_ERROR_STOP=1 \
            -c "SELECT CASE
                  WHEN rolpassword IS NOT NULL
                   AND rolpassword LIKE 'SCRAM-SHA-256\$%'
                  THEN 't'
                  ELSE 'f'
                END
                FROM pg_authid
                WHERE rolname='${MAP_USER}';"
    )"

    [[ "${SCRAM_OK}" == "t" ]] \
        || error "Haslo uzytkownika ${MAP_USER} nie zostalo zapisane przy uzyciu SCRAM-SHA-256."

    ok "Haslo uzytkownika ${MAP_USER} jest przechowywane przy uzyciu SCRAM-SHA-256."

else

    ok "Uzytkownik ${MAP_USER} juz istnieje. Haslo nie zostanie zmienione."

fi


# ============================================================
# 10. Nadanie minimalnych uprawnien
# ============================================================

info "Nadawanie minimalnych uprawnien dla MapServera..."

sudo -u postgres "${PG_BIN}/psql" \
    -d "${PG_DB}" \
    -v ON_ERROR_STOP=1 <<SQL

REVOKE ALL ON SCHEMA ${RCN_SCHEMA}
FROM ${MAP_USER};

REVOKE ALL ON ALL TABLES IN SCHEMA ${RCN_SCHEMA}
FROM ${MAP_USER};

GRANT CONNECT ON DATABASE ${PG_DB}
TO ${MAP_USER};

GRANT USAGE ON SCHEMA ${RCN_SCHEMA}
TO ${MAP_USER};

GRANT SELECT ON TABLE
    ${RCN_SCHEMA}.mv_dzialki,
    ${RCN_SCHEMA}.mv_budynki,
    ${RCN_SCHEMA}.mv_lokale
TO ${MAP_USER};

SQL

ok "Nadano wymagane uprawnienia."


# ============================================================
# 11. Weryfikacja uprawnien
# ============================================================

info "Weryfikacja uprawnien..."

PERMISSIONS="$(
    sudo -u postgres "${PG_BIN}/psql" \
        -d "${PG_DB}" \
        -Atq \
        -v ON_ERROR_STOP=1 \
        -c "SELECT
              has_database_privilege(
                  '${MAP_USER}',
                  '${PG_DB}',
                  'CONNECT'
              )::int || '|' ||

              has_schema_privilege(
                  '${MAP_USER}',
                  '${RCN_SCHEMA}',
                  'USAGE'
              )::int || '|' ||

              has_table_privilege(
                  '${MAP_USER}',
                  '${RCN_SCHEMA}.mv_dzialki',
                  'SELECT'
              )::int || '|' ||

              has_table_privilege(
                  '${MAP_USER}',
                  '${RCN_SCHEMA}.mv_budynki',
                  'SELECT'
              )::int || '|' ||

              has_table_privilege(
                  '${MAP_USER}',
                  '${RCN_SCHEMA}.mv_lokale',
                  'SELECT'
              )::int;"
)"

[[ "${PERMISSIONS}" == "1|1|1|1|1" ]] \
    || error "Weryfikacja uprawnien uzytkownika ${MAP_USER} nie powiodla sie."

ok "CONNECT do bazy ${PG_DB}."
ok "USAGE na schemacie ${RCN_SCHEMA}."
ok "SELECT na ${RCN_SCHEMA}.mv_dzialki."
ok "SELECT na ${RCN_SCHEMA}.mv_budynki."
ok "SELECT na ${RCN_SCHEMA}.mv_lokale."


# ============================================================
# 12. Koniec
# ============================================================

echo
echo "============================================================"
echo " Uzytkownik ${MAP_USER} jest skonfigurowany poprawnie."
echo
echo " Uprawnienia:"
echo "   CONNECT -> ${PG_DB}"
echo "   USAGE   -> ${RCN_SCHEMA}"
echo "   SELECT  -> ${RCN_SCHEMA}.mv_dzialki"
echo "   SELECT  -> ${RCN_SCHEMA}.mv_budynki"
echo "   SELECT  -> ${RCN_SCHEMA}.mv_lokale"
echo
echo " Uzytkownik nie posiada uprawnien do modyfikacji danych."
echo
echo " UWAGA:"
echo " Dostep sieciowy nalezy skonfigurowac osobno w:"
echo "   /etc/postgresql/${PG_MAJOR}/main/postgresql.conf"
echo "   /etc/postgresql/${PG_MAJOR}/main/pg_hba.conf"
echo "============================================================"
