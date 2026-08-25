# Cofnięcie instalacji PostgreSQL/PostGIS do stanu sprzed Etapu 1

## 1. Przeznaczenie

Skrypt:

```text
cofnij_do_czystego_debiana.sh
```

służy do usunięcia z **maszyny testowej Debian** elementów zainstalowanych podczas przygotowania PostgreSQL 18 i PostGIS w ramach **Etapu 1 — baza danych**.

Skrypt jest operacją destrukcyjną. Usuwa PostgreSQL 18 wraz z klastrem `18/main`, bazami danych i konfiguracją tego klastra.

> **UWAGA**
>
> Użycie skryptu powoduje usunięcie bazy `rcn` oraz wszystkich innych baz i ról PostgreSQL znajdujących się w klastrze PostgreSQL `18/main`. Operacji nie można cofnąć.
>
> Skrypt należy stosować wyłącznie na maszynie testowej, na której świadomie chcesz usunąć instalację PostgreSQL/PostGIS wykonaną w Etapie 1.

Skrypt dotyczy PostgreSQL/PostGIS. **Nie resetuje aplikacji RCN Importer z Etapu 2.**

## 2. Co usuwa skrypt

Skrypt:

- sprawdza, czy systemem jest Debian;
- sprawdza dostęp do `sudo`;
- zatrzymuje i usuwa klaster PostgreSQL `18/main`, jeżeli istnieje;
- usuwa pakiety PostgreSQL 18;
- usuwa klienta PostgreSQL 18;
- usuwa pakiety PostGIS dla PostgreSQL 18;
- wykonuje `apt-get autoremove --purge`;
- usuwa pozostały katalog danych:

```text
/var/lib/postgresql/18
```

- usuwa pozostały katalog konfiguracji:

```text
/etc/postgresql/18
```

- usuwa repozytorium PGDG dodane podczas instalacji:

```text
/etc/apt/sources.list.d/pgdg.list
```

- usuwa klucz repozytorium PGDG:

```text
/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg
```

- wykonuje:

```bash
sudo apt-get update
```

Usunięcie klastra powoduje również usunięcie:

- bazy `rcn`;
- schematu `uslugi_rcn`;
- danych znajdujących się w bazie;
- ról i użytkowników PostgreSQL utworzonych w tym klastrze, w tym użytkowników wykorzystywanych przez RCN i MapServer;
- uprawnień nadanych tym użytkownikom;
- konfiguracji klastra PostgreSQL, w tym zmian wykonanych w `pg_hba.conf` i `postgresql.conf`.

## 3. Czego skrypt nie usuwa

Skrypt nie usuwa:

- użytkownika systemowego Linux `rcn-importer`;
- katalogu aplikacji `/opt/gugik/rcn-importer`;
- plików aplikacji RCN Importer;
- jednostek `systemd` aplikacji RCN Importer;
- repozytorium `~/RCN`;
- plików Etapu 1 znajdujących się w `~/RCN/1-baza-danych`;
- plików Etapu 2 znajdujących się w `~/RCN/2-aplikacja-do-ladowania-danych-z-gml`;
- plików Etapu 3 znajdujących się w `~/RCN/3-konfiguracja-uslugi`.

Jeżeli chcesz również usunąć instalację aplikacji RCN Importer, użyj osobnego skryptu:

```text
~/RCN/2-aplikacja-do-ladowania-danych-z-gml/reset_instalacji_rcn_importer.sh
```

## 4. Lokalizacja pliku

Skrypt znajduje się w katalogu **Etapu 1**:

```text
~/RCN/1-baza-danych/cofnij_do_czystego_debiana.sh
```

Przejdź do katalogu:

```bash
cd ~/RCN/1-baza-danych
```

Sprawdź obecność pliku:

```bash
ls -la cofnij_do_czystego_debiana.sh
```

## 5. Nadanie prawa wykonywania

Jeżeli skrypt nie ma jeszcze prawa wykonywania, nadaj je:

```bash
chmod +x cofnij_do_czystego_debiana.sh
```

Sprawdź:

```bash
ls -l cofnij_do_czystego_debiana.sh
```

## 6. Uruchomienie

Uruchom:

```bash
./cofnij_do_czystego_debiana.sh
```

Skrypt sam sprawdzi dostęp do `sudo` i w razie potrzeby poprosi o uwierzytelnienie administratora.

Przed rozpoczęciem usuwania skrypt wyświetli ostrzeżenie i poprosi o wpisanie dokładnie:

```text
CZYSTY_DEBIAN
```

Dopiero po podaniu tej wartości rozpocznie usuwanie PostgreSQL 18 i PostGIS.

## 7. Weryfikacja po wykonaniu

Skrypt wykonuje podstawową weryfikację automatycznie. Po jego zakończeniu możesz dodatkowo sprawdzić stan systemu.

Sprawdź, czy klaster PostgreSQL 18 nadal istnieje:

```bash
if command -v pg_lsclusters >/dev/null 2>&1; then
    pg_lsclusters
else
    echo "OK - polecenie pg_lsclusters nie jest dostępne"
fi
```

Sprawdź klienta PostgreSQL:

```bash
if command -v psql >/dev/null 2>&1; then
    psql --version
else
    echo "OK - polecenie psql nie jest dostępne"
fi
```

Sprawdź katalog danych:

```bash
if [ -e /var/lib/postgresql/18 ]; then
    echo "UWAGA - katalog /var/lib/postgresql/18 nadal istnieje"
else
    echo "OK - katalog danych PostgreSQL 18 został usunięty"
fi
```

Sprawdź katalog konfiguracji:

```bash
if [ -e /etc/postgresql/18 ]; then
    echo "UWAGA - katalog /etc/postgresql/18 nadal istnieje"
else
    echo "OK - katalog konfiguracji PostgreSQL 18 został usunięty"
fi
```

Sprawdź repozytorium PGDG:

```bash
if [ -e /etc/apt/sources.list.d/pgdg.list ]; then
    echo "UWAGA - plik pgdg.list nadal istnieje"
else
    echo "OK - plik repozytorium PGDG został usunięty"
fi
```

Sprawdź, czy repozytorium RCN nadal istnieje:

```bash
ls -la ~/RCN
```

Repozytorium `~/RCN` powinno pozostać bez zmian.

## 8. Pełny reset środowiska RCN

Jeżeli celem jest ponowne przetestowanie **całego wdrożenia od początku**, wykonaj dwa niezależne resety.

### Krok 1 — usunięcie aplikacji RCN Importer

Przejdź do katalogu Etapu 2:

```bash
cd ~/RCN/2-aplikacja-do-ladowania-danych-z-gml
```

Jeżeli jest to potrzebne, nadaj skryptowi prawo wykonywania:

```bash
chmod +x reset_instalacji_rcn_importer.sh
```

Uruchom:

```bash
./reset_instalacji_rcn_importer.sh
```

Potwierdzenie:

```text
RESET_RCN_IMPORTER
```

### Krok 2 — usunięcie PostgreSQL/PostGIS

Przejdź do katalogu Etapu 1:

```bash
cd ~/RCN/1-baza-danych
```

Jeżeli jest to potrzebne, nadaj skryptowi prawo wykonywania:

```bash
chmod +x cofnij_do_czystego_debiana.sh
```

Uruchom:

```bash
./cofnij_do_czystego_debiana.sh
```

Potwierdzenie:

```text
CZYSTY_DEBIAN
```

Po wykonaniu obu resetów repozytorium `~/RCN` pozostaje na serwerze. Można ponownie rozpocząć wdrożenie od **Etapu 1 — instalacji bazy danych**, korzystając z aktualnej instrukcji znajdującej się w:

```text
~/RCN/1-baza-danych
```

Nie ma potrzeby ponownego klonowania repozytorium.

## 9. Aktualizacja repozytorium przed ponownym testem

Jeżeli przed ponownym testem chcesz pobrać najnowszą wersję materiałów, przejdź do repozytorium:

```bash
cd ~/RCN
```

Sprawdź stan:

```bash
git status
```

Pobierz informacje o zmianach z repozytorium zdalnego:

```bash
git fetch
```

Ponownie sprawdź stan:

```bash
git status
```

Jeżeli nie ma lokalnych zmian kolidujących z aktualizacją, pobierz najnowszą wersję:

```bash
git pull --ff-only
```

Na końcu sprawdź:

```bash
git status
git log -1 --oneline
```

> **Ważne**
>
> Jeżeli `git status` pokaże lokalne zmiany, nie usuwaj ich ani nie nadpisuj bez wcześniejszego sprawdzenia. Zakres zmian możesz wyświetlić poleceniem:
>
> ```bash
> git diff
> ```

## 10. Ważne informacje

- skrypt należy stosować wyłącznie na maszynie testowej;
- wszystkie dane z klastra PostgreSQL `18/main` zostaną usunięte;
- baza `rcn` zostanie usunięta;
- schemat `uslugi_rcn` zostanie usunięty wraz z bazą;
- role i użytkownicy PostgreSQL utworzeni w klastrze zostaną usunięci razem z klastrem;
- konfiguracja dostępu MapServera i narzędzi administracyjnych w `pg_hba.conf` zostanie usunięta razem z konfiguracją PostgreSQL 18;
- ustawienia `postgresql.conf`, w tym `listen_addresses`, zostaną usunięte razem z konfiguracją klastra;
- po ponownej instalacji należy ponownie skonfigurować PostgreSQL, bazę `rcn`, wymaganych użytkowników i ich uprawnienia, `pg_hba.conf` oraz — jeżeli jest wymagany dostęp zdalny — `listen_addresses`;
- aplikacja RCN Importer jest resetowana osobnym skryptem `reset_instalacji_rcn_importer.sh`;
- repozytorium `~/RCN` nie jest usuwane.
