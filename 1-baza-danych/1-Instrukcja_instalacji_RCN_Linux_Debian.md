# RCN – baza danych PostgreSQL/PostGIS

Zestaw skryptów i instrukcji przeznaczonych do instalacji oraz przygotowania bazy danych Rejestru Cen Nieruchomości (RCN) w środowisku Linux Debian.

Pakiet umożliwia instalację PostgreSQL i PostGIS, utworzenie bazy danych `rcn`, zaimportowanie struktury schematu `uslugi_rcn` oraz przygotowanie użytkownika bazy danych dla usługi MapServer.

## Informacje

**Nazwa:** RCN – baza danych PostgreSQL/PostGIS  
**Jednostka:** Główny Urząd Geodezji i Kartografii (GUGiK)  
**Autor:** Szymon Szczerba  
**Rok:** 2026  
**System operacyjny:** Debian 13 (trixie) lub nowszy  
**Baza danych:** PostgreSQL 18 lub nowsza  
**Rozszerzenie przestrzenne:** PostGIS  
**Schemat bazy danych:** `uslugi_rcn`  
**Repozytorium:** `GlownyUrzadGeodezjiIKartografii/RCN`  
**Wersja:** 1.0

# Instalacja i przygotowanie bazy RCN na Debianie

## 1. Cel

Pakiet przygotowuje PostgreSQL 18, PostGIS oraz bazę danych `rcn` dla usługi RCN na systemie **Debian 13 (trixie) lub nowszym**.

Pakiet składa się z trzech głównych etapów:

1. instalacja PostgreSQL 18 i PostGIS,
2. przygotowanie bazy danych `rcn`,
3. import struktury `uslugi_rcn` z pliku `struktura_uslugi_rcn.sql`.

## 2. Pliki i struktura repozytorium

Kompletne repozytorium RCN zostanie pobrane w dalszej części instrukcji do katalogu:

```text
~/RCN
```

Po pobraniu repozytorium podstawowa struktura katalogów będzie następująca:

```text
~/RCN/
├── 1-baza-danych/
├── 2-aplikacja-do-ladowania-danych-z-gml/
└── 3-konfiguracja-uslugi/
```

Pliki wykorzystywane w **Etapie 1 – przygotowanie bazy danych** znajdują się w katalogu:

```text
~/RCN/1-baza-danych
```

W katalogu tym znajdują się m.in.:

```text
00_instalacja_postgresql_postgis.sh
01_przygotowanie_bazy_rcn.sh
02_import_struktury_rcn.sh
03_konfiguracja_uzytkownika_mapserver.sh
04_reload_bazy_rcn.sh
struktura_uslugi_rcn.sql
cofnij_do_czystego_debiana.sh
```

## 3. Wymagania i sprawdzenie systemu

Skrypty instalacyjne są przeznaczone dla systemu **Debian 13 (trixie) lub nowszego** na architekturze `x86_64/amd64`.

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

- system Debian 13 (trixie) lub nowszy,
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

## 4. Przygotowanie i pobranie plików RCN

Pliki niezbędne do instalacji i konfiguracji RCN są dostępne w publicznym repozytorium GitHub Głównego Urzędu Geodezji i Kartografii.

Repozytorium zawiera trzy główne katalogi:

```text
1-baza-danych/
2-aplikacja-do-ladowania-danych-z-gml/
3-konfiguracja-uslugi/
```

### 4.1. Instalacja programu Git

Sprawdź, czy program `git` jest zainstalowany:

```bash
git --version
```

Jeżeli `git` nie jest zainstalowany, wykonaj:

```bash
sudo apt update
sudo apt install -y git
```

### 4.2. Pobranie repozytorium RCN

Przejdź do katalogu domowego:

```bash
cd ~
```

Pobierz repozytorium RCN:

```bash
git clone https://github.com/GlownyUrzadGeodezjiIKartografii/RCN.git
```

Jeżeli katalog `~/RCN` już istnieje, polecenie `git clone` zakończy się komunikatem:

```text
fatal: destination path 'RCN' already exists and is not an empty directory.
```

Jeżeli istniejące repozytorium ma zostać jedynie zaktualizowane, wykonaj:

```bash
cd ~/RCN
git pull --ff-only
```

Jeżeli chcesz usunąć lokalną kopię repozytorium i pobrać ją ponownie:

> **UWAGA:** poniższe polecenie usuwa cały katalog `~/RCN` wraz ze wszystkimi znajdującymi się w nim plikami i lokalnymi zmianami.

```bash
cd ~
rm -rf ~/RCN
git clone https://github.com/GlownyUrzadGeodezjiIKartografii/RCN.git
```

### 4.3. Sprawdzenie pobranego repozytorium

Po pobraniu sprawdź zawartość repozytorium:

```bash
ls -la ~/RCN
```

Powinny być widoczne m.in. katalogi:

```text
1-baza-danych
2-aplikacja-do-ladowania-danych-z-gml
3-konfiguracja-uslugi
```

### 4.4. Nadanie uprawnień do uruchamiania skryptów

Po pobraniu repozytorium skrypty `.sh` mogą nie mieć uprawnień do wykonywania.

Nadaj uprawnienia do wykonywania **wszystkim plikom `.sh` znajdującym się w repozytorium RCN i jego podkatalogach**:

```bash
find ~/RCN -type f -name "*.sh" -exec chmod +x {} \;
```

Polecenie wyszukuje wszystkie pliki z rozszerzeniem `.sh` w katalogu `~/RCN` oraz jego podkatalogach i nadaje im uprawnienia do wykonywania.

Możesz sprawdzić nadane uprawnienia poleceniem:

```bash
find ~/RCN -type f -name "*.sh" -ls
```

Przy plikach `.sh` powinno być widoczne uprawnienie `x`, np.:

```text
-rwxr-xr-x ... 00_instalacja_postgresql_postgis.sh
```

Po nadaniu uprawnień przejdź do katalogu instalacji bazy danych:

```bash
cd ~/RCN/1-baza-danych
```

Po wykonaniu tych czynności można przejść do instalacji PostgreSQL i PostGIS.

## 5. Instalacja PostgreSQL i PostGIS

Uruchom skrypt z instalacją:

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

Uruchom skrypt:

```bash
./01_przygotowanie_bazy_rcn.sh
```

Skrypt nie usuwa istniejącej bazy.

Jeżeli baza `rcn` nie istnieje, zostanie utworzona. Następnie skrypt włącza PostGIS:

```sql
CREATE EXTENSION postgis;
```

## 7. Ustawienie hasła użytkownika PostgreSQL `postgres`

Aplikacja RCN Importer wykorzystuje użytkownika PostgreSQL `postgres` do połączenia z bazą danych `rcn`.

Przed przejściem do kolejnych etapów należy ustawić hasło użytkownika `postgres`.

Uruchom konsolę PostgreSQL:

```bash
sudo -u postgres psql
```

Następnie wykonaj:

```text
\password postgres
```

Podaj nowe hasło, a następnie wpisz je ponownie w celu potwierdzenia.

Po prawidłowym ustawieniu hasła zakończ pracę z konsolą PostgreSQL:

```text
\q
```

> **WAŻNE – ZAPISZ HASŁO UŻYTKOWNIKA `postgres`**
>
> Zapisz ustawione hasło i przechowuj je w bezpiecznym miejscu.
>
> **To samo hasło będzie potrzebne podczas konfiguracji aplikacji RCN Importer w Etapie 2 w pliku `appsettings.json`.**
>
> PostgreSQL nie umożliwia późniejszego odczytania ustawionego hasła. W przypadku jego utraty konieczne będzie ustawienie nowego.
>

## 8. Import struktury

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


## 9. Użytkownik PostgreSQL dla MapServera

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

> **WAŻNE – ZAPISZ HASŁO UŻYTKOWNIKA `ms_rcn`**
>
> Hasło podane w tym kroku należy **zapisać i przechowywać w bezpiecznym miejscu**.
>
> Hasło będzie potrzebne w **Etapie 3 podczas konfiguracji połączenia MapServera z bazą danych RCN**.
>
> PostgreSQL nie umożliwia późniejszego odczytania ustawionego hasła. W przypadku jego utraty konieczne będzie ustawienie nowego.
>

Jeżeli użytkownik `ms_rcn` już istnieje, skrypt nie zmienia jego hasła, ale ponownie ustawia wymagane uprawnienia. Jest to istotne po ponownym utworzeniu bazy `rcn`.

Użytkownik administracyjny `postgres` pozostaje w systemie. Jest nadal wykorzystywany do przygotowania bazy, importu struktury oraz operacji administracyjnych. MapServer powinien natomiast korzystać z ograniczonego użytkownika `ms_rcn`.

## 10. Dostęp sieciowy do PostgreSQL — MapServer, DBeaver i inne komputery

Samo utworzenie użytkownika PostgreSQL nie powoduje automatycznie udostępnienia bazy z innych komputerów.

Jeżeli z bazą `rcn` ma łączyć się:

- MapServer działający na innym serwerze,
- DBeaver uruchomiony na komputerze administratora,
- inne narzędzie działające na zdalnym komputerze,

administrator PostgreSQL musi skonfigurować nasłuch serwera PostgreSQL, `pg_hba.conf` oraz ewentualną zaporę sieciową.

### 10.1. Sprawdzenie aktualnego nasłuchu

Sprawdź, na jakich adresach PostgreSQL nasłuchuje na porcie `5432`:

```bash
sudo ss -ltnp | grep 5432
```

Jeżeli widoczne są tylko adresy:

```text
127.0.0.1:5432
[::1]:5432
```

PostgreSQL przyjmuje połączenia tylko z lokalnej maszyny.

Jeżeli baza RCN ma być dostępna z innego komputera, np. z serwera MapServer lub komputera administratora, należy skonfigurować nasłuch PostgreSQL.

### 10.2. Konfiguracja nasłuchu PostgreSQL

Edytuj plik:

```bash
sudo nano /etc/postgresql/18/main/postgresql.conf
```

Odszukaj parametr:

```text
listen_addresses
```

Jeżeli PostgreSQL ma przyjmować połączenia z innych komputerów, można ustawić:

```text
listen_addresses = '*'
```

Ustawienie `*` powoduje nasłuchiwanie PostgreSQL na wszystkich dostępnych interfejsach sieciowych.

Jeżeli konfiguracja infrastruktury na to pozwala, zaleca się ograniczenie nasłuchu do wymaganych adresów lub interfejsów zamiast używania `*`.

> Zmiana `listen_addresses` jest potrzebna tylko wtedy, gdy PostgreSQL nie nasłuchuje jeszcze na interfejsie wymaganym do połączeń zdalnych.

Po wprowadzeniu zmian zapisz plik:

```text
Ctrl+O
Enter
Ctrl+X
```

### 10.3. `pg_hba.conf` --- dostęp MapServera do bazy danych

MapServer może działać:

1.  **na tym samym serwerze co PostgreSQL i baza `rcn`**, albo
2.  **na innym serwerze** i łączyć się z bazą `rcn` przez sieć.

Sposób konfiguracji zależy od tego, gdzie działa MapServer.

#### 10.3.1. MapServer i PostgreSQL działają na tym samym serwerze

Jeżeli MapServer działa na **tym samym serwerze Debian co PostgreSQL**,
nie musisz udostępniać bazy danych w sieci tylko na potrzeby MapServera.

MapServer może łączyć się z PostgreSQL lokalnie, używając adresu:

``` text
127.0.0.1
```

lub nazwy:

``` text
localhost
```

Otwórz plik:

``` bash
sudo nano /etc/postgresql/18/main/pg_hba.conf
```

Sprawdź, czy PostgreSQL zezwala na lokalne połączenia TCP/IP.

W pliku powinien znajdować się wpis podobny do:

``` text
host    all    all    127.0.0.1/32    scram-sha-256
```

Taki wpis obejmuje również lokalne połączenie użytkownika `ms_rcn` z
bazą `rcn`.

Jeżeli taki wpis już istnieje, **nie musisz dodawać osobnego wpisu dla
MapServera**.

Jeżeli chcesz zastosować bardziej ograniczony wpis przeznaczony tylko
dla bazy `rcn` i użytkownika `ms_rcn`, możesz dodać:

``` text
host    rcn    ms_rcn    127.0.0.1/32    scram-sha-256
```

W konfiguracji połączenia MapServera ustaw:

``` text
Host:     127.0.0.1
Port:     5432
Database: rcn
User:     ms_rcn
Password: HASŁO_UŻYTKOWNIKA_ms_rcn
```

> **WAŻNE**
>
> Jeżeli MapServer i PostgreSQL działają na tym samym serwerze, **nie
> zmieniaj `listen_addresses` na `'*'` tylko na potrzeby MapServera**.
>
> Połączenie może być realizowane lokalnie przez `127.0.0.1`.

#### 10.3.2. MapServer działa na innym serwerze

Jeżeli MapServer działa na **innym serwerze niż PostgreSQL**, musisz
zezwolić serwerowi MapServer na połączenie z bazą `rcn` przez sieć.

##### 1. Ustal adres IP serwera MapServer

Sprawdź adres IP serwera, na którym działa MapServer.

Przykład:

``` text
10.0.100.20
```

> **Nie kopiuj tego adresu bez sprawdzenia.**
>
> W swoim środowisku użyj rzeczywistego adresu IP serwera MapServer.

##### 2. Otwórz plik `pg_hba.conf`

Na serwerze Debian, na którym działa PostgreSQL, wykonaj:

``` bash
sudo nano /etc/postgresql/18/main/pg_hba.conf
```

##### 3. Dodaj wpis dla MapServera

Na końcu pliku dodaj:

``` text
host    rcn    ms_rcn    10.0.100.20/32    scram-sha-256
```

Zastąp `10.0.100.20` rzeczywistym adresem IP serwera MapServer.

Przykładowo, jeżeli MapServer ma adres:

``` text
192.168.1.50
```

dodaj:

``` text
host    rcn    ms_rcn    192.168.1.50/32    scram-sha-256
```

Maska `/32` oznacza, że dostęp zostanie przyznany tylko temu jednemu
adresowi IPv4.

##### 4. Zapisz plik

W edytorze `nano` naciśnij kolejno:

``` text
Ctrl+O
Enter
Ctrl+X
```

##### 5. Sprawdź `listen_addresses`

Ponieważ MapServer działa na innym serwerze, PostgreSQL musi nasłuchiwać
na interfejsie sieciowym dostępnym dla MapServera.

Skonfiguruj nasłuch zgodnie z punktem **10.2. Konfiguracja nasłuchu
PostgreSQL**.

##### 6. Sprawdź firewall

Jeżeli na serwerze lub w infrastrukturze sieciowej działa firewall,
zezwól na połączenie:

``` text
MapServer → serwer PostgreSQL → TCP/5432
```

Najlepiej dopuść port `5432/TCP` wyłącznie z adresu IP serwera
MapServer.

> **WAŻNE**
>
> Nie dodawaj bez potrzeby:
>
> ``` text
> host    rcn    ms_rcn    0.0.0.0/0    scram-sha-256
> ```
>
> `0.0.0.0/0` oznacza zezwolenie na próbę połączenia z dowolnego adresu
> IPv4.
>
> Dla MapServera działającego na innym serwerze podaj jego konkretny
> adres IP z maską `/32`.

Po zapisaniu zmian przejdź do punktu **10.5. Zastosowanie zmian
konfiguracji PostgreSQL**.

### 10.4. `pg_hba.conf` — dostęp administratora z DBeavera

Jeżeli administrator chce połączyć się z bazą z własnego komputera, np. przez DBeaver, jego adres IP również musi być dopuszczony.

Przykład dla komputera administratora o adresie `10.0.100.50`:

```text
host    rcn    postgres    10.0.100.50/32    scram-sha-256
```

Jeżeli do DBeavera zostanie przygotowany osobny użytkownik administracyjny, w miejscu `postgres` należy podać jego nazwę.

Każdy kolejny komputer wymagający bezpośredniego dostępu do PostgreSQL powinien zostać świadomie dopuszczony przez administratora, najlepiej osobnym wpisem `/32`.

### 10.5. Zastosowanie zmian konfiguracji PostgreSQL

Jeżeli zmieniono parametr `listen_addresses`, wykonaj restart klastra PostgreSQL:

```bash
sudo pg_ctlcluster 18 main restart
```

Sprawdź stan klastra:

```bash
pg_lsclusters
```

Następnie ponownie sprawdź, na jakich adresach PostgreSQL nasłuchuje:

```bash
sudo ss -ltnp | grep 5432
```

Jeżeli zmieniono wyłącznie `pg_hba.conf`, wystarczy przeładować konfigurację:

```bash
sudo pg_ctlcluster 18 main reload
```

### 10.6. Zapora sieciowa

Jeżeli na serwerze lub w infrastrukturze sieciowej działa firewall, port:

```text
5432/TCP
```

musi być dostępny z adresu MapServera lub komputera administratora.

Nie należy otwierać portu `5432` dla całego Internetu lub nieograniczonej sieci, jeżeli nie jest to wymagane.

### 10.7. Test połączenia

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

Dostęp użytkownika `ms_rcn` jest ograniczony do wymaganych widoków materializowanych przeznaczonych do publikacji danych przez MapServer.


## 11. Weryfikacja poprawności instalacji

Po zakończeniu instalacji wykonaj poniższe polecenia kontrolne.

Polecenia w tej sekcji **nie wykonują ponownie instalacji i nie
modyfikują bazy danych**. Służą wyłącznie do sprawdzenia, czy
wcześniejsze etapy przebiegły prawidłowo.

### 11.1. Sprawdź, czy PostgreSQL działa

Wykonaj:

``` bash
pg_lsclusters
```

Dla przygotowanego środowiska powinien być widoczny klaster:

``` text
Ver  Cluster  Port  Status
18   main     5432  online
```

Najważniejsza jest wartość:

``` text
Status: online
```

Jeżeli klaster `18/main` ma status `online`, PostgreSQL jest
uruchomiony.

### 11.2. Sprawdź wersję PostgreSQL

Wykonaj:

``` bash
/usr/lib/postgresql/18/bin/psql --version
```

Powinna zostać wyświetlona wersja PostgreSQL 18, np.:

``` text
psql (PostgreSQL) 18.x
```

### 11.3. Sprawdź, czy istnieje baza `rcn`

Wykonaj:

``` bash
sudo -u postgres psql -tAc "SELECT datname FROM pg_database WHERE datname='rcn';"
```

Prawidłowy wynik:

``` text
rcn
```

Jeżeli polecenie nie zwróci żadnej wartości, baza `rcn` nie istnieje.

### 11.4. Sprawdź PostGIS

Wykonaj:

``` bash
sudo -u postgres psql -d rcn -tAc "SELECT PostGIS_Version();"
```

Powinien zostać wyświetlony numer wersji PostGIS, np.:

``` text
3.6 ...
```

Oznacza to, że rozszerzenie PostGIS jest dostępne w bazie `rcn`.

### 11.5. Sprawdź schemat `uslugi_rcn`

Wykonaj:

``` bash
sudo -u postgres psql -d rcn -tAc "SELECT schema_name FROM information_schema.schemata WHERE schema_name='uslugi_rcn';"
```

Prawidłowy wynik:

``` text
uslugi_rcn
```

Jeżeli polecenie nie zwróci żadnej wartości, struktura RCN nie została
prawidłowo zaimportowana.

### 11.6. Sprawdź tabele w schemacie `uslugi_rcn`

Wykonaj:

``` bash
sudo -u postgres psql -d rcn -c "\dt uslugi_rcn.*"
```

Powinna zostać wyświetlona lista tabel znajdujących się w schemacie
`uslugi_rcn`.

Brak tabel może oznaczać, że import struktury bazy nie został wykonany
prawidłowo.

### 11.7. Sprawdź widoki materializowane dla MapServera

Wykonaj:

``` bash
sudo -u postgres psql -d rcn -c "\dm uslugi_rcn.*"
```

Na liście powinny znajdować się co najmniej następujące widoki
materializowane:

``` text
uslugi_rcn.mv_dzialki
uslugi_rcn.mv_budynki
uslugi_rcn.mv_lokale
```

Są to widoki wykorzystywane przez MapServer do publikacji danych RCN.

> **Uwaga**
>
> Na liście widoków zobaczysz również:
>
> ``` text
> uslugi_rcn.mv_powiaty
> ```
>
> Jest to **prawidłowe i oczekiwane**. Widok `mv_powiaty` nie jest
> wykorzystywany bezpośrednio przez MapServer do publikacji działek,
> budynków i lokali.
>
> Widok ten jest wykorzystywany przez aplikację **RCN Importer** i jest
> odświeżany podczas importu danych z plików GML.
>
> W przypadku instalacji obsługującej dane tylko jednego powiatu jego
> znaczenie jest pomijane. Został jednak uwzględniony w strukturze
> bazy, ponieważ RCN Importer umożliwia załadowanie i obsługę danych **z
> więcej niż jednego powiatu** w tej samej bazie.
>
> Dlatego prawidłowy wynik polecenia może zawierać cztery widoki:
>
> ``` text
> mv_budynki
> mv_dzialki
> mv_lokale
> mv_powiaty
> ```
>
> Obecność widoku `mv_powiaty` **nie oznacza błędu konfiguracji** i nie
> wymaga żadnych dodatkowych działań.

### 11.8. Sprawdź użytkownika `ms_rcn`

Wykonaj:

``` bash
sudo -u postgres psql -tAc "SELECT rolname FROM pg_roles WHERE rolname='ms_rcn';"
```

Prawidłowy wynik:

``` text
ms_rcn
```

Jeżeli polecenie nie zwróci żadnej wartości, użytkownik `ms_rcn` nie
został utworzony.

### 11.9. Sprawdź uprawnienia użytkownika `ms_rcn`

Sprawdź możliwość połączenia z bazą:

``` bash
sudo -u postgres psql -d rcn -tAc "SELECT has_database_privilege('ms_rcn','rcn','CONNECT');"
```

Prawidłowy wynik:

``` text
t
```

Sprawdź dostęp do schematu:

``` bash
sudo -u postgres psql -d rcn -tAc "SELECT has_schema_privilege('ms_rcn','uslugi_rcn','USAGE');"
```

Prawidłowy wynik:

``` text
t
```

Sprawdź dostęp do widoków materializowanych:

``` bash
sudo -u postgres psql -d rcn -c "
SELECT
    has_table_privilege('ms_rcn','uslugi_rcn.mv_dzialki','SELECT') AS mv_dzialki,
    has_table_privilege('ms_rcn','uslugi_rcn.mv_budynki','SELECT') AS mv_budynki,
    has_table_privilege('ms_rcn','uslugi_rcn.mv_lokale','SELECT') AS mv_lokale;
"
```

Prawidłowy wynik powinien zawierać:

``` text
 mv_dzialki | mv_budynki | mv_lokale
------------+-------------+-----------
 t          | t           | t
```

Wartość `t` oznacza, że użytkownik posiada wymagane uprawnienie.

### 11.10. Sprawdź, gdzie PostgreSQL nasłuchuje

Wykonaj:

``` bash
sudo ss -ltnp | grep 5432
```

Jeżeli MapServer działa na tym samym serwerze co PostgreSQL,
wystarczający jest m.in. nasłuch lokalny:

``` text
127.0.0.1:5432
```

Jeżeli MapServer działa na innym serwerze, PostgreSQL musi również
nasłuchiwać na odpowiednim interfejsie sieciowym.

