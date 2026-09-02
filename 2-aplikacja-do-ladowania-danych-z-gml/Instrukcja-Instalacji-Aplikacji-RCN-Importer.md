# Etap 2
# RCN Importer — instrukcja instalacji aplikacji na Linux Debian

## Informacje o aplikacji

**Nazwa:** RCN Importer  
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)  
**Autor:** Szymon Szczerba  
**Rok:** 2026  
**Technologia:** .NET 9  
**Typ aplikacji:** aplikacja konsolowa  
**Wersja:** 1.1  
**Plik wykonywalny:** `rcn-importer-1.1`  
**Publikacja:** self-contained `linux-x64`

Na serwerze nie trzeba instalować .NET. Aplikacja uruchamia się na czas importu danych, wykonuje jeden cykl importu, a po jego zakończeniu automatycznie się wyłącza. Nie działa stale w tle na serwerze.

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
│       ├── rcn-importer-1.1
│       ├── appsettings.json
│       └── pozostałe pliki publikacji
├── Instrukcja-Instalacji-Aplikacji-RCN-Importer.md
├── O-Aplikacji-RCN-Importer.md
├── reset_instalacji_rcn_importer.md
└── reset_instalacji_rcn_importer.sh
```

Znaczenie najważniejszych elementów:

- `publish/linux-x64` — kompletna publikacja aplikacji przeznaczona do skopiowania do `/opt/gugik/rcn-importer`;
- `gml/1864-1-bazowy.zip` — testowy plik bazowy;
- `gml/1864-2-przyrostowy.zip` — testowy plik przyrostowy;
- `gml/count.sql` — pomocnicze zapytania do weryfikacji liczby danych po imporcie;
- `O-Aplikacji-RCN-Importer.md` — opis działania i konfiguracji aplikacji;
- `reset_instalacji_rcn_importer.*` — materiały administracyjne do usunięcia instalacji aplikacji; nie są częścią standardowej pierwszej instalacji.

> Etap 2 korzysta z plików znajdujących się już w `~/RCN`.

Jeżeli chcesz jedynie pobrać najnowszą wersję plików użyj:

```bash
cd ~/RCN
git pull --ff-only
```

Po aktualizacji wróć do:

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

<pre>
/opt/gugik/rcn-importer
</pre>

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

<pre>
rcn-importer-1.1
appsettings.json
pozostałe pliki i biblioteki publikacji
</pre>

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
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.1
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

Sprawdź właściciela i nadane uprawnienia:

```bash
sudo ls -ld /opt/gugik/rcn-importer
sudo ls -la /opt/gugik/rcn-importer
```

Docelowo:

<pre>
/opt/gugik/rcn-importer/
├── rcn-importer-1.1
├── appsettings.json
├── input/
├── processed/
├── error/
├── artifacts/
└── logs/
</pre>

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

<pre>
{
  "Database": {
    "ConnectionName": "Localhost",
    "Schema": "uslugi_rcn"
  },
  "ConnectionStrings": {
    "Localhost": "Host=localhost;Port=5432;Database=rcn;Username=postgres;Password=TWOJE_HASLO"
  },
  "ImportJob": {
    "TerytPow": "1864",
    "InputPath": "input",
    "ProcessedPath": "processed",
    "ErrorPath": "error",
    "ArtifactsDir": "artifacts",
    "LogDirectory": "logs",
    "Mode": "UPSERT",
    "MoveFilesAfterImport": true,
    "RetentionDays": 7
  }
}
</pre>

### 7.1. Ustawienie hasła do bazy danych

W parametrze:

<pre>
Password=TWOJE_HASLO
</pre>

zastąp `TWOJE_HASLO` **hasłem użytkownika PostgreSQL `postgres`, które zostało ustawione w Etapie 1 podczas konfiguracji bazy danych RCN**.

Przykład:

<pre>
Host=localhost;Port=5432;Database=rcn;Username=postgres;Password=USTAWIONE_W_ETAPIE_1_HASLO
</pre>

> **Ważne:** Nie zapisuj rzeczywistych haseł w repozytorium Git ani w dokumentacji.

### 7.2. Ustawienie `TerytPow`

Parametr:

<pre>
"TerytPow": "1864"
</pre>

określa kod TERYT powiatu, którego dane będą importowane.

Wybierz jeden z dwóch wariantów:

- **jeżeli chcesz wykonać pierwszy import z wykorzystaniem przygotowanych danych testowych** — pozostaw wartość `"1864"`;
- **jeżeli nie chcesz korzystać z danych testowych i od razu chcesz sprawdzić import danych ze swojego powiatu** — zastąp `"1864"` właściwym kodem TERYT swojego powiatu.

> **Ważne:** Wartość `TerytPow` musi odpowiadać powiatowi, którego dane będą importowane.

### 7.3. Ustawienie trybu importu

Parametr:

<pre>
"Mode": "UPSERT"
</pre>

określa sposób zapisu danych do bazy.

Dostępne tryby:

- `REPLACE` — usuwa dotychczasowe dane powiatu z bazy i zastępuje je kompletnym zestawem danych z aktualnego importu;
- `UPSERT` — aktualizuje istniejące rekordy i dodaje nowe;
- `INSERT` — dodaje nowe dane zgodnie z logiką aplikacji.

#### Import danych testowych

Jeżeli wykonujesz pierwszy import z wykorzystaniem przygotowanych danych testowych dla powiatu `1864`, pozostaw:

<pre>
"Mode": "UPSERT"
</pre>

Tryb `UPSERT` jest zalecany dla testu bazowego i późniejszego importu pliku przyrostowego.

#### Import danych własnego powiatu

Jeżeli od razu importujesz dane własnego powiatu, wybierz tryb odpowiedni do sposobu przygotowania danych.

**Najbezpieczniejszym wyborem jest `UPSERT`**, ponieważ istniejące rekordy są aktualizowane, a nowe są dodawane bez wcześniejszego usuwania całego zestawu danych powiatu. 
Jeśli importowana transakcja z pliku GML jest już w bazie danych zostanie pominięta.

<pre>
"Mode": "UPSERT"
</pre>

Tryb `REPLACE` może być szybszy, ponieważ przed zapisem usuwa dotychczasowe dane danego powiatu i zastępuje je kompletnym zestawem z aktualnego importu.

<pre>
"Mode": "REPLACE"
</pre>

> **Ważne:** Trybu `REPLACE` używaj tylko wtedy, gdy importowany plik zawiera kompletny zestaw danych powiatu i świadomie chcesz zastąpić dane znajdujące się już w bazie.

Jeżeli nie masz pewności, który tryb wybrać, użyj:

<pre>
"Mode": "UPSERT"
</pre>

Administrator powinien świadomie zdecydować o wyborze trybu przed pierwszym importem danych własnego powiatu.

Jeżeli w katalogu `input` znajduje się kilka plików, aplikacja analizuje je osobno, a poprawne dane scala do jednej kolekcji przed zapisem. W trybie `REPLACE` błąd części zestawu blokuje częściowe zastąpienie danych.

### 7.4. Zapisanie konfiguracji

Po wprowadzeniu zmian zapisz plik:

<pre>
Ctrl+O
Enter
Ctrl+X
</pre>

Po edycji ponownie ogranicz dostęp do pliku konfiguracyjnego:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/appsettings.json
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

## 8. Sprawdzenie dostępu do bazy

Dla lokalnej bazy:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn -c "SELECT current_database();"
```

