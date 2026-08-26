# RCN Importer — instrukcja instalacji aplikacji na Linux Debian

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

Całą instrukcję wykonuj z konta administratora posiadającego uprawnienia `sudo`. Nie loguj się na konto `rcn-importer`; jest to konto systemowe przeznaczone wyłącznie do uruchamiania aplikacji.

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

Jeżeli chcesz jedynie pobrać najnowszą wersję plików użyj:

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

Użyj polecenia do sprawdzenia czy istnieje użytkownik `rcn-importer`:

```bash
id rcn-importer
```

Jeżeli użytkownik nie istnieje uruchom:

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

Użyj polecenia do utworzenia katalogu docelowego:

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

Skopiuj **całą zawartość** katalogu `publish/linux-x64` do katalogu produkcyjnego za pomocą polecenia:

```bash
sudo cp -a ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/publish/linux-x64/. /opt/gugik/rcn-importer/
```

Sprawdź skopiowane pliki:

```bash
sudo ls -la /opt/gugik/rcn-importer
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

---

## 6. Przygotowanie katalogów i uprawnień aplikacji

Utwórz katalogi robocze aplikacji:

```bash
sudo mkdir -p /opt/gugik/rcn-importer/{input,processed,error,artifacts,logs}
```

Następnie ustaw użytkownika `rcn-importer` jako właściciela całej instalacji:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
```

Nadaj wymagane uprawnienia do katalogów i plików:

```bash
sudo chmod -R u=rwX,g=rX,o= /opt/gugik/rcn-importer
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

Sprawdź właściciela i nadane uprawnienia:

```bash
sudo ls -ld /opt/gugik/rcn-importer
sudo ls -la /opt/gugik/rcn-importer
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

> **Ważne**
>
> Po nadaniu powyższych uprawnień zwykły użytkownik administracyjny może nie mieć bezpośredniego dostępu do katalogu `/opt/gugik/rcn-importer`. Jest to prawidłowe.
>
> Właścicielem instalacji jest użytkownik systemowy `rcn-importer`.
>
> Do przeglądania i modyfikowania plików aplikacji należy używać `sudo`, natomiast samą aplikację należy uruchamiać jako użytkownik `rcn-importer`.

---


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
    "Localhost": "Host=localhost;Port=5432;Database=rcn;Username=postgres;Password=TWOJE_HASLO"
  },
  "ImportJob": {
    "TerytPow": "1864", // Po testach wprowadź TERYT Twojego powiatu
    "InputPath": "input",
    "ProcessedPath": "processed",
    "ErrorPath": "error",
    "ArtifactsDir": "artifacts",
    "LogDirectory": "logs",
    "Mode": "UPSERT", // Dostępne: REPLACE, UPSERT lub INSERT
    "MoveFilesAfterImport": true,
    "RetentionDays": 7
  }
}
```

Uzupełnij przede wszystkim hasło, `TerytPow` i świadomie wybierz `Mode`. Nie zapisuj rzeczywistych haseł w repozytorium Git.

Po wprowadzeniu zmian zapisz plik:

```text
Ctrl+O
Enter
Ctrl+X
```

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

Aplikację należy uruchamiać jako dedykowany użytkownik systemowy `rcn-importer`.

Uruchom aplikację:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.0'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Po zakończeniu działania aplikacji zostanie wyświetlony zwrócony kod, np.:

```text
Kod zakończenia RCN Importer: 5
```

Przy pustym katalogu `input` kod `5` oznacza brak plików wejściowych, a nie awarię bazy.

> **Ważne**
>
> Kod zakończenia należy odczytać bezpośrednio po uruchomieniu aplikacji. Zmienna `$?` zawiera kod zakończenia ostatnio wykonanego polecenia, dlatego jest od razu zapisywana do zmiennej `EXIT_CODE`.

Nie należy wcześniej wykonywać polecenia:

```bash
cd /opt/gugik/rcn-importer
```

Zwykły użytkownik administracyjny może nie mieć prawa wejścia do katalogu aplikacji. Przejście do katalogu roboczego oraz uruchomienie aplikacji wykonywane są dlatego bezpośrednio jako użytkownik `rcn-importer`.

W przypadku problemów z uruchomieniem sprawdź właściciela i uprawnienia:

```bash
sudo ls -ld /opt/gugik/rcn-importer
sudo ls -l /opt/gugik/rcn-importer/rcn-importer-1.0
sudo ls -l /opt/gugik/rcn-importer/appsettings.json
```

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
"TerytPow": "1864", // Po testach wprowadź TERYT Twojego powiatu
```

### 10.1. Test importu bazowego

Skopiuj plik bazowy do katalogu `input`:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-1-bazowy.zip /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/1864-1-bazowy.zip
```

Sprawdź, czy plik znajduje się w katalogu `input`:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
```

