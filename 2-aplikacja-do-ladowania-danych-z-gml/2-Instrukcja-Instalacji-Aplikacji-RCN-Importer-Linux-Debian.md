# RCN Importer — instrukcja instalacji aplikacji na Linux Debian

Dokument przeznaczony jest dla administratora odpowiedzialnego za wdrożenie, konfigurację, uruchamianie i utrzymanie aplikacji **RCN Importer** w systemie Linux Debian.

## Informacje o aplikacji

**Nazwa:** RCN Importer  
**Wersja:** 1.0  
**Plik wykonywalny:** `rcn-importer-1.0`  
**Autor:** Szymon Szczerba  
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)  
**Rok:** 2026  
**Technologia:** .NET 9  
**Typ aplikacji:** aplikacja konsolowa  

Aplikacja jest publikowana jako **self-contained dla `linux-x64`**, dlatego na docelowym serwerze Debian **nie jest wymagane instalowanie .NET Runtime**.

---

## 1. Przeznaczenie

RCN Importer służy do automatycznego importu danych Rejestru Cen Nieruchomości z plików GML lub ZIP do bazy PostgreSQL/PostGIS.

Aplikacja wykonuje jeden cykl pracy:

1. odczytuje konfigurację,
2. wykonuje retencję starszych plików,
3. wyszukuje pliki w katalogu `input`,
4. odczytuje i diagnozuje poszczególne pliki GML oraz zawartość ZIP,
5. scala poprawnie odczytane dane do jednej wspólnej kolekcji RCN dla powiatu wskazanego w `TerytPow`,
6. wykonuje zapis do bazy zgodnie z trybem `REPLACE`, `UPSERT` albo `INSERT`,
7. zapisuje informacje o błędach z przypisaniem do konkretnego pliku,
8. przenosi pliki do `processed` albo `error`,
9. zapisuje artefakty w `artifacts`,
10. zapisuje logi,
11. odświeża widoki materializowane po wykonanym zapisie,
12. kończy działanie.

Aplikacja nie działa stale jako daemon. Zalecanym sposobem automatyzacji w Debianie jest **systemd timer**.

---

## 2. Wymagania serwera

Przed instalacją należy zapewnić:

- Debian 12 lub nowszy,
- architekturę `x86_64/amd64`,
- konto administratora lub konto z możliwością używania `sudo`,
- przygotowaną bazę PostgreSQL/PostGIS `rcn`,
- schemat `uslugi_rcn`,
- odpowiednie uprawnienia użytkownika bazy danych,
- pełny katalog publikacji aplikacji dla `linux-x64`,
- odpowiednią ilość miejsca na katalogi `processed`, `error`, `artifacts` i `logs`.

Sprawdzenie systemu:

```bash
cat /etc/os-release
```

Sprawdzenie numeru wersji Debiana:

```bash
cat /etc/debian_version
```

Sprawdzenie architektury:

```bash
uname -m
```

Dla publikacji `linux-x64` wynik powinien być:

```text
x86_64
```

---

## 3. Utworzenie użytkownika systemowego aplikacji

Aplikacja powinna być uruchamiana z dedykowanego użytkownika systemowego `rcn-importer`, a nie jako `root`.

Najpierw sprawdź, czy użytkownik już istnieje:

```bash
id rcn-importer
```

Jeżeli użytkownik nie istnieje, utwórz go:

```bash
sudo useradd \
  --system \
  --user-group \
  --home-dir /opt/gugik/rcn-importer \
  --shell /usr/sbin/nologin \
  rcn-importer
```

Sprawdź ponownie:

```bash
id rcn-importer
```

Dodaj administratora wdrażającego aplikację do grupy `rcn-importer`, aby mógł później edytować `appsettings.json` bez używania `sudo`. Przykład dla użytkownika `sszczerba`:

```bash
sudo usermod -aG rcn-importer sszczerba
```

Po wykonaniu polecenia sprawdź, czy użytkownik został zapisany w grupie:

```bash
groups sszczerba
```

Na liście musi znajdować się grupa `rcn-importer`.

### WAŻNE — wylogowanie i ponowne logowanie

Samo wykonanie `usermod` nie aktualizuje grup w już otwartej sesji SSH. **Przed przejściem do kolejnego punktu instrukcji należy zakończyć bieżącą sesję SSH:**

