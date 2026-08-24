# Cofnięcie instalacji PostgreSQL/PostGIS do czystego Debiana

## 1. Przeznaczenie

Skrypt:

``` text
cofnij_do_czystego_debiana.sh
```

służy do usunięcia z **maszyny testowej Debian** elementów
zainstalowanych podczas przygotowania PostgreSQL 18 i PostGIS.

Skrypt jest operacją destrukcyjną. Usuwa PostgreSQL 18 wraz z bazami
danych i konfiguracją.

> **UWAGA:** użycie skryptu powoduje usunięcie bazy `rcn` oraz
> wszystkich innych baz znajdujących się w klastrze PostgreSQL
> `18/main`. Operacji nie można cofnąć.

Skrypt dotyczy PostgreSQL/PostGIS. Nie służy do resetowania samej
aplikacji RCN Importer.

## 2. Co usuwa skrypt

Skrypt:

-   sprawdza, czy systemem jest Debian,
-   zatrzymuje i usuwa klaster PostgreSQL `18/main`,
-   usuwa pakiety PostgreSQL 18,
-   usuwa klienta PostgreSQL 18,
-   usuwa pakiety PostGIS dla PostgreSQL 18,
-   wykonuje `apt autoremove --purge`,
-   usuwa pozostały katalog danych:

``` text
/var/lib/postgresql/18
```

-   usuwa pozostały katalog konfiguracji:

``` text
/etc/postgresql/18
```

-   usuwa repozytorium PGDG dodane podczas instalacji:

``` text
/etc/apt/sources.list.d/pgdg.list
```

-   usuwa klucz repozytorium PGDG:

``` text
/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg
```

-   wykonuje:

``` bash
sudo apt-get update
```

Usunięcie klastra powoduje również usunięcie bazy `rcn`, schematu
`uslugi_rcn`, użytkownika PostgreSQL `ms_rcn`, jego uprawnień oraz zmian
dotyczących PostgreSQL zapisanych w konfiguracji klastra, w tym
`pg_hba.conf` i `postgresql.conf`.

## 3. Czego skrypt nie usuwa

Skrypt nie usuwa:

-   użytkownika systemowego Linux `rcn-importer`,
-   katalogu aplikacji `/opt/gugik/rcn-importer`,
-   plików aplikacji RCN Importer,
-   jednostek `systemd` aplikacji RCN Importer,
-   katalogu roboczego `~/RCN`,
-   skryptów `.sh` i pliku `struktura_uslugi_rcn.sql` znajdujących się w
    `~/RCN`.

Jeżeli chcesz również usunąć instalację aplikacji RCN Importer, użyj
osobnego skryptu:

``` text
reset_instalacji_rcn_importer.sh
```

## 4. Lokalizacja pliku

Jeżeli plik został umieszczony w katalogu:

``` text
/home/sszczerba/RCN
```

przejdź do niego:

``` bash
cd ~/RCN
```

Sprawdź obecność pliku:

``` bash
ls -la cofnij_do_czystego_debiana.sh
```

## 5. Nadanie prawa wykonywania

``` bash
chmod +x cofnij_do_czystego_debiana.sh
```

Możesz sprawdzić prawa:

``` bash
ls -l cofnij_do_czystego_debiana.sh
```

## 6. Uruchomienie

Uruchom:

``` bash
./cofnij_do_czystego_debiana.sh
```

Skrypt wyświetli ostrzeżenie i poprosi o wpisanie dokładnie:

``` text
CZYSTY_DEBIAN
```

Dopiero po podaniu tej wartości rozpocznie usuwanie PostgreSQL 18 i
PostGIS.

## 7. Sprawdzenie po wykonaniu

Sprawdź klastry PostgreSQL:

``` bash
pg_lsclusters
```

Jeżeli polecenie nie jest już dostępne po usunięciu pakietów, jest to
prawidłowe.

Sprawdź PostgreSQL:

``` bash
psql --version
```

Jeżeli PostgreSQL został całkowicie usunięty, polecenie powinno zwrócić
informację, że `psql` nie został znaleziony.

Sprawdź katalog danych:

``` bash
ls -la /var/lib/postgresql/18
```

Powinien być nieobecny.

Sprawdź katalog konfiguracji:

``` bash
ls -la /etc/postgresql/18
```

Powinien być nieobecny.

Sprawdź repozytorium PGDG:

``` bash
ls -la /etc/apt/sources.list.d/pgdg.list
```

Plik powinien być nieobecny.

## 8. Pełny reset środowiska RCN

Jeżeli celem jest ponowne przetestowanie **całej instalacji od
początku**, należy wykonać dwa niezależne resety.

### Krok 1 --- usunięcie aplikacji RCN Importer

``` bash
cd ~/RCN
chmod +x reset_instalacji_rcn_importer.sh
./reset_instalacji_rcn_importer.sh
```

Potwierdzenie:

``` text
RESET_RCN_IMPORTER
```

### Krok 2 --- usunięcie PostgreSQL/PostGIS

``` bash
chmod +x cofnij_do_czystego_debiana.sh
./cofnij_do_czystego_debiana.sh
```

Potwierdzenie:

``` text
CZYSTY_DEBIAN
```

Po wykonaniu obu skryptów można ponownie rozpocząć test instrukcji
instalacji od pierwszego kroku.

## 9. Ważne informacje

-   skrypt należy stosować wyłącznie na maszynie testowej,
-   wszystkie dane z klastra PostgreSQL `18/main` zostaną usunięte,
-   baza `rcn` zostanie usunięta,
-   użytkownik PostgreSQL `ms_rcn` zostanie usunięty razem z klastrem,
-   konfiguracja dostępu MapServera i DBeavera w `pg_hba.conf` zostanie
    usunięta razem z konfiguracją PostgreSQL 18,
-   po ponownej instalacji należy ponownie skonfigurować PostgreSQL,
    bazę `rcn`, użytkownika `ms_rcn`, `pg_hba.conf` oraz --- jeśli jest
    wymagany dostęp zdalny --- `listen_addresses`,
-   aplikacja RCN Importer jest resetowana osobnym skryptem
    `reset_instalacji_rcn_importer.sh`.
