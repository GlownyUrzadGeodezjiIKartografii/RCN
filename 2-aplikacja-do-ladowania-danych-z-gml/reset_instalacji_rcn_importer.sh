#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RCN Importer - przywrocenie systemu do stanu sprzed instalacji
# aplikacji RCN Importer.
#
# UWAGA:
# - skrypt NIE usuwa PostgreSQL,
# - skrypt NIE usuwa PostGIS,
# - skrypt NIE usuwa bazy danych rcn,
# - skrypt NIE usuwa schematu uslugi_rcn,
# - skrypt NIE usuwa repozytorium ~/RCN.
#
# Usuwane sa tylko elementy utworzone podczas instalacji
# aplikacji RCN Importer w Etapie 2.
# ============================================================

APP_USER="rcn-importer"
APP_GROUP="rcn-importer"
APP_DIR="/opt/gugik/rcn-importer"

SERVICE_FILE="/etc/systemd/system/rcn-importer.service"
TIMER_FILE="/etc/systemd/system/rcn-importer.timer"

info()  { printf '\n[INFO] %s\n' "$*"; }
ok()    { printf '[OK]   %s\n' "$*"; }
warn()  { printf '[UWAGA] %s\n' "$*"; }
error() { printf '[BLAD] %s\n' "$*" >&2; exit 1; }

echo "============================================================"
echo " RCN IMPORTER - RESET INSTALACJI"
echo "============================================================"
echo
echo "Skrypt usunie:"
echo "  - ${APP_DIR}"
echo "  - uzytkownika systemowego ${APP_USER}"
echo "  - grupe ${APP_GROUP}, jezeli nie bedzie juz potrzebna"
echo "  - ${SERVICE_FILE}"
echo "  - ${TIMER_FILE}"
echo "  - ewentualny crontab uzytkownika ${APP_USER}"
echo
echo "Skrypt NIE usuwa:"
echo "  - PostgreSQL"
echo "  - PostGIS"
echo "  - bazy rcn"
echo "  - schematu uslugi_rcn"
echo "  - danych znajdujacych sie w bazie"
echo "  - repozytorium ~/RCN"
echo

read -r -p "Aby kontynuowac, wpisz dokladnie: RESET_RCN_IMPORTER : " CONFIRM

if [[ "${CONFIRM}" != "RESET_RCN_IMPORTER" ]]; then
    echo "Operacja anulowana."
    exit 0
fi

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."

info "Weryfikacja uprawnien administratora..."
sudo -v

# ------------------------------------------------------------
# 1. Zatrzymanie i usuniecie jednostek systemd
# ------------------------------------------------------------

info "Zatrzymywanie timera i uslugi systemd..."

if systemctl list-unit-files --no-legend 2>/dev/null | grep -qE '^rcn-importer\.timer'; then
    sudo systemctl disable --now rcn-importer.timer || true
fi

if systemctl list-unit-files --no-legend 2>/dev/null | grep -qE '^rcn-importer\.service'; then
    sudo systemctl stop rcn-importer.service || true
fi

if [[ -f "${TIMER_FILE}" ]]; then
    sudo rm -f "${TIMER_FILE}"
    ok "Usunieto ${TIMER_FILE}"
else
    ok "Plik ${TIMER_FILE} nie istnieje."
fi

if [[ -f "${SERVICE_FILE}" ]]; then
    sudo rm -f "${SERVICE_FILE}"
    ok "Usunieto ${SERVICE_FILE}"
else
    ok "Plik ${SERVICE_FILE} nie istnieje."
fi

sudo systemctl daemon-reload
sudo systemctl reset-failed rcn-importer.service 2>/dev/null || true

# ------------------------------------------------------------
# 2. Usuniecie ewentualnego crontaba uzytkownika aplikacji
# ------------------------------------------------------------

if id "${APP_USER}" >/dev/null 2>&1; then
    info "Usuwanie ewentualnego crontaba uzytkownika ${APP_USER}..."
    sudo crontab -r -u "${APP_USER}" 2>/dev/null || true
else
    ok "Uzytkownik ${APP_USER} nie istnieje - pomijam crontab."