```bash
exit
```

Następnie połącz się ponownie z serwerem, np.:

```bash
ssh sszczerba@ADRES_IP_SERWERA
```

Po ponownym zalogowaniu sprawdź grupy aktywne w bieżącej sesji:

```bash
groups
```

W wyniku **musi** znajdować się `rcn-importer`, np.:

```text
sszczerba sudo users rcn-importer
```

Jeżeli `rcn-importer` nie występuje w wyniku polecenia `groups`, **nie przechodź do punktu 4**. Ponownie sprawdź:

```bash
groups sszczerba
```

i zakończ oraz otwórz ponownie sesję SSH.

> Katalog `/opt/gugik/rcn-importer` nie musi jeszcze istnieć. Zostanie utworzony dopiero po potwierdzeniu aktywnego członkostwa administratora w grupie `rcn-importer`.

---

## 4. Utworzenie katalogu docelowego aplikacji

> **Warunek rozpoczęcia tego punktu:** polecenie `groups` wykonane po ponownym zalogowaniu musi pokazywać grupę `rcn-importer`. Dzięki temu późniejsze polecenia `ls`, edycja `appsettings.json` i dostęp do katalogu aplikacji będą działały bez błędu `Permission denied`.

Utwórz katalog aplikacji:

```bash
sudo mkdir -p /opt/gugik/rcn-importer
```

Ustaw właściciela katalogu:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Sprawdź:

```bash
ls -ld /opt/gugik/rcn-importer
```

Docelowa lokalizacja aplikacji:

```text
/opt/gugik/rcn-importer
```

---

## 5. Przygotowanie katalogu do przesłania plików

Plików aplikacji **nie należy wgrywać przez WinSCP bezpośrednio do `/opt/gugik/rcn-importer`**.

Katalog `/opt` jest katalogiem systemowym i zwykły użytkownik logujący się przez WinSCP zazwyczaj nie ma do niego prawa zapisu.

Najpierw przygotuj katalog w katalogu domowym administratora:

```bash
mkdir -p ~/RCN/rcn-importer
```

Sprawdź:

```bash
ls -ld ~/RCN/rcn-importer
```

Dla użytkownika `sszczerba` pełna ścieżka będzie przykładowo:

```text
/home/sszczerba/RCN/rcn-importer
```

Do tego katalogu należy przesłać przez WinSCP **całą zawartość** katalogu publikacji:

```text
publish/linux-x64/
```

Nie należy kopiować wyłącznie pliku wykonywalnego `rcn-importer-1.0`.

---

## 6. Sprawdzenie przesłanych plików

Po przesłaniu aplikacji przejdź do katalogu:

```bash
cd ~/RCN/rcn-importer
```

Wyświetl zawartość:

```bash
ls -la
```

W katalogu powinny znajdować się m.in.:

```text
rcn-importer-1.0
appsettings.json
pozostałe pliki publikacji
```

---

## 7. Skopiowanie aplikacji do `/opt`

Skopiuj całą zawartość katalogu przygotowanego w katalogu domowym:

```bash
sudo cp -a ~/RCN/rcn-importer/. /opt/gugik/rcn-importer/
```

Sprawdź zawartość:

```bash
ls -la /opt/gugik/rcn-importer
```

Po skopiowaniu ustaw ponownie właściciela całej aplikacji:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

---

## 8. Utworzenie katalogów roboczych

Utwórz katalogi wykorzystywane przez aplikację:

```bash
sudo mkdir -p /opt/gugik/rcn-importer/input
sudo mkdir -p /opt/gugik/rcn-importer/processed
sudo mkdir -p /opt/gugik/rcn-importer/error
sudo mkdir -p /opt/gugik/rcn-importer/artifacts
sudo mkdir -p /opt/gugik/rcn-importer/logs
```

Ustaw właściciela:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Docelowa struktura:

```text
/opt/gugik/rcn-importer/
├── rcn-importer-1.0
├── appsettings.json
├── pozostałe pliki publikacji
├── input/
├── processed/
├── error/
├── artifacts/
└── logs/
```

---

## 9. Nadanie uprawnień

Nadaj właścicielowi aplikacji prawo odczytu, zapisu i wykonywania tam, gdzie jest to potrzebne:

```bash
sudo chmod -R u=rwX,g=rX,o= /opt/gugik/rcn-importer
```

