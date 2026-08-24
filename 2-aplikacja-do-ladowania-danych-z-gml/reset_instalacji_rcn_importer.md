# RCN Importer --- reset instalacji aplikacji

## Uruchomienie skryptu resetującego

Plik skryptu znajduje się w:

``` text
/home/sszczerba/RCN/reset_instalacji_rcn_importer.sh
```

W terminalu przejdź do katalogu:

``` bash
cd ~/RCN
```

Nadaj skryptowi prawo wykonywania:

``` bash
chmod +x reset_instalacji_rcn_importer.sh
```

Uruchom skrypt:

``` bash
./reset_instalacji_rcn_importer.sh
```

Skrypt poprosi o potwierdzenie. Wpisz dokładnie:

``` text
RESET_RCN_IMPORTER
```

i naciśnij **Enter**.

## Sprawdzenie po wykonaniu resetu

Po zakończeniu możesz sprawdzić, czy katalog aplikacji został usunięty:

``` bash
ls -la /opt/gugik
```

Sprawdź również, czy użytkownik `rcn-importer` został usunięty:

``` bash
id rcn-importer
```

Przy poprawnym resecie polecenie powinno zwrócić informację w rodzaju:

``` text
id: 'rcn-importer': no such user
```

## Ważne

Skrypt usuwa również katalog:

``` text
/home/sszczerba/RCN/rcn-importer
```

Pozostawia natomiast pozostałe pliki znajdujące się w:

``` text
~/RCN
```

czyli m.in. skrypty instalacji PostgreSQL oraz plik SQL.
