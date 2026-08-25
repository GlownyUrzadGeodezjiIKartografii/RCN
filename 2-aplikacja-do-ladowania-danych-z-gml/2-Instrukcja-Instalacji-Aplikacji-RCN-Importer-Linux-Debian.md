# RCN Importer — instrukcja instalacji aplikacji na Linux Debian

Dokument opisuje **Etap 2** wdrożenia RCN: instalację aplikacji RCN Importer i pierwsze załadowanie danych GML/ZIP. Zakłada, że wykonano już Etap 1 i repozytorium RCN znajduje się w `~/RCN`.

## Informacje o aplikacji

**Nazwa:** RCN Importer  
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)  
**Autor:** Szymon Szczerba  
**Rok:** 2026  
**Technologia:** .NET 9  
**Typ aplikacji:** aplikacja konsolowa  
**Wersja:** 1.0  
**Plik wykonywalny:** `rcn-importer-1.0`  
**Publikacja:** self-contained `linux-x64`

Na serwerze nie trzeba instalować .NET Runtime. Aplikacja wykonuje jeden cykl importu i kończy pracę; nie działa stale jako daemon.

## 1. Założenia przed rozpoczęciem

Przed rozpoczęciem Etapu 2 muszą być spełnione następujące warunki:

- Debian **13 (trixie) lub nowszy**, `x86_64/amd64`;  
- repozytorium RCN zostało już sklonowane do `~/RCN`;  
- Etap 1 został zakończony i zweryfikowany;  
- działa PostgreSQL 18/PostGIS;  
- istnieje baza `rcn` i schemat `uslugi_rcn`;  
- zostało ustawione i zapisane hasło użytkownika PostgreSQL używanego przez importer;  
- administrator ma `sudo`.  

> **Nie klonuj repozytorium ponownie.** Etap 2 korzysta z plików pobranych wcześniej w ramach całego repozytorium RCN.

## 2. Przejście do Etapu 2 w repozytorium

Po wykonaniu Etapu 1 repozytorium powinno już znajdować się w:

```text
~/RCN
```

Przejdź do katalogu Etapu 2:

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
ls -la
```

Aktualna struktura tego katalogu jest następująca:

```text
2-aplikacja-do-ladowania-danych-z-gml/
├── gml/
│   ├── 1864-1-bazowy.zip
│   ├── 1864-2-przyrostowy.zip
│   └── count.sql
├── publish/
│   └── linux-x64/
│       ├── rcn-importer-1.0
│       ├── appsettings.json
│       └── pozostałe pliki publikacji
├── 2-Aplikacja-RCN-Importer.md
├── 2-Instrukcja-Instalacji-Aplikacji-RCN-Importer-Linux-Debian.md
├── reset_instalacji_rcn_importer.md
└── reset_instalacji_rcn_importer.sh
```

Znaczenie najważniejszych elementów:

- `publish/linux-x64` — kompletna publikacja aplikacji przeznaczona do skopiowania do `/opt/gugik/rcn-importer`;
- `gml/1864-1-bazowy.zip` — testowy plik bazowy;
- `gml/1864-2-przyrostowy.zip` — testowy plik przyrostowy;
- `gml/count.sql` — pomocnicze zapytania do weryfikacji liczby danych po imporcie;
- `2-Aplikacja-RCN-Importer.md` — opis działania i konfiguracji aplikacji;
- `reset_instalacji_rcn_importer.*` — materiały administracyjne do usunięcia instalacji aplikacji; nie są częścią standardowej pierwszej instalacji.

> **Nie klonuj repozytorium ponownie.**
>
> Etap 2 korzysta z plików znajdujących się już w `~/RCN`.

Jeżeli chcesz jedynie pobrać najnowszą wersję plików:

```bash
cd ~/RCN
git pull --ff-only
```

Po aktualizacji wróć do Etapu 2:

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```


## 3. Utworzenie użytkownika systemowego

Aplikacja powinna działać jako dedykowany użytkownik `rcn-importer`, a nie jako `root`.

```bash
id rcn-importer
```

Jeżeli użytkownik nie istnieje:

```bash
sudo useradd --system --user-group \
  --home-dir /opt/gugik/rcn-importer \
  --shell /usr/sbin/nologin rcn-importer
```

Sprawdź:

```bash
id rcn-importer
```

Nie ma potrzeby dodawania konta administratora do grupy `rcn-importer`. Konfigurację można edytować za pomocą `sudo`.

## 4. Utworzenie katalogu docelowego

```bash
sudo mkdir -p /opt/gugik/rcn-importer
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Docelowa lokalizacja aplikacji:

```text
/opt/gugik/rcn-importer
```

## 5. Skopiowanie aplikacji z repozytorium

Pliki aplikacji są już dostępne w repozytorium w katalogu:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/publish/linux-x64
```