Szczegółowa konfiguracja dostępu sieciowego została opisana w punkcie
**10**.

### 11.11. Wynik weryfikacji

Instalację bazy danych RCN można uznać za prawidłowo zakończoną, jeżeli:

-   klaster PostgreSQL `18/main` ma status `online`,
-   zainstalowany jest PostgreSQL 18,
-   istnieje baza `rcn`,
-   PostGIS jest aktywny,
-   istnieje schemat `uslugi_rcn`,
-   w schemacie znajdują się wymagane tabele,
-   istnieją widoki materializowane `mv_dzialki`, `mv_budynki` i
    `mv_lokale`,
-   istnieje użytkownik `ms_rcn`,
-   użytkownik `ms_rcn` ma `CONNECT` do bazy `rcn`,
-   użytkownik `ms_rcn` ma `USAGE` do schematu `uslugi_rcn`,
-   użytkownik `ms_rcn` ma `SELECT` do wymaganych widoków
    materializowanych,
-   PostgreSQL nasłuchuje na adresie odpowiednim dla przyjętej
    konfiguracji MapServera.

Jeżeli wszystkie powyższe testy zakończyły się prawidłowo, **Etap 1 ---
instalacja i przygotowanie bazy danych RCN --- został zakończony**.

Możesz przejść do **Etapu 2 --- instalacji i konfiguracji aplikacji RCN
Importer**.




## 12. Przydatne polecenia administracyjne PostgreSQL

Poniższe polecenia nie są częścią standardowego procesu instalacji. Mogą
być wykorzystywane przez administratora podczas późniejszej eksploatacji
środowiska RCN, prac konfiguracyjnych oraz diagnostyki PostgreSQL.

### 12.1. Sprawdzenie listy klastrów PostgreSQL

``` bash
pg_lsclusters
```

Polecenie wyświetla klastry PostgreSQL dostępne na serwerze wraz z ich
wersją, nazwą, portem, stanem oraz lokalizacją danych.

Dla przygotowanego środowiska powinien być widoczny klaster `18/main`.

### 12.2. Uruchomienie klastra PostgreSQL

``` bash
sudo pg_ctlcluster 18 main start
```

Uruchamia klaster PostgreSQL `18/main`.

Polecenia użyj, jeżeli klaster został wcześniej zatrzymany lub nie
uruchomił się automatycznie.

### 12.3. Zatrzymanie klastra PostgreSQL

``` bash
sudo pg_ctlcluster 18 main stop
```

Zatrzymuje klaster PostgreSQL `18/main` w kontrolowany sposób.

> **Uwaga**
>
> Przed zatrzymaniem PostgreSQL upewnij się, że aplikacja RCN Importer,
> MapServer ani inne systemy nie wykonują w tym czasie operacji na bazie
> danych.

### 12.4. Restart klastra PostgreSQL

``` bash
sudo pg_ctlcluster 18 main restart
```

Zatrzymuje, a następnie ponownie uruchamia klaster PostgreSQL `18/main`.

Restart może być wymagany po zmianie parametrów PostgreSQL, których nie
można zastosować przez samo przeładowanie konfiguracji. Dotyczy to m.in.
zmiany parametru `listen_addresses`.

### 12.5. Przeładowanie konfiguracji PostgreSQL

``` bash
sudo pg_ctlcluster 18 main reload
```

Powoduje ponowne wczytanie konfiguracji bez zatrzymywania serwera
PostgreSQL.

Polecenie jest wystarczające m.in. po zmianach w pliku:

``` text
/etc/postgresql/18/main/pg_hba.conf
```

o ile nie zostały jednocześnie zmienione parametry wymagające restartu
klastra.

### 12.6. Sprawdzenie statusu usługi PostgreSQL

``` bash
sudo systemctl status postgresql
```

Wyświetla aktualny stan usługi PostgreSQL zarządzanej przez `systemd`
oraz podstawowe informacje diagnostyczne.

Aby zakończyć podgląd statusu, naciśnij:

``` text
q
```

### 12.7. Połączenie z bazą `rcn`

Aby uruchomić konsolę `psql` jako użytkownik administracyjny `postgres`
i połączyć się z bazą `rcn`, wykonaj:

``` bash
sudo -u postgres /usr/lib/postgresql/18/bin/psql -d rcn
```

Po połączeniu możesz wykonywać polecenia SQL oraz polecenia
administracyjne `psql`.

Aby zakończyć pracę z konsolą:

``` text
\q
```

### 12.8. Sprawdzenie ostatnich komunikatów PostgreSQL

W przypadku problemów z uruchomieniem lub działaniem PostgreSQL sprawdź
komunikaty usługi:

``` bash
sudo journalctl -u postgresql --no-pager -n 100
```

Jeżeli problem dotyczy bezpośrednio klastra PostgreSQL 18, pomocny może
być również jego plik dziennika:

``` bash
sudo tail -n 100 /var/log/postgresql/postgresql-18-main.log
```

------------------------------------------------------------------------

## 13. Ważne informacje

-   skrypty instalacyjne i administracyjne wymagają odpowiednich
    uprawnień systemowych, w tym w określonych przypadkach `sudo`,
-   istniejąca baza `rcn` nie jest usuwana podczas standardowej
    instalacji,
-   istniejące rozszerzenie PostGIS nie jest tworzone ponownie,
-   istniejący schemat `uslugi_rcn` nie jest nadpisywany podczas
    standardowego importu struktury,
-   import struktury SQL wykorzystuje `ON_ERROR_STOP=1`, dzięki czemu
    wykonanie zostaje przerwane w przypadku błędu SQL,
-   użytkownik `postgres` jest użytkownikiem administracyjnym i jest
    wykorzystywany m.in. podczas przygotowania bazy oraz przez aplikację
    RCN Importer zgodnie z jej konfiguracją,
-   użytkownik `ms_rcn` jest przeznaczony dla MapServera i posiada
    ograniczone uprawnienia do odczytu danych z wymaganych widoków
    materializowanych,
-   MapServer może działać na tym samym serwerze co PostgreSQL albo na
    innym serwerze; sposób konfiguracji połączenia zależy od przyjętej
    architektury,
-   jeżeli MapServer działa na innym serwerze, należy odpowiednio
    skonfigurować `postgresql.conf`, `pg_hba.conf` oraz ewentualną
    zaporę sieciową,
-   zdalny dostęp administratora, np. z programu DBeaver, również wymaga
    świadomego dopuszczenia odpowiedniego adresu IP,
-   port PostgreSQL `5432/TCP` nie powinien być udostępniany szerszej
    sieci niż jest to wymagane,
-   operacje RELOAD, usuwania środowiska oraz ponownego pobierania
    repozytorium nie są częścią standardowej pierwszej instalacji,
-   po zakończeniu instalacji jej poprawność należy sprawdzić zgodnie z
    punktem **11. Weryfikacja poprawności instalacji**.

------------------------------------------------------------------------

# 14. Operacje dodatkowe i administracyjne

Poniższe operacje **nie są częścią standardowej pierwszej instalacji
RCN**.

Korzystaj z nich wyłącznie wtedy, gdy świadomie chcesz:

-   ponownie utworzyć bazę danych `rcn`,
-   usunąć środowisko RCN,
-   zaktualizować pliki z repozytorium,
-   usunąć lokalne repozytorium i pobrać je ponownie.

> **Uwaga**
>
> Część operacji opisanych w tym rozdziale powoduje usunięcie danych lub
> lokalnych plików. Przed ich wykonaniem przeczytaj cały opis danego
> punktu i upewnij się, że rozumiesz skutki operacji.

## 14.1. Ponowne utworzenie bazy `rcn` (RELOAD)

> **UWAGA --- OPERACJA DESTRUKCYJNA**
>
> Nie wykonuj tego kroku podczas standardowej instalacji.
>
> Skrypt `04_reload_bazy_rcn.sh` usuwa istniejącą bazę danych `rcn` wraz
> ze wszystkimi znajdującymi się w niej danymi, a następnie tworzy bazę
> ponownie i odtwarza jej strukturę.

Przejdź do katalogu:

``` bash
cd ~/RCN/1-baza-danych
```

Uruchom:

``` bash
./04_reload_bazy_rcn.sh
```

Skrypt:

1.  wymaga potwierdzenia wykonania operacji,
2.  usuwa istniejącą bazę danych `rcn` wraz z jej zawartością,
3.  uruchamia `01_przygotowanie_bazy_rcn.sh`,
4.  uruchamia `02_import_struktury_rcn.sh`,
5.  uruchamia `03_konfiguracja_uzytkownika_mapserver.sh` i ponownie
    nadaje użytkownikowi `ms_rcn` wymagane uprawnienia.

> **WAŻNE**
>
> Operacja powoduje utratę wszystkich danych znajdujących się aktualnie
> w bazie `rcn`.
>
> Jeżeli baza zawiera dane, które mają zostać zachowane, nie uruchamiaj
> skryptu RELOAD bez wcześniejszego wykonania odpowiedniej kopii
> zapasowej.

Rola PostgreSQL `ms_rcn` jest rolą klastra PostgreSQL i nie jest usuwana
przez usunięcie samej bazy `rcn`. Po utworzeniu nowej bazy wymagane
uprawnienia do jej obiektów muszą jednak zostać nadane ponownie. Skrypt
RELOAD wykonuje tę czynność przez ponowne uruchomienie skryptu
konfigurującego użytkownika MapServera.

Po zakończeniu operacji możesz sprawdzić poprawność odtworzonej bazy za
pomocą testów opisanych w punkcie **11. Weryfikacja poprawności
instalacji**.