fi

# ------------------------------------------------------------
# 3. Usuniecie katalogu aplikacji
# ------------------------------------------------------------

if [[ -d "${APP_DIR}" ]]; then
    info "Usuwanie katalogu aplikacji ${APP_DIR}..."
    sudo rm -rf --one-file-system "${APP_DIR}"
    ok "Usunieto ${APP_DIR}"
else
    ok "Katalog ${APP_DIR} nie istnieje."
fi

# Jezeli /opt/gugik jest pusty, usun go rowniez.
if [[ -d /opt/gugik ]] && \
   [[ -z "$(sudo find /opt/gugik -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    sudo rmdir /opt/gugik
    ok "Usunieto pusty katalog /opt/gugik"
fi

# ------------------------------------------------------------
# 4. Usuniecie uzytkownika systemowego
# ------------------------------------------------------------

if id "${APP_USER}" >/dev/null 2>&1; then
    info "Usuwanie uzytkownika systemowego ${APP_USER}..."
    sudo userdel "${APP_USER}"
    ok "Usunieto uzytkownika ${APP_USER}"
else
    ok "Uzytkownik ${APP_USER} nie istnieje."
fi

# ------------------------------------------------------------
# 5. Usuniecie grupy
# ------------------------------------------------------------

if getent group "${APP_GROUP}" >/dev/null 2>&1; then
    info "Usuwanie grupy ${APP_GROUP}..."
    sudo groupdel "${APP_GROUP}" 2>/dev/null || true

    if getent group "${APP_GROUP}" >/dev/null 2>&1; then
        warn "Grupa ${APP_GROUP} nadal istnieje. Sprawdz recznie jej czlonkow."
    else
        ok "Usunieto grupe ${APP_GROUP}"
    fi
else
    ok "Grupa ${APP_GROUP} nie istnieje."
fi

# ------------------------------------------------------------
# 6. Repozytorium pozostaje bez zmian
# ------------------------------------------------------------

info "Repozytorium ~/RCN nie jest usuwane przez reset Etapu 2."

# ------------------------------------------------------------
# 7. Weryfikacja
# ------------------------------------------------------------

echo
echo "============================================================"
echo " WERYFIKACJA"
echo "============================================================"

LEFT=0

if id "${APP_USER}" >/dev/null 2>&1; then
    warn "Uzytkownik ${APP_USER} nadal istnieje."
    LEFT=1
else
    ok "Brak uzytkownika ${APP_USER}."
fi

if getent group "${APP_GROUP}" >/dev/null 2>&1; then
    warn "Grupa ${APP_GROUP} nadal istnieje."
    LEFT=1
else
    ok "Brak grupy ${APP_GROUP}."
fi

if [[ -e "${APP_DIR}" ]]; then
    warn "Katalog ${APP_DIR} nadal istnieje."
    LEFT=1
else
    ok "Brak katalogu ${APP_DIR}."
fi

if [[ -e "${SERVICE_FILE}" || -e "${TIMER_FILE}" ]]; then
    warn "Pozostaly pliki jednostek systemd RCN Importer."
    LEFT=1
else
    ok "Brak plikow jednostek systemd RCN Importer."
fi

if systemctl list-unit-files --no-legend 2>/dev/null | grep -qE '^rcn-importer\.(service|timer)'; then
    warn "Systemd nadal widzi jednostki RCN Importer."
    systemctl list-unit-files --no-legend 2>/dev/null | grep -E '^rcn-importer\.(service|timer)' || true
    LEFT=1
else
    ok "Systemd nie widzi jednostek RCN Importer."
fi

echo

if (( LEFT == 0 )); then
    echo "============================================================"
    echo " RESET ZAKONCZONY POPRAWNIE"
    echo
    echo " Mozesz ponownie rozpoczac instalacje RCN Importer"
    echo " od punktu 2 instrukcji Etapu 2."
    echo "============================================================"
else
    echo "============================================================"
    echo " RESET ZAKONCZONY Z OSTRZEZENIAMI"
    echo " Sprawdz pozycje oznaczone [UWAGA]."
    echo "============================================================"
fi
