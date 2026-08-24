# Instalacja i przygotowanie bazy RCN na Debianie

## 1. Cel

Pakiet przygotowuje PostgreSQL 18, PostGIS oraz bazę danych `rcn` dla usługi RCN na systemie **Debian 12 lub nowszym**.

Pakiet składa się z trzech głównych etapów:

1. instalacja PostgreSQL 18 i PostGIS,
2. przygotowanie bazy danych `rcn`,
3. import struktury `uslugi_rcn` z pliku `struktura_uslugi_rcn.sql`.

## 2. Pliki

W jednym katalogu powinny znajdować się:

```text
00_instalacja_postgresql_postgis.sh
01_przygotowanie_bazy_rcn.sh
02_import_struktury_rcn.sh
03_konfiguracja_uzytkownika_mapserver.sh
04_reload_bazy_rcn.sh
struktura_uslugi_rcn.sql
```

Opcjonalny skrypt testowy:

```text
cofnij_do_czystego_debiana.sh
```

Skrypt czyszczący jest destrukcyjny i jest przeznaczony wyłącznie dla maszyny testowej.

## 3. Wymagania i sprawdzenie systemu

Skrypty instalacyjne są przeznaczone dla systemu **Debian 12 lub nowszego** na architekturze `x86_64/amd64`.

Przed rozpoczęciem instalacji należy sprawdzić wersję systemu:

```bash
cat /etc/os-release
```

Polecenie wyświetli informacje o zainstalowanym systemie, w tym nazwę i wersję Debiana.

Przykładowy wynik:

```text
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
```

Sam numer wersji Debiana można sprawdzić poleceniem:

```bash
cat /etc/debian_version
```

Dodatkowo należy zapewnić:

- system Debian 12 lub nowszy,
- architekturę `x86_64/amd64`,
- dostęp do Internetu podczas instalacji pakietów,
- konto użytkownika z możliwością wykonywania poleceń `sudo`.

Sprawdzenie architektury systemu:

```bash
uname -m
```

Dla architektury `x86_64/amd64` wynik powinien być:

```text
x86_64
```

PostgreSQL 18 jest instalowany z oficjalnego repozytorium PostgreSQL PGDG dla Debiana.

## 4. Przygotowanie

```bash
mkdir -p ~/RCN
cd ~/RCN
chmod +x *.sh
```

## 5. Instalacja PostgreSQL i PostGIS

```bash
./00_instalacja_postgresql_postgis.sh
```

Skrypt:

1. sprawdza, czy system jest Debianem,
2. instaluje narzędzia APT wymagane do konfiguracji repozytorium,
3. dodaje oficjalne repozytorium PostgreSQL PGDG,
4. instaluje PostgreSQL 18,
5. instaluje PostGIS dla PostgreSQL 18,
6. sprawdza lub tworzy klaster `18/main`,
7. uruchamia PostgreSQL,
8. sprawdza wersję serwera,
9. sprawdza dostępność rozszerzenia `postgis`.

Typowe ścieżki dla tej instalacji:

```text
/usr/lib/postgresql/18/bin
/var/lib/postgresql/18/main
/etc/postgresql/18/main
```

Stan klastrów można sprawdzić:

```bash
pg_lsclusters
```

## 6. Przygotowanie bazy `rcn`

```bash
./01_przygotowanie_bazy_rcn.sh
```

Skrypt nie usuwa istniejącej bazy.

Jeżeli baza `rcn` nie istnieje, zostanie utworzona. Następnie skrypt włącza PostGIS:

```sql
CREATE EXTENSION postgis;
```

## 7. Import struktury

Plik:

```text
struktura_uslugi_rcn.sql
```

musi znajdować się obok skryptu:

```text
02_import_struktury_rcn.sh
```

Uruchom:

```bash
./02_import_struktury_rcn.sh
```

Jeżeli schemat `uslugi_rcn` już istnieje, import jest pomijany i wykonywana jest weryfikacja.


## 8. Użytkownik PostgreSQL dla MapServera

Po utworzeniu struktury bazy należy skonfigurować oddzielnego użytkownika PostgreSQL przeznaczonego wyłącznie dla MapServera.

