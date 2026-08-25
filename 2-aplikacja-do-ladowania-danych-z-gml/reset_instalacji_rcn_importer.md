# RCN Importer — reset instalacji aplikacji

Ta procedura dotyczy wyłącznie **Etapu 2 — RCN Importer**. Służy do usunięcia instalacji aplikacji i przywrócenia stanu umożliwiającego ponowne wykonanie Etapu 2.

Reset **nie jest elementem standardowej pierwszej instalacji**.

Skrypt resetujący znajduje się w repozytorium:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/reset_instalacji_rcn_importer.sh
```

## 1. Przejście do katalogu Etapu 2

Przejdź do katalogu Etapu 2:

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```

Sprawdź, czy skrypt znajduje się w katalogu:

```bash
ls -l reset_instalacji_rcn_importer.sh
```

## 2. Nadanie uprawnień do uruchomienia skryptu

Jeżeli skrypt nie ma jeszcze uprawnień do wykonywania, nadaj je poleceniem:

```bash
chmod +x reset_instalacji_rcn_importer.sh
```

Uprawnienie wystarczy nadać jednokrotnie.

## 3. Uruchomienie resetu

Uruchom skrypt z uprawnieniami administratora:

```bash
sudo ./reset_instalacji_rcn_importer.sh
```

Skrypt wymaga świadomego potwierdzenia operacji.

Po wyświetleniu pytania wpisz:

```text
RESET_RCN_IMPORTER
```

i zatwierdź klawiszem Enter.

> **Ważne**
>
> Reset usuwa instalację aplikacji RCN Importer. Przed potwierdzeniem upewnij się, że chcesz usunąć katalog aplikacji, użytkownika systemowego oraz konfigurację automatycznego uruchamiania Etapu 2.

## 4. Co zostanie usunięte

Skrypt usuwa elementy związane z instalacją RCN Importer, w szczególności:

- katalog instalacyjny `/opt/gugik/rcn-importer`;
- katalog `/opt/gugik`, jeżeli po usunięciu aplikacji pozostanie pusty;
- użytkownika systemowego `rcn-importer`;
- grupę `rcn-importer`, jeżeli może zostać usunięta;
- jednostkę `/etc/systemd/system/rcn-importer.service`, jeżeli istnieje;
- jednostkę `/etc/systemd/system/rcn-importer.timer`, jeżeli istnieje;
- ewentualny crontab użytkownika `rcn-importer`.

Jeżeli skonfigurowano usługę lub timer systemd, skrypt powinien je zatrzymać i wyłączyć przed usunięciem ich konfiguracji.

## 5. Czego skrypt nie usuwa

Skrypt **nie usuwa**:

- repozytorium `~/RCN`;
- plików pobranych z repozytorium Git;
- katalogów i materiałów Etapu 1;
- katalogów i materiałów Etapu 3;
- PostgreSQL;
- PostGIS;
- bazy danych `rcn`;
- schematu `uslugi_rcn`;
- danych znajdujących się w bazie;
- konfiguracji PostgreSQL wykonanej w Etapie 1.

Dzięki temu po resecie można ponownie rozpocząć instalację aplikacji bez ponownego pobierania repozytorium i bez ponownej instalacji bazy danych.

## 6. Weryfikacja resetu

Po zakończeniu działania skryptu sprawdź, czy elementy Etapu 2 zostały poprawnie usunięte.

### 6.1. Sprawdzenie katalogu aplikacji

Wykonaj:

```bash
if [ -e /opt/gugik/rcn-importer ]; then
    echo "UWAGA - katalog /opt/gugik/rcn-importer nadal istnieje"
else
    echo "OK - katalog aplikacji został usunięty"
fi
```

Oczekiwany rezultat:

```text
OK - katalog aplikacji został usunięty
```

### 6.2. Sprawdzenie użytkownika systemowego

Wykonaj:

```bash
if id rcn-importer >/dev/null 2>&1; then
    echo "UWAGA - użytkownik rcn-importer nadal istnieje"
else
    echo "OK - użytkownik rcn-importer został usunięty"
fi
```

Oczekiwany rezultat:

```text
OK - użytkownik rcn-importer został usunięty
```

### 6.3. Sprawdzenie jednostek systemd

Wykonaj:

```bash
if systemctl list-unit-files --no-legend 2>/dev/null | grep -qE '^rcn-importer\.(service|timer)'; then
    echo "UWAGA - nadal istnieją jednostki systemd RCN Importer"
    systemctl list-unit-files --no-legend | grep -E '^rcn-importer\.(service|timer)'
else
    echo "OK - jednostki systemd RCN Importer zostały usunięte"
fi
```

Oczekiwany rezultat:

```text
OK - jednostki systemd RCN Importer zostały usunięte
```

### 6.4. Sprawdzenie repozytorium

Repozytorium powinno pozostać na serwerze.

Sprawdź:

```bash
ls -la ~/RCN
```

Powinny być nadal dostępne katalogi poszczególnych etapów, w tym:

```text
1-baza-danych
2-aplikacja-do-ladowania-danych-z-gml
3-konfiguracja-uslugi
```

## 7. Ponowna instalacja

Po poprawnym wykonaniu resetu repozytorium `~/RCN` pozostaje bez zmian.

Instalację aplikacji można rozpocząć ponownie od:

**punktu 2 — Przejście do Etapu 2 w repozytorium**

w instrukcji:

```text
2-Instrukcja-Instalacji-Aplikacji-RCN-Importer-Linux-Debian.md
```

Nie ma potrzeby ponownego klonowania repozytorium ani ponownej instalacji PostgreSQL/PostGIS.

> **Ważne**
>
> Repozytorium `~/RCN` pozostaje bez zmian. Reset usuwa wyłącznie instalację aplikacji RCN Importer oraz elementy systemowe związane z Etapem 2. Nie usuwa PostgreSQL, PostGIS, bazy `rcn`, schematu `uslugi_rcn` ani danych znajdujących się w bazie.
