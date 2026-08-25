# RCN Importer

Aplikacja konsolowa do automatycznego importu danych Rejestru Cen
Nieruchomości (RCN) z plików GML lub ZIP do bazy PostgreSQL/PostGIS.

## Informacje o aplikacji

**Nazwa:** RCN Importer\
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)\
**Autor:** Szymon Szczerba\
**Rok:** 2026\
**Technologia:** .NET 9\
**Typ aplikacji:** aplikacja konsolowa  
**Wersja:** 1.0  

Aplikacja jest przeznaczona do cyklicznego lub ręcznego zasilania bazy
RCN. Jedno uruchomienie programu przetwarza wszystkie obsługiwane pliki
znajdujące się w katalogu `input`, zapisuje wynik działania i kończy
pracę.

## Jak działa aplikacja

Podczas każdego uruchomienia aplikacja:

1.  odczytuje konfigurację z pliku `appsettings.json`;
2.  łączy się ze wskazaną bazą PostgreSQL/PostGIS;
3.  wyszukuje w katalogu `input` obsługiwane pliki GML i ZIP;
4.  odczytuje i diagnozuje każdy plik wejściowy oraz każdy plik GML
    znajdujący się wewnątrz archiwum ZIP;
5.  poprawnie odczytane dane scala do jednej wspólnej kolekcji RCN dla
    powiatu wskazanego w `TerytPow`;
6.  wykonuje zapis do bazy zgodnie z trybem ustawionym w parametrze
    `Mode`;
7.  zapisuje informację o błędach z przypisaniem do konkretnego pliku
    źródłowego, a w przypadku ZIP również do konkretnego GML wewnątrz
    archiwum;
8.  po zakończeniu przetwarzania przenosi pliki źródłowe do `processed`
    albo `error`, zgodnie z wynikiem przetwarzania;
9.  zapisuje szczegółowe raporty JSON w katalogu `artifacts`;
10. zapisuje przebieg działania w katalogu `logs`;
11. przed rozpoczęciem importu wykonuje automatyczne czyszczenie starych
    plików zgodnie z parametrem `RetentionDays`;
12. po wykonaniu zapisu odświeża widoki materializowane i kończy
    działanie.

Jedno uruchomienie aplikacji obsługuje cały zestaw plików znajdujących
się w katalogu `input`. Jeżeli w katalogu znajduje się więcej niż jeden
plik, dane z poprawnych plików są łączone przed zapisem do bazy. Pliki
nie są kolejno używane do niezależnego zastępowania danych powiatu.

Błąd pojedynczego pliku nie kończy od razu analizy całego katalogu.
Aplikacja sprawdza pozostałe pliki i zapisuje diagnostykę wskazującą,
który plik był poprawny, który nie zawierał danych, a którego nie udało
się odczytać lub przetworzyć.

## Struktura katalogów

Po uruchomieniu aplikacji wykorzystywana jest następująca struktura:

``` text
RCN-Importer/
├── appsettings.json
├── input/
├── processed/
├── error/
├── artifacts/
└── logs/
```

Znaczenie katalogów:

-   `input` -- pliki oczekujące na import (`*.gml`, `*.zip`);
-   `processed` -- pliki, których import zakończył się poprawnie;
-   `error` -- pliki, których nie udało się poprawnie zaimportować lub
    które nie zawierały danych do załadowania;
-   `artifacts` -- techniczne raporty JSON dotyczące wykonanych
    importów;
-   `logs` -- logi działania aplikacji.

Katalogi są określane względem katalogu aplikacji, dlatego ta sama
konfiguracja może być używana w systemie Linux.

## Miejsce w repozytorium

RCN Importer stanowi **Etap 2** wdrożenia. Repozytorium jest pobierane jeden raz do `~/RCN`, zgodnie z głównym README. Materiały tego etapu znajdują się w:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```

## Pliki w repozytorium

Materiały dotyczące aplikacji znajdują się w:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```

Najważniejsze katalogi:

```text
gml/                — pliki testowe i count.sql
publish/linux-x64/  — kompletna publikacja aplikacji dla Debiana x86_64
```

Do instalacji należy kopiować **całą zawartość** katalogu `publish/linux-x64`, a nie pojedynczy plik wykonywalny.

## Pierwsze uruchomienie

Przed pierwszym uruchomieniem należy:

1.  przygotować bazę `rcn` wraz ze schematem wymaganym przez aplikację i
    rozszerzeniem PostGIS;
