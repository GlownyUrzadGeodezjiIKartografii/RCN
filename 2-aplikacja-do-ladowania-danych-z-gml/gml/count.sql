SELECT 'Działki' AS obiekt, COUNT(*) AS liczba
FROM uslugi_rcn.dzialka

UNION ALL

SELECT 'Budynki', COUNT(*)
FROM uslugi_rcn.budynek

UNION ALL

SELECT 'Lokale', COUNT(*)
FROM uslugi_rcn.lokal

UNION ALL

SELECT 'Transakcje', COUNT(*)
FROM uslugi_rcn.transakcja;


-- Oczekiwane wyniki kontrolne

-- 1864-1-bazowy.zip
-- Działki:      3361
-- Budynki:      1618
-- Lokale:        765
-- Transakcje:   1696

-- 1864-2-przyrostowy.zip
-- Działki:        19
-- Budynki:         3
-- Lokale:          2
-- Transakcje:      5

-- Razem po imporcie obu plików
-- Działki:      3380
-- Budynki:      1621
-- Lokale:        767
-- Transakcje:   1701