Sprawdź również schemat:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn -c "\dt uslugi_rcn.*"
```

## 9. Pierwsze uruchomienie aplikacji bez danych

Aplikację należy uruchamiać jako dedykowany użytkownik systemowy `rcn-importer`.

Uruchom aplikację:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
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

## 10. Pierwszy import danych

Po skonfigurowaniu aplikacji wybierz jeden z dwóch wariantów pierwszego importu:

1. **Wariant A — import danych testowych** — jeżeli chcesz sprawdzić działanie aplikacji na plikach testowych dołączonych do repozytorium;
2. **Wariant B — import danych własnego powiatu** — jeżeli nie chcesz wykonywać testu i od razu chcesz zaimportować własne dane RCN.

> **Ważne:** Nie ma obowiązku wykonywania importu danych testowych. Jeżeli konfiguracja została przygotowana dla własnego powiatu, możesz od razu przejść do wariantu B.

### 10.1. Wariant A — import danych testowych

Ten wariant służy do sprawdzenia poprawności działania RCN Importer na przygotowanych danych testowych.

Pliki testowe dotyczą powiatu o kodzie TERYT:

<pre>
1864
</pre>

Przed rozpoczęciem upewnij się, że w `appsettings.json` ustawiono:

<pre>
"TerytPow": "1864"
"Mode": "UPSERT"
</pre>

Dla testu zalecany jest tryb `UPSERT`.

W repozytorium znajdują się dwa pliki testowe:

<pre>
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-1-bazowy.zip
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-2-przyrostowy.zip
</pre>

Test wykonaj w następującej kolejności:

1. import pliku bazowego `1864-1-bazowy.zip`;
2. sprawdzenie liczby zaimportowanych obiektów;
3. import pliku przyrostowego `1864-2-przyrostowy.zip`;
4. ponowne sprawdzenie liczby obiektów po imporcie przyrostowym.

#### 10.1.1. Import pliku bazowego

Skopiuj plik bazowy do katalogu `input`:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-1-bazowy.zip /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/1864-1-bazowy.zip
```