2.  skonfigurować połączenie z bazą w `appsettings.json`(m.in. `TerytPow`);
3.  wybrać właściwy tryb importu w parametrze `Mode`;
4.  umieścić pliki GML lub ZIP w katalogu `input`;
5.  uruchomić aplikację;
6.  po zakończeniu sprawdzić komunikat końcowy oraz -- w razie potrzeby
    -- katalogi `processed`, `error`, `artifacts` i `logs`.

Nie należy umieszczać nowych plików bezpośrednio w `processed`, `error`
ani `artifacts`. Pliki przeznaczone do załadowania należy zawsze
kopiować do `input`.

## Konfiguracja `appsettings.json`

Przykładowa konfiguracja:

``` json
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

### Połączenie z bazą danych

Sekcja `Database` wskazuje nazwę połączenia i schemat bazy:

``` json
"Database": {
  "ConnectionName": "Localhost",
  "Schema": "uslugi_rcn"
}
```

`ConnectionName` musi odpowiadać nazwie wpisu znajdującego się w sekcji
`ConnectionStrings`.

Przykład:

``` json
"ConnectionStrings": {
  "Localhost": "Host=localhost;Port=5432;Database=rcn;Username=postgres;Password=UZUPELNIJ"
}
```

Należy ustawić:

-   `Host` -- adres serwera PostgreSQL;
-   `Port` -- port PostgreSQL, standardowo `5432`;
-   `Database` -- nazwę bazy, domyślnie `rcn`;
-   `Username` -- użytkownika posiadającego wymagane uprawnienia;
-   `Password` -- hasło użytkownika.

> **Ważne:** plik `appsettings.json` zawiera dane dostępowe do bazy.
> Należy ograniczyć dostęp do tego pliku i nie publikować go wraz z
> rzeczywistym hasłem w publicznych repozytoriach ani innych
> ogólnodostępnych lokalizacjach.

## Konfiguracja importu

Sekcja:

``` json
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
```

Parametry:

  -----------------------------------------------------------------------
  Parametr                            Znaczenie
  ----------------------------------- -----------------------------------
  `TerytPow`                          Czterocyfrowy kod TERYT powiatu
                                      obsługiwanego przez daną
                                      instalację. Wszystkie pliki z
                                      `InputPath` są traktowane jako dane
                                      tego powiatu; ich nazwy mogą być
                                      dowolne.

  `InputPath`                         Katalog z plikami oczekującymi na
                                      import.

  `ProcessedPath`                     Katalog, do którego trafiają pliki
                                      poprawnie zaimportowane.

  `ErrorPath`                         Katalog dla plików zakończonych
                                      błędem lub bez danych do
                                      załadowania.

  `ArtifactsDir`                      Katalog technicznych raportów JSON.

  `LogDirectory`                      Katalog logów aplikacji.

  `Mode`                              Tryb importu: `REPLACE`, `UPSERT`
                                      lub `INSERT`.

  `MoveFilesAfterImport`              Określa, czy po przetworzeniu plik
                                      ma zostać przeniesiony z `input`.

  `RetentionDays`                     Liczba dni przechowywania starszych
                                      plików w `processed`, `error`,
                                      `artifacts` i `logs`. Wartość `0`
                                      wyłącza automatyczne usuwanie.
  -----------------------------------------------------------------------

Domyślnie obsługiwane są pliki `*.gml` i `*.zip`.

## Wiele plików w katalogu `input`

W katalogu `input` może znajdować się jeden albo wiele plików GML i ZIP.
Dla instalacji starosty wszystkie są traktowane jako dane powiatu
wskazanego w `ImportJob:TerytPow`.

Przykład:

``` text
input/
├── transakcje.gml
├── nieruchomosci.gml
├── dane_uzupelniajace.gml
└── paczka.zip
```

Nazwy plików nie muszą zawierać kodu TERYT. Kod powiatu jest pobierany z
`appsettings.json`.

Aplikacja najpierw próbuje odczytać poszczególne pliki. Dane z plików,
które udało się poprawnie przygotować i odczytać, są dodawane do
wspólnej kolekcji RCN. Dopiero po zakończeniu odczytu wykonywana jest
operacja zapisu do bazy.

Przykład dla dwóch poprawnych plików:

``` text
plik_1.gml ─┐
            ├──> wspólna kolekcja RCN ──> jeden zapis do bazy