Uruchom aplikację jako użytkownik `rcn-importer` i wyświetl zwrócony kod zakończenia:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.0'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Po zakończeniu działania aplikacji zostanie wyświetlony zwrócony kod, np.:

```text
Kod zakończenia RCN Importer: 0
```

Kod `0` oznacza poprawne zakończenie importu.

> **Ważne**
>
> Kod zakończenia należy odczytać bezpośrednio po uruchomieniu aplikacji. Zmienna `$?` zawiera kod zakończenia ostatnio wykonanego polecenia, dlatego jest od razu zapisywana do zmiennej `EXIT_CODE`.

Po zakończeniu sprawdź katalogi robocze:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
sudo ls -la /opt/gugik/rcn-importer/error
sudo ls -la /opt/gugik/rcn-importer/artifacts
sudo ls -la /opt/gugik/rcn-importer/logs
```

Po poprawnym imporcie plik `1864-1-bazowy.zip` powinien trafić do katalogu `processed`.

Jeżeli plik trafił do katalogu `error`, sprawdź logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

### 10.2. Sprawdzenie danych w bazie

Do repozytorium dołączony jest plik `count.sql`, który pozwala szybko sprawdzić liczbę załadowanych obiektów.

Plik znajduje się w repozytorium:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

Wykonaj:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn < ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

W tym przypadku plik `count.sql` jest odczytywany przez aktualnie zalogowanego użytkownika, natomiast polecenia SQL są wykonywane w bazie `rcn` przez użytkownika PostgreSQL `postgres`.

Po poprawnym wykonaniu powinny zostać wyświetlone liczby obiektów zapisanych w bazie.

> **Ważne**
>
> Nie używaj w tym przypadku parametru `-f` ze ścieżką do pliku znajdującego się w `~/RCN`.
>
> Polecenie `psql` jest uruchamiane jako użytkownik systemowy `postgres`, który może nie mieć dostępu do katalogu domowego administratora. Przekierowanie `<` powoduje, że plik `count.sql` odczytuje aktualnie zalogowany użytkownik, a jego zawartość jest przekazywana do `psql`.

### 10.3. Test importu przyrostowego

Po poprawnym imporcie pliku bazowego możesz przetestować import przyrostowy.

Skopiuj plik przyrostowy do katalogu `input`:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-2-przyrostowy.zip /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/1864-2-przyrostowy.zip
```

Sprawdź, czy plik znajduje się w katalogu `input`:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
```

Przed uruchomieniem upewnij się, że wybrany w `appsettings.json` tryb `Mode` odpowiada sposobowi, w jaki chcesz wykonać test.

Uruchom importer jako użytkownik `rcn-importer` i wyświetl zwrócony kod zakończenia:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.0'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Po zakończeniu działania aplikacji zostanie wyświetlony zwrócony kod, np.:

```text
Kod zakończenia RCN Importer: 0
```

Kod `0` oznacza poprawne zakończenie importu.

> **Ważne**
>
> Kod zakończenia należy odczytać bezpośrednio po uruchomieniu aplikacji. Zmienna `$?` zawiera kod zakończenia ostatnio wykonanego polecenia, dlatego jest od razu zapisywana do zmiennej `EXIT_CODE`.

Po zakończeniu sprawdź katalogi robocze:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
sudo ls -la /opt/gugik/rcn-importer/error
sudo ls -la /opt/gugik/rcn-importer/artifacts
sudo ls -la /opt/gugik/rcn-importer/logs
```

Po poprawnym imporcie plik `1864-2-przyrostowy.zip` powinien trafić do katalogu `processed`.

Jeżeli plik trafił do katalogu `error`, sprawdź logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

Następnie ponownie sprawdź liczbę danych w bazie:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn < ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

> **Ważne**
>
> Pliki `1864-1-bazowy.zip` i `1864-2-przyrostowy.zip` są plikami testowymi dołączonymi do repozytorium. W środowisku docelowym do katalogu `input` należy przekazywać właściwe pliki GML/ZIP zawierające dane RCN danego powiatu.

## 11. Automatyczne uruchamianie — systemd timer

Najpierw wykonaj co najmniej jeden poprawny import ręczny. Dopiero potem konfiguruj automatyczne uruchamianie aplikacji.

Utwórz usługę:

```bash
sudo nano /etc/systemd/system/rcn-importer.service
```