Użytkownik:

```text
ms_rcn
```

ma otrzymać tylko:

- `CONNECT` do bazy `rcn`,
- `USAGE` na schemat `uslugi_rcn`,
- `SELECT` na widoki materializowane:
  - `uslugi_rcn.mv_dzialki`,
  - `uslugi_rcn.mv_budynki`,
  - `uslugi_rcn.mv_lokale`.

Użytkownik `ms_rcn` nie powinien otrzymywać praw do zapisu danych ani modyfikowania struktury bazy.

Uruchom:

```bash
./03_konfiguracja_uzytkownika_mapserver.sh
```

Przy pierwszym uruchomieniu skrypt poprosi o hasło dla użytkownika `ms_rcn`.

Jeżeli użytkownik `ms_rcn` już istnieje, skrypt nie zmienia jego hasła, ale ponownie ustawia wymagane uprawnienia. Jest to istotne po ponownym utworzeniu bazy `rcn`.

Użytkownik administracyjny `postgres` pozostaje w systemie. Jest nadal wykorzystywany do przygotowania bazy, importu struktury oraz operacji administracyjnych. MapServer powinien natomiast korzystać z ograniczonego użytkownika `ms_rcn`.

## 9. Dostęp sieciowy do PostgreSQL — MapServer, DBeaver i inne komputery

Samo utworzenie użytkownika PostgreSQL nie powoduje automatycznie udostępnienia bazy z innych komputerów.

Jeżeli z bazą `rcn` ma łączyć się:

- MapServer działający na innym serwerze,
- DBeaver uruchomiony na komputerze administratora,
- inne narzędzie działające na zdalnym komputerze,

administrator PostgreSQL musi skonfigurować **nasłuch serwera PostgreSQL**, `pg_hba.conf` oraz ewentualną zaporę sieciową. PostgreSQL używa `pg_hba.conf` do kontroli uwierzytelniania klientów. citeturn538033search0

### 9.1. Sprawdzenie aktualnego nasłuchu

```bash
sudo ss -ltnp | grep 5432
```

Jeżeli widoczne są tylko adresy:

```text
127.0.0.1:5432
[::1]:5432
```

PostgreSQL przyjmuje połączenia tylko z lokalnej maszyny.

### 9.2. `postgresql.conf`