plik_2.gml ─┘
```

Oznacza to, że w trybie `REPLACE` dwa pliki nie wykonują dwóch kolejnych
operacji REPLACE. Są scalane, a następnie cały poprawny zestaw zastępuje
dane powiatu w jednej operacji.

Jeżeli jeden z plików jest błędny, aplikacja nadal sprawdza pozostałe
pliki i zapisuje informację o błędzie z nazwą konkretnego pliku.

-   w trybach `UPSERT` i `INSERT` dane z poprawnych plików mogą zostać
    załadowane mimo błędu innego pliku;
-   w trybie `REPLACE` błąd części zestawu blokuje wykonanie częściowego
    zastąpienia danych. Aplikacja nie wykonuje REPLACE z niekompletnego
    zestawu, aby nie usunąć z bazy prawidłowych danych, których zabrakło
    wskutek błędnego pliku.

Plik bez danych RCN albo plik całkowicie odfiltrowany jest również
wykazywany w diagnostyce. Szczegóły należy sprawdzić w `logs` i
`artifacts`.

## Tryby importu

### `REPLACE`

Zastępuje dane powiatu kompletnym zestawem przygotowanym podczas danego
uruchomienia. Jeżeli w `input` znajduje się kilka poprawnych plików, ich
dane są najpierw scalane do jednej kolekcji RCN, a następnie wykonywana
jest jedna operacja REPLACE.

Jeżeli choć jeden element wymaganego zestawu zakończy się błędem
uniemożliwiającym bezpieczne zbudowanie kompletnej kolekcji, częściowy
REPLACE nie jest wykonywany. Pozostałe pliki są mimo to analizowane,
dzięki czemu raport może wskazać wszystkie wykryte problemy.

``` json
"Mode": "REPLACE"
```

### `UPSERT`

Dodaje nowe rekordy oraz aktualizuje rekordy istniejące. Jeżeli część
plików jest błędna, aplikacja może wykorzystać dane z plików poprawnych
i jednocześnie zaraportować błędy dla pozostałych plików.

``` json
"Mode": "UPSERT"
```

### `INSERT`

Służy do dodawania nowych danych zgodnie z logiką trybu INSERT. Błąd
pojedynczego pliku nie musi blokować załadowania danych z pozostałych
poprawnych plików.

``` json
"Mode": "INSERT"
```

Wybrany tryb jest zapisywany w logu oraz w artefaktach importu. Przed
uruchomieniem należy upewnić się, że `Mode` odpowiada oczekiwanemu
sposobowi aktualizacji bazy.

## Przenoszenie plików

Przy ustawieniu:

``` json
"MoveFilesAfterImport": true
```

plik po zakończeniu przetwarzania znika z katalogu `input` i zostaje
przeniesiony do odpowiedniego katalogu docelowego.

Po poprawnym imporcie:

``` text
input/powiat.zip
        ↓
processed/2026-08-12-12_31_00_powiat.zip
```

Po błędzie lub braku danych do załadowania:

``` text
input/powiat.zip
        ↓