Wprowadź konfigurację:

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
SuccessExitStatus=5
NoNewPrivileges=true
PrivateTmp=true
```

> **Ważne**
>
> Aplikacja zwraca kod `5`, jeżeli w katalogu `input` nie ma plików do przetworzenia. Dla automatycznego uruchamiania jest to normalna sytuacja, dlatego `SuccessExitStatus=5` powoduje, że systemd nie traktuje braku plików wejściowych jako awarii usługi.
>
> Standardowy kod `0` nadal jest traktowany przez systemd jako poprawne zakończenie.

Przeładuj konfigurację systemd:

```bash
sudo systemctl daemon-reload
```

Uruchom usługę ręcznie w celu sprawdzenia konfiguracji:

```bash
sudo systemctl start rcn-importer.service
sudo systemctl status rcn-importer.service
```

Jeżeli `systemctl status` otworzy widok pełnoekranowy, naciśnij `q`, aby wrócić do terminala.

Sprawdź również logi usługi:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Usługa ma typ `oneshot`, dlatego po zakończeniu działania aplikacji nie musi pozostawać stale aktywna. Najważniejsze jest, aby wykonanie zakończyło się bez błędu.

Utwórz timer, np. uruchamiający importer codziennie o godzinie 02:00:

```bash
sudo nano /etc/systemd/system/rcn-importer.timer
```

Wprowadź:

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

Przeładuj konfigurację i włącz timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now rcn-importer.timer
```

Sprawdź jego stan:

```bash
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn-importer
```

Opcja `Persistent=true` powoduje, że jeżeli zaplanowane uruchomienie nie odbyło się np. z powodu wyłączenia serwera, systemd uruchomi zadanie po ponownym uruchomieniu systemu.

Nie konfiguruj jednocześnie `cron` i `systemd timer` dla tej samej instalacji. Zalecany jest `systemd timer`.

---

## 12. Aktualizacja aplikacji z repozytorium

Przed aktualizacją aplikacji pobierz najnowszą wersję repozytorium:

```bash
cd ~/RCN
git pull --ff-only
```

Zatrzymaj timer na czas aktualizacji:

```bash
sudo systemctl stop rcn-importer.timer
```

Wykonaj kopię aktualnej konfiguracji aplikacji:

```bash
sudo cp /opt/gugik/rcn-importer/appsettings.json /tmp/rcn-importer-appsettings.json.bak
```

Skopiuj aktualną publikację aplikacji z repozytorium:

```bash
sudo cp -a ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/publish/linux-x64/. /opt/gugik/rcn-importer/
```

Przywróć produkcyjną konfigurację `appsettings.json`:

```bash
sudo cp /tmp/rcn-importer-appsettings.json.bak /opt/gugik/rcn-importer/appsettings.json
```

Ponownie ustaw właściciela i wymagane uprawnienia:

```bash
sudo chown -R rcn-importer:rcn-importer /opt/gugik/rcn-importer
sudo chmod -R u=rwX,g=rX,o= /opt/gugik/rcn-importer
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.0
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

Sprawdź skopiowane pliki:

```bash
sudo ls -la /opt/gugik/rcn-importer
```

Wykonaj ręczny test aplikacji:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.0'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Jeżeli katalog `input` jest pusty, kod `5` oznacza brak plików wejściowych i nie oznacza awarii aplikacji.

Po poprawnym teście ponownie uruchom timer:

```bash
sudo systemctl start rcn-importer.timer
```

Sprawdź:

```bash
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn-importer
```

Po zakończeniu aktualizacji i sprawdzeniu poprawności konfiguracji możesz usunąć tymczasową kopię:

```bash
sudo rm -f /tmp/rcn-importer-appsettings.json.bak
```

> **Ważne**
>
> Nie nadpisuj bez kontroli produkcyjnego pliku `appsettings.json`. Może on zawierać właściwy dla danego serwera kod `TerytPow`, tryb importu oraz dane połączenia z bazą.

---

## 13. Diagnostyka

Logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

Aby wyświetlić zawartość konkretnego pliku logu, użyj np.:

```bash
sudo less /opt/gugik/rcn-importer/logs/NAZWA_PLIKU_LOGU
```

Logi usługi systemd:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Aby obserwować logi usługi systemd na bieżąco:

```bash
sudo journalctl -u rcn-importer.service -f
```

Sprawdzenie właściciela i uprawnień katalogu aplikacji:

```bash
sudo ls -ld /opt/gugik/rcn-importer
sudo ls -la /opt/gugik/rcn-importer
```

Sprawdzenie pliku wykonywalnego i konfiguracji:

```bash
sudo ls -l /opt/gugik/rcn-importer/rcn-importer-1.0
sudo ls -l /opt/gugik/rcn-importer/appsettings.json
```

Sprawdzenie katalogów roboczych:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
sudo ls -la /opt/gugik/rcn-importer/processed
sudo ls -la /opt/gugik/rcn-importer/error
sudo ls -la /opt/gugik/rcn-importer/artifacts
sudo ls -la /opt/gugik/rcn-importer/logs
```

Sprawdzenie miejsca na dysku i rozmiaru instalacji:

```bash
df -h
sudo du -sh /opt/gugik/rcn-importer
```

