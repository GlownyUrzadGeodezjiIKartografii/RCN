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
# - skrypt NIE usuwa schematu uslugi_rcn.
#
# Usuwane sa tylko elementy utworzone podczas instalacji
# aplikacji RCN Importer.
# ============================================================

APP_USER="rcn-importer"
APP_GROUP="rcn-importer"
APP_DIR="/opt/gugik/rcn-importer"

SERVICE_FILE="/etc/systemd/system/rcn-importer.service"
TIMER_FILE="/etc/systemd/system/rcn-importer.timer"

# Katalog roboczy utworzony zgodnie z instrukcja.
# ${SUDO_USER:-$USER} wskazuje uzytkownika, ktory uruchomil sudo.
ADMIN_USER="${SUDO_USER:-$USER}"
ADMIN_HOME="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
STAGING_DIR="${ADMIN_HOME}/RCN/rcn-importer"

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
echo "  - katalog roboczy ${STAGING_DIR}"
echo
echo "Skrypt NIE usuwa:"
echo "  - PostgreSQL"
echo "  - PostGIS"
echo "  - bazy rcn"
echo "  - schematu uslugi_rcn"
echo

read -r -p "Aby kontynuowac, wpisz dokladnie: RESET_RCN_IMPORTER : " CONFIRM
[[ "${CONFIRM}" == "RESET_RCN_IMPORTER" ]] || {
    echo "Operacja anulowana."
    exit 0
}

command -v sudo >/dev/null 2>&1 || error "Nie znaleziono polecenia sudo."
sudo -v

# ------------------------------------------------------------
# 1. Zatrzymanie i usuniecie systemd
# ------------------------------------------------------------

info "Zatrzymywanie timera i uslugi systemd..."

if systemctl list-unit-files 2>/dev/null | grep -q '^rcn-importer.timer'; then
    sudo systemctl disable --now rcn-importer.timer || true
fi

if systemctl list-unit-files 2>/dev/null | grep -q '^rcn-importer.service'; then
    sudo systemctl stop rcn-importer.service || true
fi

if [[ -f "${TIMER_FILE}" ]]; then
    sudo rm -f "${TIMER_FILE}"
    ok "Usunieto ${TIMER_FILE}"
fi

if [[ -f "${SERVICE_FILE}" ]]; then
    sudo rm -f "${SERVICE_FILE}"
    ok "Usunieto ${SERVICE_FILE}"
fi

sudo systemctl daemon-reload
sudo systemctl reset-failed rcn-importer.service 2>/dev/null || true

# ------------------------------------------------------------
# 2. Usuniecie ewentualnego crontaba uzytkownika aplikacji
# ------------------------------------------------------------

if id "${APP_USER}" >/dev/null 2>&1; then
    info "Usuwanie ewentualnego crontaba uzytkownika ${APP_USER}..."
    sudo crontab -r -u "${APP_USER}" 2>/dev/null || true
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
# 6. Usuniecie katalogu roboczego z katalogu administratora
# ------------------------------------------------------------

if [[ -d "${STAGING_DIR}" ]]; then
    info "Usuwanie katalogu roboczego ${STAGING_DIR}..."
    sudo rm -rf --one-file-system "${STAGING_DIR}"
    ok "Usunieto ${STAGING_DIR}"
else
    ok "Katalog ${STAGING_DIR} nie istnieje."
fi

# Usun ~/RCN tylko jezeli jest pusty.
RCN_PARENT="${ADMIN_HOME}/RCN"

if [[ -d "${RCN_PARENT}" ]] && \
   [[ -z "$(sudo find "${RCN_PARENT}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    sudo rmdir "${RCN_PARENT}"
    ok "Usunieto pusty katalog ${RCN_PARENT}"
fi

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
    warn "Pozostaly pliki systemd."
    LEFT=1
else
    ok "Brak jednostek systemd RCN Importer."
fi

if [[ -e "${STAGING_DIR}" ]]; then
    warn "Katalog roboczy ${STAGING_DIR} nadal istnieje."
    LEFT=1
else
    ok "Brak katalogu roboczego ${STAGING_DIR}."
fi

echo

if (( LEFT == 0 )); then
    echo "============================================================"
    echo " RESET ZAKONCZONY POPRAWNIE"
    echo
    echo " Mozesz ponownie rozpoczac instrukcje instalacji"
    echo " RCN Importer od pierwszego kroku."
    echo "============================================================"
else
    echo "============================================================"
    echo " RESET ZAKONCZONY Z OSTRZEZENIAMI"
    echo " Sprawdz pozycje oznaczone [UWAGA]."
    echo "============================================================"
fi