error/2026-08-12-12_31_00_powiat.zip
```

Do nazwy przenoszonego pliku dodawana jest data i czas. Pozwala to
zachować historię kolejnych importów i ogranicza ryzyko nadpisania
wcześniej przetworzonego pliku o tej samej nazwie.

Przy ustawieniu:

``` json
"MoveFilesAfterImport": false
```

plik pozostaje w katalogu `input`. Przy kolejnym uruchomieniu może więc
zostać ponownie znaleziony i ponownie przetworzony. Do normalnej pracy
automatycznej zalecane jest pozostawienie wartości `true`.

## Automatyczne usuwanie starych plików

Aplikacja może automatycznie usuwać stare pliki, aby katalogi robocze
nie zwiększały swojej wielkości bez ograniczeń.

Mechanizmem steruje parametr:

``` json
"RetentionDays": 7
```

Retencja obejmuje katalogi:

-   `processed`;
-   `error`;
-   `artifacts`;
-   `logs`.

**Katalog `input` nie jest automatycznie czyszczony.** Dzięki temu
aplikacja nie usunie pliku, który nadal oczekuje na zaimportowanie.

### `RetentionDays = 0`

``` json
"RetentionDays": 0
```

Automatyczne usuwanie jest wyłączone. Żadne pliki nie są usuwane z
powodu retencji.

W logu zapisywana jest informacja:

``` text
Retencja plików: 0 dni - automatyczne usuwanie plików jest wyłączone.
```

### `RetentionDays = 7`

``` json
"RetentionDays": 7
```

Aplikacja usuwa pliki mające 7 dni lub więcej. Pod uwagę brana jest data
ostatniej modyfikacji pliku.

Przykładowo, jeżeli aplikacja zostanie uruchomiona 12.08.2026, usuwane
będą pliki z dnia 05.08.2026 i starsze.

Przykładowy log:

``` text
Retencja plików: 7 dni. Usuwane będą pliki z dnia 2026-08-05 i starsze.
Retencja katalogu processed: usunięto 12 plików, błędy: 0.
Retencja katalogu error: usunięto 2 pliki, błędy: 0.
Retencja katalogu artifacts: usunięto 14 plików, błędy: 0.
Retencja katalogu logs: usunięto 6 plików, błędy: 0.
Zakończono czyszczenie plików. Usunięto: 34, błędy: 0.
```

### Wartość ujemna

Wartość mniejsza od `0` jest traktowana jako nieprawidłowa konfiguracja,
ale **nie zatrzymuje działania aplikacji**.

Przykład:

``` json
"RetentionDays": -7
```

Aplikacja bezpiecznie przyjmuje wtedy `0`, wyłącza automatyczne usuwanie
i kontynuuje pracę.

W logu zostanie zapisane:

``` text
Nieprawidłowa wartość RetentionDays: -7. Ustawiono 0 dni - automatyczne usuwanie plików jest wyłączone.
```

### Błąd podczas usuwania pliku

Jeżeli pojedynczego starego pliku nie można usunąć, np. z powodu braku
uprawnień albo dlatego, że jest używany przez inny proces, błąd zostaje
zapisany w logu. Nie powoduje to zatrzymania całego importu.

Czyszczenie wykonywane jest przed wyszukaniem i rozpoczęciem importu
nowych plików.

## Katalog `artifacts`

Katalog `artifacts` zawiera raporty techniczne w formacie JSON. Nie są w
nim przechowywane kopie plików GML ani ZIP.

Dla każdego przetworzonego pliku tworzony jest osobny raport, np.:

``` text
artifacts/2026-08-12-12_31_00_powiat.json
```

Raport może zawierać m.in.:

-   nazwę pliku źródłowego;
-   wykorzystany tryb importu;
-   status `SUCCESS` albo `ERROR`;
-   czas rozpoczęcia i zakończenia;
-   czas trwania operacji;
-   ścieżkę, do której przeniesiono plik;
-   opis błędu, jeżeli import się nie powiódł;
-   komunikaty zwrócone podczas importu.

Przykład:

``` json
{
  "SourceFile": "powiat.zip",
  "Mode": "REPLACE",
  "Status": "SUCCESS",
  "StartedAt": "2026-08-12T10:25:31+02:00",
  "FinishedAt": "2026-08-12T10:25:45+02:00",
  "DurationSeconds": 14.2,
  "DestinationFile": "processed/2026-08-12-12_31_00_powiat.zip",
  "Error": null,
  "Messages": []
}
```

Po każdym uruchomieniu aplikacji zapisywane jest również zbiorcze
podsumowanie:

``` text
artifacts/2026-08-12-12_31_00_run-summary.json
```

Zawiera ono m.in. liczbę znalezionych plików, liczbę importów poprawnych
i błędnych, użyty tryb, katalogi robocze, informację o odświeżeniu
widoków materializowanych oraz kod zakończenia programu.

Artefakty są szczególnie przydatne przy diagnostyce problemów oraz
sprawdzaniu historii automatycznych uruchomień.

## Logi

Przebieg działania aplikacji jest zapisywany w katalogu `logs`.

W logu znajdują się m.in.:

-   data i czas uruchomienia;
-   wybrany tryb importu;
-   katalog źródłowy;
-   katalog plików poprawnych;
-   katalog plików błędnych;
-   katalog artefaktów;
-   lista obsługiwanych rozszerzeń;
-   zastosowana retencja plików i wynik automatycznego czyszczenia;
-   informacje o rozpoczęciu i wyniku importu poszczególnych plików;
-   informacja, gdzie został przeniesiony plik;
-   błędy i ostrzeżenia;
-   wynik odświeżenia widoków materializowanych;
-   podsumowanie całego uruchomienia.

W przypadku problemów z importem w pierwszej kolejności należy sprawdzić
log, a następnie odpowiadający danemu plikowi raport w katalogu
`artifacts`.

## Pliki ZIP

Archiwum ZIP jest traktowane jako jedno źródło wejściowe, ale znajdujące
się w nim pliki GML są przygotowywane i diagnozowane osobno.

Przykład:

``` text
dane.zip
├── czesc_1.gml   → OK
├── czesc_2.gml   → BŁĄD
└── czesc_3.gml   → OK
```

W logu i artefakcie aplikacja może wskazać błąd konkretnego pliku, np.
`dane.zip / czesc_2.gml`. Jeżeli nie można otworzyć samego archiwum,
błąd jest przypisywany do pliku ZIP.

W `UPSERT` i `INSERT` poprawne dane z `czesc_1.gml` i `czesc_3.gml` mogą
zostać wykorzystane mimo błędu `czesc_2.gml`. W `REPLACE` nie jest
wykonywane częściowe zastąpienie danych z niekompletnego
archiwum/zestawu.

Do katalogu `input` należy przekazywać wyłącznie pliki przeznaczone do
importu. Nie należy używać tego katalogu jako archiwum.

## Uruchamianie ręczne

### Linux

W docelowej instalacji aplikacja działa z katalogu `/opt/gugik/rcn-importer` jako dedykowany użytkownik systemowy `rcn-importer`. Dla wersji opublikowanej jako plik wykonywalny:

``` bash
chmod +x rcn-importer-1.0
sudo -u rcn-importer ./rcn-importer-1.0
```

Aplikacja może być również uruchamiana automatycznie przez
`systemd timer` lub `cron`.

## Automatyczne uruchamianie

Program został zaprojektowany tak, aby jedno uruchomienie oznaczało
jeden pełny cykl przetwarzania katalogu `input`. Dzięki temu może być
bezpiecznie uruchamiany cyklicznie przez mechanizmy systemowe, np.:

-   `systemd timer`;
-   `cron`.

Przed włączeniem pracy cyklicznej zaleca się wykonać co najmniej jeden
import ręczny i sprawdzić połączenie z bazą, tryb importu, logi oraz
wynik w bazie.

## Kody zakończenia

Aplikacja zwraca kod zakończenia, który może być wykorzystany przez
skrypty, Harmonogram zadań lub `systemd`:

    Kod Znaczenie
  ----- ---------------------------------------------
    `0` Import zakończony sukcesem.
    `1` Wystąpił błąd importu.
    `2` Operacja została anulowana.
    `3` Błąd konfiguracji.
    `4` Błąd odświeżania widoków materializowanych.
    `5` Nie znaleziono plików wejściowych.

Kod `5` oznacza, że w chwili uruchomienia w katalogu `input` nie było
plików przeznaczonych do importu. Nie oznacza to uszkodzenia bazy
danych.

## Co sprawdzić po imporcie

Po zakończeniu pracy warto sprawdzić:

1.  czy plik zniknął z `input`;
2.  czy trafił do `processed` albo `error`;
3.  czy w `artifacts` powstał raport dotyczący pliku;
4.  czy log nie zawiera błędów lub ostrzeżeń;
5.  w przypadku importu produkcyjnego -- czy dane są dostępne w bazie i
    oczekiwanych widokach.

## Najczęstsze problemy

### Brak plików do importu

Sprawdź, czy plik znajduje się w katalogu `input` i ma rozszerzenie
`.gml` albo `.zip`.

### Plik trafił do `error`

Sprawdź log oraz raport JSON w `artifacts`. Powinny zawierać informację
o przyczynie niepowodzenia.

### Brak połączenia z PostgreSQL

Sprawdź `Host`, `Port`, `Database`, `Username` i `Password` w
`ConnectionStrings`. W przypadku połączenia z innym serwerem sprawdź
również konfigurację sieci, zapory i PostgreSQL (`pg_hba.conf`).

### Dane zostały zaimportowane w niewłaściwym trybie

Przed kolejnym uruchomieniem sprawdź wartość `ImportJob:Mode`. Tryb
importu wpływa na sposób aktualizacji danych w bazie.

### Plik jest przetwarzany ponownie

Sprawdź `MoveFilesAfterImport`. Przy wartości `false` poprawnie
przetworzony plik pozostaje w `input` i może zostać ponownie znaleziony
przy następnym uruchomieniu.

## Zalecenia eksploatacyjne

-   przed pierwszym użyciem wykonaj test na danych testowych;
-   przed importem sprawdź wartość `Mode`;
-   pozostaw `MoveFilesAfterImport` ustawione na `true` przy pracy
    automatycznej;
-   regularnie kontroluj katalog `error`;
-   ustaw `RetentionDays` odpowiednio do dostępnego miejsca i wymaganej
    historii importów; wartość `0` wyłącza automatyczne czyszczenie;
-   jeżeli wymagana jest dłuższa archiwizacja, skopiuj potrzebne pliki
    poza katalogi objęte retencją przed upływem ustawionej liczby dni;
-   zabezpiecz `appsettings.json`, ponieważ może zawierać hasło do bazy;
-   nie uruchamiaj równocześnie kilku instancji importera korzystających
    z tego samego katalogu `input`, jeżeli nie zostało to wcześniej
    przetestowane i świadomie skonfigurowane.