Nie twórz dodatkowego katalogu `~/RCN/rcn-importer` i nie przesyłaj plików aplikacji osobno przez WinSCP.

Skopiuj **całą zawartość** katalogu `publish/linux-x64` do katalogu produkcyjnego:

```bash
sudo cp -a ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/publish/linux-x64/.   /opt/gugik/rcn-importer/
```

Następnie ustaw właściciela plików:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Sprawdź skopiowane pliki:

```bash
ls -la /opt/gugik/rcn-importer
```

W katalogu powinny znajdować się co najmniej:

```text
rcn-importer-1.0
appsettings.json
pozostałe pliki i biblioteki publikacji
```

> **Ważne**
>
> Kopiuj cały katalog publikacji. Sam plik `rcn-importer-1.0` nie wystarcza do działania aplikacji.


## 6. Katalogi robocze i uprawnienia

```bash
sudo mkdir -p /opt/gugik/rcn-importer/{input,processed,error,artifacts,logs}
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
sudo chmod -R u=rwX,g=rX,o= /opt/gugik/rcn-importer
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

Docelowo:

```text
/opt/gugik/rcn-importer/
├── rcn-importer-1.0
├── appsettings.json
├── input/
├── processed/
├── error/
├── artifacts/
└── logs/
```

## 7. Konfiguracja `appsettings.json`

Edytuj konfigurację:

```bash
sudo nano /opt/gugik/rcn-importer/appsettings.json
```

Przykład:

```json
{
  "Database": {
    "ConnectionName": "Localhost",
    "Schema": "uslugi_rcn"
  },
  "ConnectionStrings": {
    "Localhost": "Host=localhost;Port=5432;Database=rcn;Username=postgres;Password=UZUPELNIJ"
  },
  "ImportJob": {
    "TerytPow": "1864",
    "InputPath": "input",
    "ProcessedPath": "processed",
    "ErrorPath": "error",
    "ArtifactsDir": "artifacts",
    "LogDirectory": "logs",
    "Mode": "REPLACE",
    "MoveFilesAfterImport": true,
    "RetentionDays": 7
  }
}
```

Uzupełnij przede wszystkim hasło, `TerytPow` i świadomie wybierz `Mode`. Nie zapisuj rzeczywistych haseł w repozytorium Git.

Po edycji ponownie ogranicz dostęp:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/appsettings.json
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

### Tryby importu

- `REPLACE` — zastępuje dane powiatu kompletnym zestawem z danego uruchomienia;
- `UPSERT` — aktualizuje istniejące rekordy i dodaje nowe;
- `INSERT` — dodaje nowe dane zgodnie z logiką aplikacji.

Jeżeli w `input` znajduje się kilka plików, aplikacja analizuje je osobno, a poprawne dane scala do jednej kolekcji przed zapisem. W `REPLACE` błąd części zestawu blokuje częściowe zastąpienie danych.

## 8. Sprawdzenie dostępu do bazy

Dla lokalnej bazy:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn -c "SELECT current_database();"
```

Sprawdź również schemat:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn -c "\dt uslugi_rcn.*"
```

Jeżeli baza jest zdalna, konfiguracja `listen_addresses`, `pg_hba.conf` i zapory została opisana w Etapie 1.

## 9. Pierwsze uruchomienie bez danych

```bash
cd /opt/gugik/rcn-importer
sudo -u rcn-importer ./rcn-importer-1.0
echo $?
```

Przy pustym `input` kod `5` oznacza brak plików wejściowych, a nie awarię bazy.

## 10. Pierwszy import testowy

W repozytorium znajdują się przygotowane pliki testowe:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-1-bazowy.zip
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-2-przyrostowy.zip
```

oraz pomocniczy skrypt SQL:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

Pliki testowe dotyczą powiatu o kodzie:

```text
1864
```

Dlatego przed ich użyciem upewnij się, że w `appsettings.json` ustawiono:

```json
"TerytPow": "1864"
```

### 10.1. Test importu bazowego

Skopiuj plik bazowy do katalogu `input`:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-1-bazowy.zip   /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer   /opt/gugik/rcn-importer/input/1864-1-bazowy.zip
```

Uruchom aplikację:

```bash
cd /opt/gugik/rcn-importer
sudo -u rcn-importer ./rcn-importer-1.0
```

Sprawdź katalogi:

```bash
ls -la processed
ls -la error
ls -la artifacts
ls -la logs
```

Po poprawnym imporcie plik powinien trafić do `processed`.

### 10.2. Sprawdzenie danych w bazie

Do repozytorium dołączony jest plik `count.sql`, który pozwala szybko sprawdzić liczbę załadowanych obiektów.

Wykonaj:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql   -d rcn   -f ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

### 10.3. Test importu przyrostowego

Po poprawnym imporcie pliku bazowego możesz przetestować import przyrostowy.

Skopiuj:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-2-przyrostowy.zip   /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer   /opt/gugik/rcn-importer/input/1864-2-przyrostowy.zip
```