Sprawdź zawartość katalogu `input`:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
```

W katalogu powinien znajdować się plik:

<pre>
1864-1-bazowy.zip
</pre>

Uruchom aplikację:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Prawidłowy wynik:

<pre>
Kod zakończenia RCN Importer: 0
</pre>

Kod `0` oznacza poprawne zakończenie importu.

Po poprawnym imporcie plik:

<pre>
1864-1-bazowy.zip
</pre>

powinien zostać przeniesiony do katalogu:

<pre>
/opt/gugik/rcn-importer/processed
</pre>

Sprawdź:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
```

Jeżeli plik trafił do katalogu `error`, sprawdź logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

#### 10.1.2. Sprawdzenie danych po imporcie pliku bazowego

Do repozytorium dołączony jest pomocniczy plik `count.sql`:

<pre>
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
</pre>

Uruchom:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn < ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

Po poprawnym wykonaniu powinny zostać wyświetlone liczby obiektów zapisanych w bazie po imporcie pliku bazowego.

> **Uwaga:** Jeżeli wynik zostanie wyświetlony w trybie podglądu i nie nastąpi automatyczny powrót do wiersza poleceń, naciśnij `q`, aby zakończyć podgląd i wrócić do terminala.

#### 10.1.3. Import pliku przyrostowego

Skopiuj plik przyrostowy do katalogu `input`:

```bash
sudo cp ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/1864-2-przyrostowy.zip /opt/gugik/rcn-importer/input/
```

Nadaj właściciela:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/1864-2-przyrostowy.zip
```

Sprawdź zawartość katalogu `input`:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
```

W katalogu powinien znajdować się plik:

<pre>
1864-2-przyrostowy.zip
</pre>

Uruchom ponownie aplikację:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Prawidłowy wynik:

<pre>
Kod zakończenia RCN Importer: 0
</pre>

Kod `0` oznacza poprawne zakończenie importu.

Po poprawnym imporcie plik:

<pre>
1864-2-przyrostowy.zip
</pre>

powinien zostać przeniesiony do katalogu:

<pre>
/opt/gugik/rcn-importer/processed
</pre>

Sprawdź:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
```

#### 10.1.4. Sprawdzenie danych po imporcie pliku przyrostowego

Ponownie uruchom `count.sql`:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn < ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

Po poprawnym wykonaniu powinny zostać wyświetlone liczby obiektów zapisanych w bazie po imporcie pliku przyrostowego.

#### 10.1.5. Końcowa weryfikacja testu

Po wykonaniu importu bazowego i przyrostowego sprawdź katalogi robocze aplikacji:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
sudo ls -la /opt/gugik/rcn-importer/error
sudo ls -la /opt/gugik/rcn-importer/artifacts
sudo ls -la /opt/gugik/rcn-importer/logs
```

W katalogu `processed` powinny znajdować się oba poprawnie przetworzone pliki:

<pre>
1864-1-bazowy.zip
1864-2-przyrostowy.zip
</pre>