Nadaj plikowi wykonywalnemu prawo wykonania:

```bash
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
```

Ustaw właściciela i grupę pliku konfiguracyjnego:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/appsettings.json
```

Nadaj właścicielowi i członkom grupy `rcn-importer` prawo odczytu i zapisu. Dzięki temu użytkownik administracyjny dodany wcześniej do tej grupy może edytować konfigurację bez `sudo`:

```bash
sudo chmod 660 /opt/gugik/rcn-importer/appsettings.json
```

Uprawnienie `660` oznacza, że właściciel i członkowie grupy `rcn-importer` mogą odczytywać i edytować plik, a pozostali użytkownicy nie mają do niego dostępu.

Sprawdź:

```bash
ls -la /opt/gugik/rcn-importer
```

---

### Docelowe uprawnienia

Docelowo:

- właścicielem katalogu aplikacji jest `rcn-importer`,
- grupą katalogu jest `rcn-importer`,
- użytkownik `sszczerba` należy do grupy `rcn-importer`,
- `sszczerba` może przeglądać katalog aplikacji,
- `sszczerba` może edytować `appsettings.json`,
- pozostali użytkownicy nie mają dostępu do konfiguracji.

Sprawdzenie:

```bash
groups
ls -ld /opt/gugik/rcn-importer
ls -l /opt/gugik/rcn-importer/appsettings.json
```

---

## 10. Konfiguracja `appsettings.json`

Po ponownym zalogowaniu użytkownik administracyjny należący do grupy `rcn-importer` może edytować konfigurację bez `sudo`:

```bash
nano /opt/gugik/rcn-importer/appsettings.json
```

W razie potrzeby administrator z uprawnieniami `sudo` może również użyć:

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

Ścieżki są względne względem katalogu aplikacji. Nie ma potrzeby wpisywania pełnych ścieżek typu:

```text
/opt/gugik/rcn-importer/input
```

Po zapisaniu konfiguracji prawa powinny pozostać następujące:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/appsettings.json
sudo chmod 660 /opt/gugik/rcn-importer/appsettings.json
```

Sprawdzenie:

```bash
ls -l /opt/gugik/rcn-importer/appsettings.json
```

Oczekiwane uprawnienia:

```text
-rw-rw---- ... rcn-importer rcn-importer ... appsettings.json
```

---

## 11. Powiat obsługiwany przez instalację

Parametr:

```json
"TerytPow": "1864"
```

określa czterocyfrowy kod TERYT powiatu, którego dane znajdują się w katalogu `input`.

Wszystkie pliki znajdujące się w `InputPath` powinny dotyczyć powiatu skonfigurowanego w `TerytPow`.

---

## 12. Tryb importu

Parametr:

```json
"Mode": "REPLACE"
```

obsługuje trzy wartości:

```text
REPLACE
UPSERT
INSERT
```

Znaczenie:

- `REPLACE` — zastępuje dotychczasowy zestaw danych powiatu nowym zestawem,
- `UPSERT` — aktualizuje istniejące rekordy i dodaje nowe,
- `INSERT` — dodaje nowe dane bez aktualizacji istniejących.

Administrator powinien przed uruchomieniem produkcyjnym upewnić się, że ustawiony tryb odpowiada oczekiwanemu sposobowi aktualizacji danych.

---

## 13. Wiele plików wejściowych

Jeżeli w katalogu `input` znajduje się więcej niż jeden plik, aplikacja najpierw analizuje poszczególne pliki, a następnie scala poprawne dane do jednej wspólnej kolekcji RCN dla powiatu wskazanego w `TerytPow`.

Przykład:

```text
input/
├── plik_1.gml
├── plik_2.gml
└── dane.zip
```

W trybie `REPLACE` poprawne pliki tworzą jeden zestaw danych przeznaczony do zastąpienia danych powiatu.

Jeżeli część zestawu jest błędna, częściowy `REPLACE` nie powinien być wykonywany. Chroni to istniejące dane przed zastąpieniem niekompletnym zbiorem.

W przypadku ZIP aplikacja może wskazać konkretny błędny plik GML znajdujący się wewnątrz archiwum.

---

## 14. Retencja plików

Parametr:

```json
"RetentionDays": 7
```

określa liczbę dni przechowywania plików w katalogach:

```text
processed
error
artifacts
logs
```