Przed uruchomieniem upewnij się, że wybrany w `appsettings.json` tryb `Mode` odpowiada sposobowi, w jaki chcesz wykonać test.

Uruchom importer:

```bash
cd /opt/gugik/rcn-importer
sudo -u rcn-importer ./rcn-importer-1.0
```

Po zakończeniu ponownie wykonaj:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql   -d rcn   -f ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

> **Ważne**
>
> Pliki `1864-1-bazowy.zip` i `1864-2-przyrostowy.zip` są plikami testowymi dołączonymi do repozytorium. W środowisku docelowym do katalogu `input` należy przekazywać właściwe pliki GML/ZIP zawierające dane RCN danego powiatu.


## 11. Automatyczne uruchamianie — systemd timer

Najpierw wykonaj co najmniej jeden poprawny import ręczny. Dopiero potem konfiguruj automatykę.

Utwórz usługę:

```bash
sudo nano /etc/systemd/system/rcn-importer.service
```

```ini
[Unit]
Description=GUGiK RCN Importer
After=network-online.target postgresql.service
Wants=network-online.target

[Service]
Type=oneshot
User=rcn-importer
Group=rcn-importer
WorkingDirectory=/opt/gugik/rcn-importer
ExecStart=/opt/gugik/rcn-importer/rcn-importer-1.0
NoNewPrivileges=true
PrivateTmp=true
```

Przeładuj konfigurację i przetestuj:

```bash
sudo systemctl daemon-reload
sudo systemctl start rcn-importer.service
sudo systemctl status rcn-importer.service
```

Utwórz timer, np. codziennie o 02:00:

```bash
sudo nano /etc/systemd/system/rcn-importer.timer
```

```ini
[Unit]
Description=Codzienne uruchamianie RCN Importer

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
Unit=rcn-importer.service

[Install]
WantedBy=timers.target
```

Włącz:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now rcn-importer.timer
systemctl list-timers --all | grep rcn
```

Nie konfiguruj jednocześnie `cron` i `systemd timer` dla tej samej instalacji. Zalecany jest `systemd timer`.

## 12. Aktualizacja aplikacji z repozytorium

Nie przesyłaj nowej wersji przez WinSCP. Zaktualizuj repozytorium:

```bash
cd ~/RCN
git pull --ff-only
```

Następnie zatrzymaj timer, wykonaj kopię konfiguracji i skopiuj aktualną publikację z Etapu 2 do `/opt/gugik/rcn-importer`. Nie nadpisuj bez kontroli produkcyjnego `appsettings.json`.

```bash
sudo systemctl stop rcn-importer.timer
sudo cp /opt/gugik/rcn-importer/appsettings.json /tmp/rcn-importer-appsettings.json.bak
```

Po skopiowaniu nowej publikacji przywróć konfigurację, właściciela i uprawnienia, wykonaj test ręczny, a następnie:

```bash
sudo systemctl start rcn-importer.timer
```

## 13. Diagnostyka

Logi aplikacji:

```bash
ls -lht /opt/gugik/rcn-importer/logs
```

Logi systemd:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Najczęściej sprawdzaj również:

```bash
df -h
du -sh /opt/gugik/rcn-importer
sudo systemctl status rcn-importer.timer
```

## 14. Reset wyłącznie Etapu 2

Skrypt resetujący znajduje się w katalogu Etapu 2 repozytorium. Nie jest elementem standardowej instalacji. Używaj go tylko wtedy, gdy świadomie chcesz usunąć instalację RCN Importer.

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
./reset_instalacji_rcn_importer.sh
```

Skrypt usuwa instalację aplikacji z `/opt`, użytkownika `rcn-importer` oraz jednostki systemd, ale **nie usuwa repozytorium `~/RCN`, PostgreSQL, PostGIS ani bazy `rcn`**.

## 15. Weryfikacja zakończenia Etapu 2

Etap 2 można uznać za zakończony, jeżeli:

- istnieje `/opt/gugik/rcn-importer/rcn-importer-1.0`;
- aplikacja uruchamia się jako `rcn-importer`;
- `appsettings.json` zawiera poprawne połączenie, `TerytPow` i `Mode`;
- wykonano co najmniej jeden poprawny import;
- pliki trafiają do `processed` albo `error`;
- powstają logi i artefakty;
- dane są zapisane w bazie `rcn`;
- widoki materializowane są odświeżane;
- jeżeli skonfigurowano automatykę — `rcn-importer.timer` jest aktywny.

Po pozytywnej weryfikacji można przejść do **Etapu 3 — konfiguracji usługi publikacyjnej MapServer**.