Katalog `error` powinien być pusty.

Jeżeli którykolwiek z plików trafił do katalogu `error`, sprawdź logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

Test można uznać za zakończony poprawnie, jeżeli:

- oba uruchomienia aplikacji zakończyły się kodem `0`;
- plik bazowy i przyrostowy zostały przeniesione do katalogu `processed`;
- żaden z plików nie trafił do katalogu `error`;
- po imporcie bazowym dane zostały zapisane w bazie;
- po imporcie przyrostowym liczba lub zawartość danych odpowiada wynikowi przetworzenia pliku przyrostowego;
- aplikacja utworzyła wymagane logi i artefakty.

### 10.2. Wariant B — import danych własnego powiatu

Jeżeli nie chcesz korzystać z przygotowanych danych testowych, możesz od razu wykonać pierwszy import danych własnego powiatu.

Przed rozpoczęciem upewnij się, że w `appsettings.json`:

- `TerytPow` zawiera właściwy kod TERYT Twojego powiatu;
- `Mode` został świadomie wybrany zgodnie z zasadami opisanymi w punkcie 7.3;
- ustawione jest poprawne połączenie z bazą danych.

Przykładowa wartość parametru `TerytPow`:

<pre>
"TerytPow": "XXXX"
</pre>

gdzie `XXXX` oznacza właściwy kod TERYT powiatu.

> **Ważne:** Kod `TerytPow` musi odpowiadać powiatowi, którego dane znajdują się w pliku przeznaczonym do importu.

#### 10.2.1. Skopiowanie własnego pliku

Plik GML lub ZIP zawierający dane RCN Twojego powiatu należy skopiować do katalogu:

<pre>
/opt/gugik/rcn-importer/input
</pre>

Załóżmy, że plik przeznaczony do importu znajduje się w katalogu domowym administratora.

W poniższych poleceniach zastąp `NAZWA_PLIKU.zip` rzeczywistą nazwą pliku zawierającego dane RCN Twojego powiatu.

Skopiuj plik:

```bash
sudo cp ~/NAZWA_PLIKU.zip /opt/gugik/rcn-importer/input/
```

Nadaj użytkownikowi `rcn-importer` własność skopiowanego pliku:

```bash
sudo chown rcn-importer:rcn-importer /opt/gugik/rcn-importer/input/NAZWA_PLIKU.zip
```

Sprawdź zawartość katalogu `input`:

```bash
sudo ls -la /opt/gugik/rcn-importer/input
```

Upewnij się, że w katalogu znajduje się właściwy plik przeznaczony do importu.

#### 10.2.2. Uruchomienie importu

Uruchom aplikację:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
EXIT_CODE=$?
echo "Kod zakończenia RCN Importer: $EXIT_CODE"
```

Prawidłowy wynik:

<pre>
Kod zakończenia RCN Importer: 0
</pre>

Kod `0` oznacza poprawne zakończenie importu.

#### 10.2.3. Sprawdzenie wyniku importu

Sprawdź katalogi robocze:

```bash
sudo ls -la /opt/gugik/rcn-importer/processed
sudo ls -la /opt/gugik/rcn-importer/error
sudo ls -la /opt/gugik/rcn-importer/artifacts
sudo ls -la /opt/gugik/rcn-importer/logs
```

Po poprawnym imporcie przetworzony plik powinien zostać przeniesiony z katalogu `input` do:

<pre>
/opt/gugik/rcn-importer/processed
</pre>

Jeżeli plik trafił do:

<pre>
/opt/gugik/rcn-importer/error
</pre>

sprawdź logi aplikacji:

```bash
sudo ls -lht /opt/gugik/rcn-importer/logs
```

Sprawdź również dane zapisane w bazie:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn < ~/RCN/2-aplikacja-do-ladowania-danych-z-gml/gml/count.sql
```

Po poprawnym wykonaniu powinny zostać wyświetlone liczby obiektów zapisanych w bazie.

Liczba obiektów będzie zależna od zawartości pliku z danymi własnego powiatu.

> **Uwaga:** Jeżeli wynik zostanie wyświetlony w trybie podglądu i nie nastąpi automatyczny powrót do wiersza poleceń, naciśnij `q`, aby zakończyć podgląd i wrócić do terminala.

