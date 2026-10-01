# MO planiranje (Mašinska obrada)

Web aplikacija: poslovođa MO planira redoslijed po mašinama i kapacitet (h), operateri na mašinama
potvrđuju urađene komade, a aplikacija provjerava da li je to proknjiženo u SAP-u.

## Pokretanje
```
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Početni PIN poslovođe: `1234` (env `BOSS_PIN`). PIN-ovi operatera (1001…) se vide/mijenjaju u Postavke.

## Izvor podataka
- **Excel (zasad):** `data/nalozi.xlsx` (Query 1) i `data/preostala_norma.xlsx` (Query 2); ponovo se čitaju kad se fajl promijeni.
  Mogu se i uploadovati iz Postavki.
- **SAP direktno (MS SQL, SAP B1):** SQL iz Power Query-ja Excela je u `queries/nalozi.sql` i `queries/preostala_norma.sql`.
  Postavi env varijable `SQL_USER` i `SQL_PASSWORD` (host `192.168.0.45`, baza `SBO_GS-TMT_PROD` su default, `SQL_HOST/SQL_PORT/SQL_DB`).
  Čim je `SQL_USER` postavljen, koristi se baza umjesto Excela; osvježavanje svakih `SYNC_INTERVAL_SEC` (300 s).
  Aplikacija mora raditi na računaru/serveru koji vidi `192.168.0.45`. Preporuka: poseban SQL korisnik samo za čitanje.

## Logika
- Aktivna linija = RN je u Query 1 sa statusom `ACTIVE_STATUSES` (default `Otvoren`) **i** postoji u Query 2 sa preostalom količinom, na uključenoj mašini.
- Norma je u minutama; kapacitet (h) se unosi po KW-u (ISO sedmica) → od vrha zeleno dok staje, ostatak crveno; granična linija se nudi za podjelu.
- Operater: količina + "Potvrdi". Unos je `pending` dok `Ostalo Komada` u SAP-u ne padne za tu količinu; nakon `ALERT_AFTER_MIN` (30) poslovođa dobija upozorenje.