------------------------------------------------------------------------

## 14.2. Przywrócenie środowiska do stanu przed instalacją RCN

> **UWAGA --- OPERACJA DESTRUKCYJNA**
>
> Poniższej procedury używaj wyłącznie wtedy, gdy świadomie chcesz
> usunąć środowisko RCN i przygotować serwer do ponownej instalacji.

Szczegółowy opis procedury znajduje się w pliku:

``` text
~/RCN/1-baza-danych/cofnij_do_czystego_debiana.md
```

Najpierw zapoznaj się z instrukcją:

``` bash
cat ~/RCN/1-baza-danych/cofnij_do_czystego_debiana.md
```

Następnie przejdź do katalogu:

``` bash
cd ~/RCN/1-baza-danych
```

Jeżeli po zapoznaniu się z instrukcją chcesz wykonać operację, uruchom:

``` bash
./cofnij_do_czystego_debiana.sh
```

> **WAŻNE**
>
> Skrypt usuwa PostgreSQL 18 wraz z jego danymi. Uruchamiaj go wyłącznie
> świadomie i po upewnieniu się, że dane nie są już potrzebne albo
> zostały wcześniej zabezpieczone.

------------------------------------------------------------------------

## 14.3. Aktualizacja plików RCN z repozytorium

Jeżeli lokalne repozytorium `~/RCN` nadal istnieje i chcesz pobrać jego
najnowszą wersję bez usuwania całego katalogu, przejdź do repozytorium:

``` bash
cd ~/RCN
```

Następnie wykonaj:

``` bash
git pull --ff-only
```

Polecenie pobierze zmiany z repozytorium, jeżeli aktualizacja może
zostać wykonana jako `fast-forward`.

> **Uwaga**
>
> Przed aktualizacją upewnij się, że lokalne zmiany w plikach, które
> chcesz zachować, zostały zapisane lub zabezpieczone.
>
> Jeżeli katalog `~/RCN` został wcześniej usunięty, nie możesz wykonać
> `git pull`. W takim przypadku pobierz repozytorium ponownie zgodnie z
> punktem **14.4**.

Po aktualizacji repozytorium, jeżeli pojawiły się nowe pliki `.sh`,
możesz ponownie nadać wszystkim skryptom w repozytorium uprawnienia do
wykonywania:

``` bash
find ~/RCN -type f -name "*.sh" -exec chmod +x {} \;
```

------------------------------------------------------------------------

## 14.4. Usunięcie lokalnego repozytorium i ponowne pobranie

Jeżeli chcesz usunąć lokalną kopię repozytorium RCN i pobrać wszystkie
pliki ponownie, najpierw upewnij się, że katalog `~/RCN` nie zawiera
żadnych lokalnych plików lub zmian, które należy zachować.

> **UWAGA --- OPERACJA DESTRUKCYJNA**
>
> Poniższe polecenie bezpowrotnie usuwa cały katalog `~/RCN` wraz z jego
> zawartością.
>
> Usunięcie katalogu repozytorium nie jest tym samym co usunięcie
> PostgreSQL ani bazy danych `rcn`. Operacja usuwa lokalne pliki
> znajdujące się w `~/RCN`.

Usuń lokalne repozytorium:

``` bash
rm -rf ~/RCN
```

Przejdź do katalogu domowego:

``` bash
cd ~
```

Pobierz ponownie kompletne repozytorium RCN:

``` bash
git clone https://github.com/GlownyUrzadGeodezjiIKartografii/RCN.git
```

Sprawdź zawartość:

``` bash
ls -la ~/RCN
```

Powinny być dostępne co najmniej katalogi:

``` text
1-baza-danych
2-aplikacja-do-ladowania-danych-z-gml
3-konfiguracja-uslugi
```

Po ponownym pobraniu repozytorium nadaj uprawnienia do wykonywania
wszystkim skryptom `.sh`:

``` bash
find ~/RCN -type f -name "*.sh" -exec chmod +x {} \;
```

> **Uwaga**
>
> Samo ponowne pobranie repozytorium **nie oznacza, że należy ponownie
> instalować PostgreSQL ani ponownie tworzyć bazę danych**.
>
> Jeżeli środowisko PostgreSQL i baza `rcn` nadal istnieją i działają
> prawidłowo, nie wykonuj ponownie instalacji tylko dlatego, że
> repozytorium zostało pobrane na nowo.

Jeżeli celem jest wykonanie pełnej instalacji na nowym lub wcześniej
wyczyszczonym serwerze, rozpocznij procedurę od punktu **3. Wymagania i
sprawdzenie systemu**, a następnie wykonuj kolejne punkty instrukcji.

Po zakończeniu instalacji sprawdź jej poprawność zgodnie z punktem **11.
Weryfikacja poprawności instalacji**.