Jeżeli skonfigurowano automatyczne uruchamianie, sprawdź stan usługi i timera:

```bash
sudo systemctl status rcn-importer.service
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn-importer
```

W przypadku ręcznego testu aplikację uruchamiaj jako użytkownik `rcn-importer` i sprawdź zwrócony kod zakończenia:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.0'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Przy pustym katalogu `input` kod `5` oznacza brak plików wejściowych, a nie awarię aplikacji.

> **Uwaga**
>
> Brak możliwości wykonania przez zwykłego użytkownika polecenia `cd /opt/gugik/rcn-importer` nie oznacza błędu instalacji. Dostęp do katalogu został celowo ograniczony. Operacje administracyjne wykonuj przez `sudo`, a aplikację uruchamiaj jako użytkownik `rcn-importer`.

---

## 14. Cofnięcie zmian — usunięcie instalacji RCN Importer

Jeżeli chcesz wycofać zmiany wykonane w ramach Etapu 2 i ponownie przeprowadzić instalację aplikacji od początku, możesz usunąć instalację RCN Importer.

Operacja usuwa wyłącznie elementy związane z Etapem 2. **Nie usuwa repozytorium `~/RCN`, PostgreSQL, PostGIS ani bazy danych `rcn`.**

### 14.1. Automatyczne cofnięcie zmian

Zalecanym sposobem jest użycie skryptu `reset_instalacji_rcn_importer.sh`, znajdującego się w repozytorium.

Przejdź do katalogu Etapu 2:

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```

Uruchom skrypt:

```bash
sudo ./reset_instalacji_rcn_importer.sh
```

Skrypt powinien usunąć:

- katalog instalacyjny `/opt/gugik/rcn-importer`;
- użytkownika systemowego `rcn-importer`;
- usługę `rcn-importer.service`, jeżeli została utworzona;
- timer `rcn-importer.timer`, jeżeli został utworzony.

Repozytorium:

```text
~/RCN
```

pozostaje bez zmian i może zostać wykorzystane do ponownej instalacji.

### 14.2. Ręczne cofnięcie zmian

Jeżeli z jakiegoś powodu nie chcesz używać skryptu resetującego, zmiany można wycofać ręcznie.

Zatrzymaj i wyłącz timer, jeżeli został skonfigurowany:

```bash
sudo systemctl disable --now rcn-importer.timer 2>/dev/null || true
```

Zatrzymaj usługę, jeżeli istnieje:

```bash
sudo systemctl stop rcn-importer.service 2>/dev/null || true
```

Usuń jednostki systemd:

```bash
sudo rm -f /etc/systemd/system/rcn-importer.service
sudo rm -f /etc/systemd/system/rcn-importer.timer
sudo systemctl daemon-reload
sudo systemctl reset-failed
```

Usuń cały katalog instalacyjny aplikacji:

```bash
sudo rm -rf /opt/gugik/rcn-importer
```

Usuń użytkownika systemowego:

```bash
sudo userdel rcn-importer 2>/dev/null || true
```

### 14.3. Weryfikacja cofnięcia zmian

Sprawdź, czy katalog aplikacji został usunięty:

```bash
sudo test ! -e /opt/gugik/rcn-importer && echo "OK - katalog aplikacji został usunięty"
```

Sprawdź, czy użytkownik `rcn-importer` został usunięty:

```bash
id rcn-importer
```

Jeżeli użytkownik został poprawnie usunięty, polecenie powinno zwrócić informację, że taki użytkownik nie istnieje.

Sprawdź jednostki systemd:

```bash
systemctl list-unit-files | grep rcn-importer
```

Jeżeli cofnięcie zmian zostało wykonane poprawnie, jednostki `rcn-importer.service` i `rcn-importer.timer` nie powinny być widoczne.

Sprawdź, czy repozytorium nadal istnieje:

```bash
ls -la ~/RCN
```

> **Ważne**
>
> Nie usuwaj katalogu `~/RCN`. Repozytorium jest wspólne dla wszystkich etapów wdrożenia i powinno pozostać na serwerze.
>
> Cofnięcie Etapu 2 nie usuwa PostgreSQL, PostGIS, bazy `rcn`, schematu `uslugi_rcn` ani konfiguracji wykonanej w Etapie 1.

Po wykonaniu resetu instalację aplikacji można rozpocząć ponownie od **punktu 2 — Przejście do Etapu 2 w repozytorium**.

---

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
- jeżeli skonfigurowano automatykę — `rcn-importer.timer` jest aktywny i widoczny na liście zaplanowanych timerów.

Stan timera można sprawdzić poleceniami:

```bash
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn-importer
```

Po pozytywnej weryfikacji można przejść do **Etapu 3 — konfiguracji usługi publikacyjnej MapServer**.