Katalog `input` nie jest objęty retencją.

Przykładowe wartości:

```text
0   → retencja wyłączona
7   → pliki mające 7 dni lub więcej są usuwane
30  → pliki mające 30 dni lub więcej są usuwane
< 0 → wartość traktowana jako nieprawidłowa; retencja nie powinna usuwać plików
```

---

## 15. Sprawdzenie dostępu do PostgreSQL

Jeżeli PostgreSQL działa na tym samym serwerze:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn
```

Wyświetlenie tabel w schemacie `uslugi_rcn`:

```text
\dt uslugi_rcn.*
```

Wyjście:

```text
\q
```

Jeżeli baza działa na innym serwerze, sprawdź port:

```bash
nc -vz HOST 5432
```

Jeżeli `nc` nie jest zainstalowane:

```bash
sudo apt update
sudo apt install netcat-openbsd
```

Administrator powinien również sprawdzić:

- host i port PostgreSQL,
- `listen_addresses`,
- `pg_hba.conf`,
- reguły zapory,
- użytkownika i hasło,
- uprawnienia użytkownika,
- istnienie bazy `rcn`,
- istnienie schematu `uslugi_rcn`,
- dostępność PostGIS.

---

## 16. Pierwsze uruchomienie ręczne

Przejdź do katalogu aplikacji:

```bash
cd /opt/gugik/rcn-importer
```

Uruchom aplikację jako użytkownik systemowy:

```bash
sudo -u rcn-importer ./rcn-importer-1.0
```

Po zakończeniu sprawdź kod wyjścia:

```bash
echo $?
```

Przykładowe kody:

```text
0 - sukces
1 - błąd importu
2 - anulowanie
3 - błąd konfiguracji
4 - błąd odświeżania widoków materializowanych
5 - brak plików wejściowych
```

Kod `5` przy pustym katalogu `input` nie oznacza awarii bazy danych.

---

## 17. Test z plikiem GML lub ZIP

Skopiuj plik testowy do:

```text
/opt/gugik/rcn-importer/input
```

Przykład:

```bash
sudo cp /sciezka/do/pliku/test.zip /opt/gugik/rcn-importer/input/
```

Ustaw właściciela:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/test.zip
```

Uruchom:

```bash
cd /opt/gugik/rcn-importer
sudo -u rcn-importer ./rcn-importer-1.0
```

Po wykonaniu sprawdź:

```bash
ls -la processed
ls -la error
ls -la artifacts
ls -la logs
```

Po sukcesie plik powinien trafić do `processed`, a po błędzie do `error`, jeżeli konfiguracja przewiduje przenoszenie plików.

---

# Automatyczne uruchamianie

## 18. Utworzenie usługi systemd

Utwórz plik:

```bash
sudo nano /etc/systemd/system/rcn-importer.service
```

Zawartość:

```ini
[Unit]
Description=GUGiK RCN Importer
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=rcn-importer
Group=rcn-importer
WorkingDirectory=/opt/gugik/rcn-importer
ExecStart=/opt/gugik/rcn-importer/rcn-importer-1.0

NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Przeładuj konfigurację:

```bash
sudo systemctl daemon-reload
```

---

## 19. Test usługi systemd

Uruchom ręcznie:

```bash
sudo systemctl start rcn-importer.service
```

Sprawdź status:

```bash
sudo systemctl status rcn-importer.service
```

Ostatnie logi:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

---

## 20. Utworzenie timera — raz dziennie

Utwórz:

```bash
sudo nano /etc/systemd/system/rcn-importer.timer
```

Przykład uruchomienia codziennie o 02:00:

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

Włącz timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now rcn-importer.timer
```

Sprawdź:

```bash
systemctl list-timers --all | grep rcn
```

---

## 21. Inne przykłady harmonogramu

### Co godzinę

```ini
[Timer]
OnCalendar=hourly
Persistent=true
Unit=rcn-importer.service
```

### Co około 15 minut

```ini
[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
Persistent=true
Unit=rcn-importer.service
```

### Kilka razy dziennie

```ini
[Timer]
OnCalendar=*-*-* 06:00:00
OnCalendar=*-*-* 12:00:00
OnCalendar=*-*-* 18:00:00
Persistent=true
Unit=rcn-importer.service
```

Po zmianie timera:

```bash
sudo systemctl daemon-reload
sudo systemctl restart rcn-importer.timer
```

---

## 22. Sprawdzenie timera

Status:

```bash
sudo systemctl status rcn-importer.timer
```

Lista timerów:

```bash
systemctl list-timers --all | grep rcn
```

Pełna konfiguracja:

```bash
systemctl cat rcn-importer.timer
```

---

## 23. Ręczne uruchomienie mimo aktywnego timera

Nie trzeba wyłączać timera:

```bash
sudo systemctl start rcn-importer.service
```

Sprawdzenie:

```bash
sudo systemctl status rcn-importer.service
```

---

## 24. Wyłączenie i ponowne włączenie timera

Wyłączenie:

```bash
sudo systemctl disable --now rcn-importer.timer
```

Ponowne włączenie:

```bash
sudo systemctl enable --now rcn-importer.timer
```

---

# Alternatywa — cron

## 25. Uruchamianie przez cron

Jeżeli administrator nie chce używać `systemd timer`, aplikację można uruchamiać przez `cron`.

Edycja crontaba użytkownika aplikacji:

```bash
sudo crontab -u rcn-importer -e
```

Codziennie o 02:00:

```cron
0 2 * * * cd /opt/gugik/rcn-importer && ./rcn-importer-1.0
```

Co godzinę:

```cron
0 * * * * cd /opt/gugik/rcn-importer && ./rcn-importer-1.0
```

Co 15 minut:

```cron
*/15 * * * * cd /opt/gugik/rcn-importer && ./rcn-importer-1.0
```

Zalecany jest jednak `systemd timer`, ponieważ zapewnia wygodniejsze sprawdzanie statusu, logowanie przez `journalctl` i zarządzanie harmonogramem.

Nie należy jednocześnie konfigurować tego samego importera w `cron` i `systemd timer`.

---

# Aktualizacja aplikacji

## 26. Przygotowanie nowej wersji

Nową publikację `linux-x64` należy przesłać przez WinSCP do katalogu użytkownika, np.:

```text
/home/sszczerba/RCN/rcn-importer
```

Nie należy aktualizować plików bezpośrednio w `/opt` przez WinSCP.

---

## 27. Aktualizacja plików aplikacji

Zatrzymaj timer:

```bash
sudo systemctl stop rcn-importer.timer
```

Sprawdź, czy aplikacja aktualnie nie działa:

```bash
sudo systemctl status rcn-importer.service
```

Wykonaj kopię konfiguracji:

```bash
sudo cp /opt/gugik/rcn-importer/appsettings.json \
  /opt/gugik/rcn-importer/appsettings.json.bak
```

Skopiuj nową publikację:

```bash
sudo cp -a ~/RCN/rcn-importer/. /opt/gugik/rcn-importer/
```

Jeżeli nowa publikacja zawiera własny `appsettings.json`, przywróć konfigurację produkcyjną:

```bash
sudo cp /opt/gugik/rcn-importer/appsettings.json.bak \
  /opt/gugik/rcn-importer/appsettings.json
```

Ustaw właściciela:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Ustaw prawa:

```bash
sudo chmod -R u=rwX,g=rX,o= /opt/gugik/rcn-importer
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
sudo chmod 660 /opt/gugik/rcn-importer/appsettings.json
```

Przetestuj aplikację:

```bash
cd /opt/gugik/rcn-importer
sudo -u rcn-importer ./rcn-importer-1.0
```

Jeżeli test jest poprawny:

```bash
sudo systemctl daemon-reload
sudo systemctl start rcn-importer.timer
```

---

## 28. Zmiana konfiguracji

Po zmianie `appsettings.json` nie trzeba restartować stale działającego procesu, ponieważ aplikacja nie działa jako daemon.

Nowa konfiguracja zostanie odczytana przy następnym uruchomieniu.

Jeżeli chcesz uruchomić aplikację od razu:

```bash
sudo systemctl start rcn-importer.service
```

---

# Administracja i diagnostyka

## 29. Logi aplikacji

Logi aplikacji:

```bash
ls -lht /opt/gugik/rcn-importer/logs
```

Logi systemd:

```bash
sudo journalctl -u rcn-importer.service
```

Ostatnie 100 wpisów:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Log na żywo:

```bash
sudo journalctl -fu rcn-importer.service
```

---