Import danych własnego powiatu można uznać za zakończony poprawnie, jeżeli:

- aplikacja zakończyła działanie kodem `0`;
- przetworzony plik został przeniesiony do katalogu `processed`;
- plik nie trafił do katalogu `error`;
- dane zostały zapisane w bazie `rcn`;
- aplikacja utworzyła wymagane logi i artefakty.

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
ExecStart=/opt/gugik/rcn-importer/rcn-importer-1.1
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

> **Uwaga:** Jeżeli polecenie `systemctl status` otworzy widok pełnoekranowy, naciśnij `q`, aby zakończyć podgląd i wrócić do terminala.

Sprawdź również logi usługi:

```bash
sudo journalctl -u rcn-importer.service -n 100 --no-pager
```

Usługa ma typ `oneshot`, dlatego po zakończeniu działania aplikacji nie musi pozostawać stale aktywna. Najważniejsze jest, aby wykonanie zakończyło się bez błędu.

Utwórz timer, np. uruchamiający importer codziennie o godzinie 02:00:

```bash
sudo nano /etc/systemd/system/rcn-importer.timer
```

Wprowadź konfigurację:

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

> **Uwaga:** Jeżeli polecenie `systemctl status` otworzy widok pełnoekranowy, naciśnij `q`, aby zakończyć podgląd i wrócić do terminala.

Opcja `Persistent=true` powoduje, że jeżeli zaplanowane uruchomienie nie odbyło się np. z powodu wyłączenia serwera, systemd uruchomi zadanie po ponownym uruchomieniu systemu.

Nie konfiguruj jednocześnie `cron` i `systemd timer` dla tej samej instalacji. Zalecany jest `systemd timer`.

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
sudo chmod +x /opt/gugik/rcn-importer/rcn-importer-1.1
sudo chmod 600 /opt/gugik/rcn-importer/appsettings.json
```

Sprawdź skopiowane pliki:

```bash
sudo ls -la /opt/gugik/rcn-importer
```

Wykonaj ręczny test aplikacji:

```bash
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
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
sudo ls -l /opt/gugik/rcn-importer/rcn-importer-1.1
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
sudo -u rcn-importer sh -c 'cd /opt/gugik/rcn-importer && ./rcn-importer-1.1'
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

---

## 15. Weryfikacja zakończenia Etapu 2

Etap 2 można uznać za zakończony, jeżeli:

- istnieje `/opt/gugik/rcn-importer/rcn-importer-1.1`;
- aplikacja uruchamia się jako użytkownik systemowy `rcn-importer`;
- `appsettings.json` zawiera poprawne połączenie z bazą danych, właściwy `TerytPow` i świadomie wybrany `Mode`;
- wykonano co najmniej jeden poprawny import;
- poprawnie przetworzony plik został przeniesiony do katalogu `processed`;
- dane zostały zapisane w bazie `rcn`;
- aplikacja tworzy logi i artefakty;
- jeżeli skonfigurowano automatyczne uruchamianie — `rcn-importer.timer` jest aktywny i widoczny na liście zaplanowanych timerów.

Jeżeli skonfigurowano automatyczne uruchamianie, stan timera można sprawdzić poleceniami:

```bash
sudo systemctl status rcn-importer.timer
systemctl list-timers --all | grep rcn-importer
```

> **Uwaga:** Jeżeli polecenie `systemctl status` otworzy widok pełnoekranowy, naciśnij `q`, aby zakończyć podgląd i wrócić do terminala.

Po pozytywnej weryfikacji powyższych elementów Etap 2 można uznać za zakończony.

## 16. Przejście do Etapu 3

Jeżeli instalacja i weryfikacja aplikacji RCN Importer zakończyły się prawidłowo, **Etap 2 — instalacja aplikacji RCN Importer — jest zakończony**.

Przejdź do **Etapu 3 — konfiguracji usługi publikacyjnej MapServer**:

[Otwórz instrukcję konfiguracji MapServera](https://github.com/GlownyUrzadGeodezjiIKartografii/RCN/blob/main/3-konfiguracja-uslugi/mapserver-rcn-debian-trixie.md)
