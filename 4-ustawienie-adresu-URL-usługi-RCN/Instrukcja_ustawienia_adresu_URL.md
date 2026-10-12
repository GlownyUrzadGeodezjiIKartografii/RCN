# Instrukcja ustawienia adresu URL usługi RCN

Po uruchomieniu usługi RCN należy zapisać jej adres URL w bazie danych `rcn`, w tabeli `uslugi_rcn.powiat`.

Można to zrobić za pomocą **DBeaver** lub **Bash (Linux)**.

## 1. Ustawienie adresu URL

### Sposób 1 – DBeaver

1. Uruchom DBeaver i połącz się z bazą `rcn`.
2. Otwórz edytor SQL (SQL Editor).
3. Wykonaj polecenie:

```sql
UPDATE uslugi_rcn.powiat
SET serwis_rcn = 'https://rcn.powiat.pl' -- Wpisz adres URL usługi RCN
WHERE teryt = '1864';                    -- Wpisz właściwy kod TERYT
```

### Sposób 2 – Bash (Linux)

1. Połącz się z serwerem PostgreSQL.
2. Uruchom konsolę bazy danych:

```bash
sudo -u postgres psql -d rcn
```

3. Wykonaj to samo polecenie SQL:

```sql
UPDATE uslugi_rcn.powiat
SET serwis_rcn = 'https://rcn.powiat.pl' -- Wpisz adres URL usługi RCN
WHERE teryt = '1864';                    -- Wpisz właściwy kod TERYT
```

4. Zakończ pracę z konsolą PostgreSQL poleceniem `\q`.

**W obu przypadkach** zastąp `ADRES_URL` rzeczywistym adresem usługi RCN, a `1864` właściwym kodem TERYT. W DBeaver zatwierdź transakcję, jeśli automatyczne zatwierdzanie jest wyłączone.

## 2. Odświeżenie widoków

Po zapisaniu adresu wykonaj:

```sql
REFRESH MATERIALIZED VIEW uslugi_rcn.mv_dzialki;
REFRESH MATERIALIZED VIEW uslugi_rcn.mv_budynki;
REFRESH MATERIALIZED VIEW uslugi_rcn.mv_lokale;
REFRESH MATERIALIZED VIEW uslugi_rcn.mv_powiaty;
```

## 3. Sprawdzenie konfiguracji

Sprawdź zapisany adres URL:

```sql
SELECT teryt, serwis_rcn
FROM uslugi_rcn.powiat
WHERE teryt = '1864';                    -- Wpisz właściwy kod TERYT
```

Następnie sprawdź dane w widokach:

```sql
SELECT * FROM uslugi_rcn.mv_dzialki LIMIT 10;
SELECT * FROM uslugi_rcn.mv_budynki LIMIT 10;
SELECT * FROM uslugi_rcn.mv_lokale LIMIT 10;
SELECT * FROM uslugi_rcn.mv_powiaty LIMIT 10;
```

Jeżeli w bazie znajdują się dane powiatu `1864`, sprawdź, czy dla jego obiektów pole `serwis_rcn` zawiera ustawiony adres URL usługi.

**Uwaga:** zapytania z LIMIT 10 wyświetlają maksymalnie 10 rekordów z każdego widoku zmaterializowanego, spośród danych załadowanych do bazy RCN.