## 30. Kontrola katalogu błędów

```bash
ls -lht /opt/gugik/rcn-importer/error
```

W przypadku błędów należy sprawdzić również:

```text
logs/
artifacts/
```

Pliku z katalogu `error` nie należy bez analizy ponownie kopiować do `input`.

---

## 31. Kontrola miejsca na dysku

```bash
df -h
```

Rozmiar całej aplikacji:

```bash
du -sh /opt/gugik/rcn-importer
```

Rozmiary katalogów:

```bash
du -sh /opt/gugik/rcn-importer/input
du -sh /opt/gugik/rcn-importer/processed
du -sh /opt/gugik/rcn-importer/error
du -sh /opt/gugik/rcn-importer/artifacts
du -sh /opt/gugik/rcn-importer/logs
```

---

## 32. Sprawdzenie procesu

```bash
ps aux | grep rcn-importer-1.0
```

Ponieważ aplikacja wykonuje jeden cykl i kończy pracę, po poprawnym zakończeniu procesu nie powinno być na liście.

---

## 33. Kopia bezpieczeństwa

Katalogi `processed`, `error`, `artifacts` i `logs` są katalogami technicznymi i mogą być objęte retencją.

Jeżeli organizacja wymaga dłuższego przechowywania historii, należy skonfigurować osobny mechanizm kopii bezpieczeństwa poza katalogiem aplikacji.

Najważniejsza jest niezależna polityka kopii bezpieczeństwa bazy PostgreSQL. Retencja plików aplikacji nie zastępuje backupu bazy.

---

## 34. Bezpieczeństwo

Administrator powinien:

- uruchamiać aplikację z dedykowanego użytkownika `rcn-importer`,
- nie uruchamiać aplikacji jako `root`,
- ograniczyć dostęp do `appsettings.json` do użytkownika `rcn-importer` i członków grupy `rcn-importer`,
- stosować dedykowanego użytkownika PostgreSQL z wymaganymi, ale nie nadmiarowymi uprawnieniami,
- ograniczyć dostęp sieciowy do PostgreSQL,
- nie publikować rzeczywistych haseł w repozytorium,
- regularnie instalować aktualizacje bezpieczeństwa systemu,
- kontrolować katalog `error`,
- kontrolować wolne miejsce,
- wykonywać backup bazy danych,
- sprawdzać logi po zmianach konfiguracji lub aktualizacji aplikacji.

---

# Najczęstsze problemy

## 35. `Permission denied` przy kopiowaniu przez WinSCP

Nie należy wgrywać plików bezpośrednio do:

```text
/opt/gugik/rcn-importer
```

WinSCP powinien przesyłać pliki do katalogu użytkownika, np.:

```text
/home/sszczerba/RCN/rcn-importer
```

Następnie należy użyć:

```bash
sudo cp -a ~/RCN/rcn-importer/. /opt/gugik/rcn-importer/
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

---

## 36. `Permission denied` przy wejściu do `/opt/gugik/rcn-importer`

Jeżeli:

```bash
ls -la /opt/gugik/rcn-importer
```

zwraca `Permission denied`, sprawdź:

```bash
groups
groups sszczerba
```

Jeżeli `groups sszczerba` pokazuje `rcn-importer`, ale polecenie `groups` dla bieżącej sesji jej nie pokazuje, wyloguj się:

```bash
exit
```

i zaloguj ponownie przez SSH. Nowe członkostwo w grupie zaczyna obowiązywać w nowej sesji.

Po ponownym zalogowaniu:

```bash
groups
ls -la /opt/gugik/rcn-importer
```

---

## 37. `Permission denied` przy uruchamianiu aplikacji

Sprawdź:

```bash
ls -la /opt/gugik/rcn-importer
```

Następnie:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
```

---

## 38. Brak połączenia z PostgreSQL

Sprawdź konfigurację `ConnectionStrings`.

