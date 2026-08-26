# RCN - narzędzie do publikacji danych Rejestru Cen Nieruchomości

Pakiet narzędzi przygotowany z myślą o **starostwach**, przeznaczony do
przygotowania, zasilania oraz publikacji danych Rejestru Cen
Nieruchomości (RCN).

Rozwiązanie obejmuje przygotowanie bazy danych PostgreSQL/PostGIS,
aplikację **RCN Importer** do ładowania danych RCN z plików GML oraz
konfigurację serwera publikacyjnego opartego na MapServerze.

Pakiet prowadzi administratora przez cały proces wdrożenia -- od
przygotowania bazy danych, przez załadowanie danych z plików GML, aż do
uruchomienia usługi publikującej dane RCN.

## Informacje

**Nazwa:** RCN - narzędzie do publikacji danych Rejestru Cen
Nieruchomości\
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)\
**Autorzy:** Szymon Szczerba, Krzysztof Błachnio\
**Rok:** 2026\
**System operacyjny:** Debian 13 (trixie) lub nowszy\
**Baza danych:** PostgreSQL 18 lub nowsza\
**Rozszerzenie przestrzenne:** PostGIS\
**Schemat bazy danych:** `uslugi_rcn`\
**Aplikacja importująca:** RCN Importer\
**Serwer publikacyjny:** MapServer\
**Repozytorium:** `GlownyUrzadGeodezjiIKartografii/RCN`\
**Wersja:** 1.0

## Wymagania sprzętowe

Dla środowiska produkcyjnego, w którym na jednej maszynie uruchomione są PostgreSQL/PostGIS, RCN Importer oraz MapServer, zalecana jest następująca minimalna konfiguracja:

- **procesor:** 4 rdzenie `x86_64/amd64`,
- **pamięć RAM:** 8 GB,
- **dysk:** SSD, co najmniej 20 GB wolnego miejsca,
- **sieć:** połączenie 1 Gb/s.

Wymagana przestrzeń dyskowa może być większa w zależności od wielkości bazy RCN, liczby przechowywanych plików GML/ZIP, logów oraz sposobu wykonywania kopii zapasowych.

W przypadku rozdzielenia PostgreSQL/PostGIS, RCN Importera i MapServera na osobne maszyny wymagania sprzętowe należy dostosować do roli i przewidywanego obciążenia poszczególnych serwerów.

## Wymagania systemowe

Minimalne wymagania systemowe:

-   system **Linux Debian 13 (trixie) lub nowszy** na architekturze
    `x86_64/amd64`,
-   konto użytkownika z możliwością wykonywania poleceń `sudo`,
-   dostęp do Internetu podczas pobierania repozytorium i instalowania
    pakietów,
-   program `git` (jeżeli nie jest zainstalowany, poniżej znajduje się
    polecenie instalacji).

PostgreSQL, PostGIS, RCN Importer i MapServer są przygotowywane w
kolejnych etapach zgodnie z instrukcjami znajdującymi się w odpowiednich
katalogach repozytorium.

------------------------------------------------------------------------

## Pobranie repozytorium w Debianie

### 1. Zaloguj się na serwer

Zaloguj się na serwer Debian na konto użytkownika posiadającego
możliwość wykonywania poleceń `sudo`.

### 2. Sprawdź architekturę systemu

Wykonaj:

``` bash
uname -m
```

Dla obsługiwanej architektury wynik powinien być:

<pre>
x86_64
</pre>

### 3. Sprawdź, czy Git jest zainstalowany

Wykonaj:

``` bash
git --version
```

Jeżeli Git jest zainstalowany, zobaczysz informację o jego wersji.

Jeżeli polecenie `git` nie jest dostępne, zainstaluj je:

``` bash
sudo apt update
sudo apt install -y git
```

### 4. Przejdź do katalogu domowego

``` bash
cd ~
```

### 5. Pobierz repozytorium RCN

Wykonaj:

``` bash
git clone https://github.com/GlownyUrzadGeodezjiIKartografii/RCN.git
```

Repozytorium zostanie pobrane do katalogu:

<pre>
~/RCN
</pre>

### 6. Sprawdź pobrane pliki

Wykonaj:

``` bash
ls -la ~/RCN
```

Powinny być widoczne trzy główne katalogi:

<pre>
1-baza-danych
2-aplikacja-do-ladowania-danych-z-gml
3-konfiguracja-uslugi
</pre>

### 7. Nadaj uprawnienia do wykonywania skryptów

Po pobraniu repozytorium nadaj uprawnienia do wykonywania wszystkim
plikom `.sh` znajdującym się w repozytorium:

``` bash
find ~/RCN -type f -name "*.sh" -exec chmod +x {} \;
```

### 8. Sprawdzenie stanu i aktualizacja wcześniej pobranego repozytorium

Jeżeli repozytorium `RCN` zostało już wcześniej pobrane, **nie należy
klonować go ponownie**. Przed pobraniem najnowszej wersji warto najpierw
sprawdzić stan lokalnego repozytorium.

Przejdź do katalogu repozytorium:

``` bash
cd ~/RCN
```

Sprawdź aktualny stan:

``` bash
git status
```

Polecenie pokaże między innymi:

-   aktualną gałąź;
-   czy w repozytorium znajdują się lokalne zmiany;
-   czy są pliki zmodyfikowane lub nieśledzone.

Następnie pobierz z serwera informacje o najnowszych zmianach, bez
modyfikowania lokalnych plików:

``` bash
git fetch
```

Ponownie sprawdź stan repozytorium:

``` bash
git status
```

Jeżeli lokalna gałąź jest starsza od repozytorium zdalnego i nie ma
lokalnych zmian kolidujących z aktualizacją, pobierz najnowszą wersję:

``` bash
git pull --ff-only
```

Po aktualizacji sprawdź ponownie stan:

``` bash
git status
```

Możesz również wyświetlić ostatni commit znajdujący się w lokalnym
repozytorium:

``` bash
git log -1 --oneline
```

Jeżeli repozytorium jest aktualne i nie zawiera lokalnych zmian,
`git status` powinien wskazywać, że lokalna gałąź jest zgodna z
repozytorium zdalnym oraz że nie ma zmian do zatwierdzenia.

> **Ważne**
>
> Jeżeli `git status` pokaże lokalne zmiany w plikach, nie usuwaj ich
> ani nie nadpisuj bez wcześniejszego sprawdzenia.
>
> Zakres lokalnych zmian możesz wyświetlić poleceniem:
>
> ``` bash
> git diff
> ```
>
> Polecenia `git clone` używa się przy pierwszym pobraniu repozytorium.
> Dla istniejącego repozytorium `~/RCN` do sprawdzania i pobierania
> kolejnych wersji używaj `git status`, `git fetch` oraz
> `git pull --ff-only`.

Po aktualizacji repozytorium nie ma potrzeby ponownego wykonywania
zakończonych etapów wdrożenia, chyba że instrukcja dotycząca konkretnej
aktualizacji wyraźnie tego wymaga.

------------------------------------------------------------------------

## Jak korzystać z repozytorium?

Repozytorium zostało podzielone na trzy główne katalogi odpowiadające
kolejnym etapom wdrożenia:

<pre>
RCN/
├── 1-baza-danych/
├── 2-aplikacja-do-ladowania-danych-z-gml/
└── 3-konfiguracja-uslugi/
</pre>

**Przy pierwszym wdrożeniu wykonuj etapy dokładnie w tej kolejności:**

<pre>
1. Przygotowanie bazy danych
             ↓
2. Instalacja RCN Importer i załadowanie danych GML
             ↓
3. Konfiguracja MapServera i uruchomienie publikacji
</pre>

> **Ważne**
>
> Każdy katalog zawiera własną instrukcję prowadzącą przez dany etap.
> Nie rozpoczynaj od samodzielnego uruchamiania poszczególnych skryptów.
> **Najpierw otwórz instrukcję znajdującą się w danym katalogu i wykonuj
> opisane w niej czynności krok po kroku.**

------------------------------------------------------------------------

# Etap 1 --- przygotowanie bazy danych RCN

### Od czego zacząć?