Edytuj:

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
```

Należy odpowiednio skonfigurować parametr `listen_addresses`.

Przykładowo, jeżeli PostgreSQL ma nasłuchiwać na wszystkich interfejsach serwera:

```text
listen_addresses = '*'
```

Bezpieczniejszym rozwiązaniem jest wskazanie tylko wymaganych adresów/interfejsów, jeżeli konfiguracja sieci na to pozwala.

> `listen_addresses` określa, na jakich interfejsach PostgreSQL przyjmuje połączenia TCP/IP. Sam wpis w `pg_hba.conf` nie wystarczy, jeżeli serwer nie nasłuchuje na odpowiednim interfejsie.

### 9.3. `pg_hba.conf` — dostęp MapServera

Edytuj:

```bash
sudo nano /etc/postgresql/18/main/pg_hba.conf
```

Dla MapServera najlepiej dopuścić wyłącznie adres IP serwera MapServer.

Przykład:

```text
host    rcn    ms_rcn    10.0.100.20/32    scram-sha-256
```

gdzie:

```text
10.0.100.20
```

należy zastąpić rzeczywistym adresem IP serwera MapServer.

Maska `/32` oznacza dopuszczenie tylko jednego konkretnego adresu IPv4.

Nie zaleca się stosowania szerokich wpisów typu:

```text
0.0.0.0/0
```

jeżeli nie jest to świadomie wymagane przez administratora.

### 9.4. `pg_hba.conf` — dostęp administratora z DBeavera

Jeżeli administrator chce połączyć się z bazą z własnego komputera, np. przez DBeaver, jego adres IP również musi być dopuszczony.

Przykład dla komputera administratora o adresie `10.0.100.50`:

```text
host    rcn    postgres    10.0.100.50/32    scram-sha-256
```

Jeżeli do DBeavera zostanie przygotowany osobny użytkownik administracyjny, w miejscu `postgres` należy podać jego nazwę.

Każdy kolejny komputer wymagający bezpośredniego dostępu do PostgreSQL powinien zostać świadomie dopuszczony przez administratora, najlepiej osobnym wpisem `/32`.

### 9.5. Restart PostgreSQL po zmianie `listen_addresses`

Po zmianie `postgresql.conf` wykonaj:

```bash
sudo pg_ctlcluster 18 main restart
```

Sprawdź ponownie:

```bash
sudo ss -ltnp | grep 5432
```

Po samych zmianach `pg_hba.conf` konfigurację można również przeładować, ale restart klastra jest prostym sposobem zastosowania obu rodzajów zmian podczas pierwszej konfiguracji.

### 9.6. Zapora sieciowa

Jeżeli na serwerze lub w infrastrukturze sieciowej działa firewall, port:

```text
5432/TCP
```

musi być dostępny z adresu MapServera lub komputera administratora.

Nie należy otwierać portu 5432 dla całego Internetu lub nieograniczonej sieci, jeżeli nie jest to wymagane.

### 9.7. Test połączenia

Z innego komputera można sprawdzić dostępność portu PostgreSQL:

```bash
nc -vz ADRES_SERWERA_POSTGRESQL 5432
```

W DBeaver należy skonfigurować m.in.:

```text
Host:     adres serwera Debian/PostgreSQL
Port:     5432
Database: rcn
User:     postgres lub inny użytkownik administracyjny
```

MapServer powinien korzystać z:

```text
Database: rcn
User:     ms_rcn
```

Dostęp `ms_rcn` ograniczony jest w bazie do trzech widoków materializowanych. PostgreSQL pozwala nadać `SELECT` bezpośrednio na widoku materializowanym. citeturn538033search7

## 10. Ponowne utworzenie bazy `rcn` (RELOAD)

Skrypt `04_reload_bazy_rcn.sh` służy do całkowitego odtworzenia bazy danych `rcn`.

Uruchomienie:

```bash
./04_reload_bazy_rcn.sh
```

Skrypt:

1. wymaga potwierdzenia wykonania operacji,
2. usuwa istniejącą bazę danych `rcn` wraz ze znajdującymi się w niej danymi,
3. uruchamia `01_przygotowanie_bazy_rcn.sh`,
4. uruchamia `02_import_struktury_rcn.sh`,
5. uruchamia `03_konfiguracja_uzytkownika_mapserver.sh` i ponownie nadaje uprawnienia `ms_rcn`.

> **UWAGA:** operacja usuwa wszystkie dane znajdujące się w bazie `rcn`.

Rola PostgreSQL `ms_rcn` jest rolą klastra i nie jest usuwana przez `DROP DATABASE`, ale uprawnienia do obiektów nowo utworzonej bazy muszą zostać nadane ponownie. Dlatego skrypt RELOAD ponownie uruchamia konfigurację użytkownika MapServer.

Wszystkie poniższe pliki muszą znajdować się w tym samym katalogu:

```text
01_przygotowanie_bazy_rcn.sh
02_import_struktury_rcn.sh
03_konfiguracja_uzytkownika_mapserver.sh
04_reload_bazy_rcn.sh
struktura_uslugi_rcn.sql
```

## 11. Kolejność

Pierwsza instalacja:

```bash
./00_instalacja_postgresql_postgis.sh
./01_przygotowanie_bazy_rcn.sh
./02_import_struktury_rcn.sh
./03_konfiguracja_uzytkownika_mapserver.sh
./03_konfiguracja_uzytkownika_mapserver.sh
```

Jeżeli PostgreSQL i PostGIS są już przygotowane:

```bash
./01_przygotowanie_bazy_rcn.sh
./02_import_struktury_rcn.sh
```

## 12. Wyświetlenie tabel w bazie danych

Połączenie z bazą danych rcn jako użytkownik postgres:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn
```

Wyświetlenie wszystkich tabel znajdujących się w schemacie uslugi_rcn:

```bash
\dt uslugi_rcn.*
```

Wyjście z konsoli PostgreSQL:

```bash
\q
```

## 13. Przydatne polecenia Debian/PostgreSQL

Poniższe polecenia mogą być wykorzystywane przez administratora do sprawdzania stanu PostgreSQL, zarządzania klastrem oraz diagnostyki podstawowych problemów z bazą danych.

### Sprawdzenie listy klastrów PostgreSQL

```bash
pg_lsclusters
```

Polecenie wyświetla klastry PostgreSQL dostępne na serwerze. Pozwala sprawdzić m.in. wersję PostgreSQL, nazwę klastra, port, jego aktualny stan oraz lokalizację danych.

Dla przygotowanej konfiguracji powinien być widoczny klaster PostgreSQL `18/main` ze stanem `online`.

### Uruchomienie klastra PostgreSQL

```bash
sudo pg_ctlcluster 18 main start
```

Uruchamia klaster PostgreSQL `18/main`. Polecenie może być użyte, jeżeli baza danych została zatrzymana lub nie uruchomiła się automatycznie po restarcie serwera.

### Zatrzymanie klastra PostgreSQL

```bash
sudo pg_ctlcluster 18 main stop
```

Zatrzymuje klaster PostgreSQL `18/main` w kontrolowany sposób. Może być przydatne podczas prac administracyjnych lub konserwacyjnych.

Przed zatrzymaniem należy upewnić się, że żadna aplikacja nie wykonuje aktualnie operacji na bazie danych.

### Restart klastra PostgreSQL

```bash
sudo pg_ctlcluster 18 main restart
```

Zatrzymuje, a następnie ponownie uruchamia klaster PostgreSQL `18/main`.

Polecenie może być potrzebne np. po zmianach konfiguracji PostgreSQL wymagających ponownego uruchomienia serwera.

### Sprawdzenie statusu usługi PostgreSQL

```bash
sudo systemctl status postgresql
```

Wyświetla aktualny stan usługi PostgreSQL zarządzanej przez `systemd`. Pozwala szybko sprawdzić, czy usługa jest uruchomiona oraz czy podczas jej uruchamiania wystąpiły błędy.

Wyjście z podglądu statusu:

```text
q
```

### Sprawdzenie wersji PostgreSQL

```bash
/usr/lib/postgresql/18/bin/psql --version
```

Wyświetla wersję zainstalowanego klienta `psql`. Polecenie pozwala potwierdzić, że na serwerze dostępne są narzędzia PostgreSQL 18.

### Połączenie z bazą danych `rcn`

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn
```

Uruchamia konsolę PostgreSQL jako użytkownik administracyjny `postgres` i łączy bezpośrednio z bazą danych `rcn`.

Po połączeniu można wykonywać polecenia SQL oraz polecenia administracyjne `psql`, np. wyświetlić wszystkie tabele w schemacie `uslugi_rcn`:

```text
\dt uslugi_rcn.*
```

Wyjście z konsoli PostgreSQL:

```text
\q
```

## 14. Ważne informacje

- skrypty wymagają `sudo`,
- istniejąca baza `rcn` nie jest usuwana,
- istniejące rozszerzenie PostGIS nie jest tworzone ponownie,
- istniejący schemat `uslugi_rcn` nie jest nadpisywany,
- import SQL używa `ON_ERROR_STOP=1`,
- użytkownik `ms_rcn` jest przeznaczony dla MapServera i ma wyłącznie `CONNECT`, `USAGE` oraz `SELECT` na `mv_dzialki`, `mv_budynki` i `mv_lokale`,
- zdalny dostęp z MapServera, DBeavera lub innego komputera wymaga osobnej konfiguracji `listen_addresses`, `pg_hba.conf` i ewentualnej zapory,
- `04_reload_bazy_rcn.sh` usuwa i odtwarza wyłącznie bazę `rcn`; nie usuwa instalacji PostgreSQL ani PostGIS,
- `cofnij_do_czystego_debiana.sh` usuwa PostgreSQL 18 i jego dane i powinien być używany wyłącznie na maszynie testowej.