Jeżeli baza jest lokalna:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn
```

Jeżeli baza jest zdalna:

```bash
nc -vz HOST 5432
```

Po stronie PostgreSQL sprawdź:

- `listen_addresses`,
- `pg_hba.conf`,
- reguły zapory,
- port PostgreSQL,
- użytkownika i hasło,
- uprawnienia użytkownika do bazy `rcn`.

---

## 39. PostgreSQL nasłuchuje tylko lokalnie

Sprawdź:

```bash
sudo ss -ltnp | grep 5432
```

Jeżeli widoczne jest wyłącznie:

```text
127.0.0.1:5432
[::1]:5432
```

to PostgreSQL przyjmuje tylko połączenia lokalne.

Konfiguracja znajduje się typowo w:

```text
/etc/postgresql/18/main/postgresql.conf
/etc/postgresql/18/main/pg_hba.conf
```

Po zmianach wymagających restartu:

```bash
sudo pg_ctlcluster 18 main restart
```

---

## 40. Plik pozostaje w `input`

Sprawdź w `appsettings.json`:

```json
"MoveFilesAfterImport": true
```

Następnie sprawdź log aplikacji.

---

## 41. Plik trafił do `error`

Sprawdź:

```text
logs/
artifacts/
```

Artefakty i logi zawierają informacje diagnostyczne dotyczące konkretnego importu.

---

## 42. Timer nie uruchamia aplikacji

Sprawdź:

```bash
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Po zmianie pliku `.service` albo `.timer`:

```bash
sudo systemctl daemon-reload
sudo systemctl restart rcn-importer.timer
```

---

# Przydatne polecenia administratora

## 43. Skrócona lista

```bash
# przejście do aplikacji
cd /opt/gugik/rcn-importer

# ręczne uruchomienie aplikacji
sudo -u rcn-importer ./rcn-importer-1.0

# uruchomienie przez systemd
sudo systemctl start rcn-importer.service

# status ostatniego uruchomienia
sudo systemctl status rcn-importer.service

# status timera
sudo systemctl status rcn-importer.timer

# lista timerów
systemctl list-timers --all | grep rcn

# ostatnie logi
sudo journalctl -u rcn-importer.service -n 100 --no-pager

# log na żywo
sudo journalctl -fu rcn-importer.service

# zatrzymanie timera
sudo systemctl stop rcn-importer.timer

# wyłączenie timera
sudo systemctl disable --now rcn-importer.timer

# włączenie timera
sudo systemctl enable --now rcn-importer.timer

# przeładowanie konfiguracji systemd
sudo systemctl daemon-reload

# sprawdzenie miejsca na dysku
df -h

# rozmiar aplikacji
du -sh /opt/gugik/rcn-importer
```

---

# Zalecany proces wdrożenia

## 44. Kolejność krok po kroku

1. Przygotuj PostgreSQL/PostGIS oraz bazę `rcn`.
2. Przygotuj publikację `linux-x64` jako `self-contained`.
3. **Utwórz użytkownika systemowego `rcn-importer` i dodaj administratora do grupy `rcn-importer`.**
4. **Sprawdź `groups sszczerba`, wyloguj się przez `exit`, zaloguj ponownie przez SSH i sprawdź `groups`. Nie kontynuuj, dopóki aktywna sesja nie pokazuje grupy `rcn-importer`.**
6. **Utwórz katalog docelowy `/opt/gugik/rcn-importer`.**
6. Utwórz katalog `~/RCN/rcn-importer` dla plików przesyłanych przez WinSCP.
7. Wgraj przez WinSCP całą publikację do `~/RCN/rcn-importer`.
8. Sprawdź przesłane pliki.
9. Skopiuj publikację do `/opt/gugik/rcn-importer` za pomocą `sudo cp -a`.
10. Utwórz katalogi `input`, `processed`, `error`, `artifacts`, `logs`.
11. Ustaw właściciela `rcn-importer:rcn-importer`.
12. Nadaj odpowiednie uprawnienia.
13. Skonfiguruj `appsettings.json`.
14. Sprawdź `TerytPow`, tryb importu i retencję.
15. Sprawdź połączenie z PostgreSQL.
16. Uruchom aplikację ręcznie jako `rcn-importer`.
17. Wykonaj test z plikiem GML lub ZIP.
18. Sprawdź `processed`, `error`, `artifacts` i `logs`.
19. Utwórz `rcn-importer.service`.
20. Przetestuj usługę.
21. Utwórz `rcn-importer.timer`.
22. Włącz timer.
23. Sprawdź następny termin uruchomienia.
24. Po pierwszym automatycznym wykonaniu sprawdź logi i wynik importu.

Po wykonaniu powyższych kroków aplikacja może pracować cyklicznie bez ręcznego uruchamiania.