Otwórz [instrukcję instalacji bazy danych](https://github.com/GlownyUrzadGeodezjiIKartografii/RCN/blob/main/1-baza-danych/Instrukcja_instalacji_bazy_danych.md)

i wykonuj kolejne punkty instrukcji.

Tutaj znajdują się materiały potrzebne do przygotowania bazy danych wykorzystywanej przez całe rozwiązanie.

Etap obejmuje między innymi:

-   instalację PostgreSQL 18,
-   instalację PostGIS,
-   utworzenie bazy danych `rcn`,
-   utworzenie struktury schematu `uslugi_rcn`,
-   przygotowanie tabel i widoków materializowanych,
-   konfigurację użytkownika `ms_rcn` przeznaczonego dla MapServera,
-   konfigurację dostępu sieciowego do PostgreSQL, jeżeli jest wymagany,
-   weryfikację poprawności przygotowanego środowiska.

Po zakończeniu tego etapu powinna działać kompletna baza danych RCN
gotowa do przyjęcia danych z plików GML.

> **Nie przechodź do Etapu 2, dopóki weryfikacja opisana w instrukcji
> bazy danych nie zakończy się prawidłowo.**

------------------------------------------------------------------------

# Etap 2 --- instalacja RCN Importer i załadowanie danych GML

### Od czego zacząć?

Otwórz [instrukcję instalacji aplikacji RCN Importer](https://github.com/GlownyUrzadGeodezjiIKartografii/RCN/blob/main/2-aplikacja-do-ladowania-danych-z-gml/Instrukcja-Instalacji-Aplikacji-RCN-Importer.md)

RCN Importer odpowiada za:

-   odczyt danych RCN z plików GML,
-   przetworzenie danych wejściowych,
-   załadowanie danych do bazy `rcn`,
-   aktualizację danych znajdujących się w bazie,
-   odświeżanie wymaganych widoków materializowanych,
-   zapisywanie informacji o przebiegu importu w logach.

Wykonaj opisane w niej czynności w podanej kolejności.

Na tym etapie skonfigurujesz między innymi połączenie aplikacji z bazą
`rcn` oraz wykonasz pierwszy import danych GML.

Po zakończeniu sprawdź, czy dane zostały prawidłowo załadowane do bazy.

> **Etap 2 wymaga prawidłowo zakończonego Etapu 1.**
>
> RCN Importer zapisuje dane do bazy przygotowanej w poprzednim etapie.

------------------------------------------------------------------------

# Etap 3 --- konfiguracja usługi publikacyjnej

Po przygotowaniu bazy i załadowaniu danych przejdź do katalogu:

### Od czego zacząć?

Otwórz [instrukcję instalacji mapservera](https://github.com/GlownyUrzadGeodezjiIKartografii/RCN/blob/main/3-konfiguracja-uslugi/mapserver-rcn-debian-trixie.md)

Publikacja danych realizowana jest z wykorzystaniem **MapServera**,
który odczytuje dane z bazy PostgreSQL/PostGIS przygotowanej w Etapie 1
i zasilonej danymi w Etapie 2.

------------------------------------------------------------------------

# Schemat działania rozwiązania

<pre>
          pliki GML z danymi RCN
                    │
                    ▼
             ┌──────────────┐
             │ RCN Importer │
             └──────┬───────┘
                    │
                    ▼
        ┌────────────────────────┐
        │ PostgreSQL / PostGIS   │
        │                        │
        │ baza: rcn              │
        │ schemat: uslugi_rcn    │
        └───────────┬────────────┘
                    │
                    ▼
             ┌─────────────┐
             │  MapServer  │
             └──────┬──────┘
                    │
                    ▼
          publikacja danych RCN
</pre>

------------------------------------------------------------------------

# Ważne przed rozpoczęciem

-   Wykonuj etapy **1 → 2 → 3** w podanej kolejności.
-   W każdym katalogu rozpocznij od przeczytania znajdującej się tam
    instrukcji.
-   Nie uruchamiaj skryptów tylko na podstawie ich nazw --- część z nich
    służy do operacji administracyjnych, odtwarzania lub usuwania
    środowiska.
-   Skrypty `RELOAD` nie są elementem standardowej pierwszej instalacji.
-   Przed przejściem do następnego etapu sprawdź, czy poprzedni etap
    zakończył się prawidłowo.
-   Jeżeli MapServer znajduje się na innym serwerze niż PostgreSQL,
    konieczna jest odpowiednia konfiguracja dostępu sieciowego do bazy.
    Została ona opisana w instrukcji Etapu 1.
-   Jeżeli MapServer i PostgreSQL działają na tym samym serwerze,
    możliwe jest wykorzystanie połączenia lokalnego.
