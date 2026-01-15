# Delivery Logistics System - README

**Sustav za upravljanje dostavama i logistikom**

**Autori:** Tin Barbarić, Dino Drčec

---

## Sadržaj

- [Pregled Sustava](#pregled-sustava)
- [Značajke po Fazama](#značajke-po-fazama)
- [Preduvjeti](#preduvjeti)
- [Instalacija i Deployment](#instalacija-i-deployment)
- [Pristup Servisima](#pristup-servisima)
- [Web Sučelje](#web-sučelje)
- [Demo Skripta](#demo-skripta)
- [Arhitektura Sustava](#arhitektura-sustava)
- [Upravljanje Sustavom](#upravljanje-sustavom)
- [Rješavanje Problema](#rješavanje-problema)

---

## Pregled Sustava

Delivery Logistics System je sveobuhvatna platforma za upravljanje dostavama koja objedinjuje upravljanje pošiljkama, optimizaciju ruta kroz mrežu distribucije, real-time GPS praćenje vozila te naprednu analitiku i pretraživanje.

### Procijenjeno Vrijeme Deploya

- **Normalni deploy:** 4-6 minuta
- **S potpunim cleanup-om:** 5-7 minuta
- **Prvo pokretanje (download image-a):** 8-12 minuta

### Minimalni Sistemski Zahtjevi

- **RAM:** 8 GB (preporučeno 16 GB)
- **Disk:** 10 GB slobodnog prostora
- **CPU:** Dual-core procesor (preporučeno quad-core)
- **OS:** Linux (testirano na WSL2/Windows 11), vjerojatno radi i na native Linux okruženju

---

## Značajke po Fazama

### **Faza 1: Upravljanje Pošiljkama**

Osnovna funkcionalnost za kreiranje i upravljanje pošiljkama.

**Mogućnosti:**
- Kreiranje pošiljke s detaljima (pošiljatelj, primatelj, težina, adrese, proizvodi)
- Ažuriranje statusa pošiljke (CREATED, WAREHOUSE, IN_TRANSIT, DELIVERED)
- Pretraživanje pošiljki prema tracking broju
- Load balancing preko nginx poslužitelja

**Tehnologije:**
- **Web Server:** Python Flask (3 instance)
- **Load Balancer:** Nginx
- **Baza Podataka:** MongoDB replica set (1 primary + 2 secondary)

**Odabir MongoDB:** Omogućuje jednostavno modeliranje pošiljki kao dokumenata s varijabilnim listama proizvoda te lakšu horizontalnu skalabilnost.

---

### **Faza 2: Mrežna Optimizacija i Rute**

Dodaje graf bazu podataka za modeliranje logističke mreže i računanje optimalnih ruta.

**Mogućnosti:**
- Prikaz mreže distributivnih centara i skladišta
- Računanje optimalne rute između lokacija
- Vizualizacija povezanosti između pošiljki, vozila i distributivnih centara
- Graf analiza logističke mreže

**Tehnologije:**
- **Graf Baza:** Neo4j (distributivni centri kao čvorovi, rute kao veze)
- **Atributi ruta:** Udaljenost, vrijeme, troškovi

**Odabir Neo4j:** Idealna za modeliranje kompleksne mreže distribucije s mogućnošću brzog računanja najkraćih puteva i optimizacije ruta.

---

### **Faza 3: Real-time Praćenje i Analitika**

Dodaje stream processing, log agregaciju i naprednu analitiku.

**Mogućnosti:**
- Real-time GPS praćenje vozila
- Prikaz trenutnih pozicija vozila na mapi
- Napredna pretraga pošiljki (tracking broj, status, primatelj)
- Vizualizacija ključnih metrika:
  - Broj pošiljki po statusima
  - Prosječno vrijeme dostave
  - Kašnjenja i performanse
- Centralizirano logiranje i analiza

**Tehnologije:**
- **Message Broker:** Redpanda (Kafka-compatible)
- **Log Agregacija:** Fluent Bit
- **Pretraživanje:** OpenSearch
- **Vizualizacija:** OpenSearch Dashboards (Kibana-compatible)
- **GPS Consumer:** Python (Kafka consumer)

---

### **Faza 4: Machine Learning (APVO - Neobavezno)**

Predviđanje procijenjenog vremena dostave korištenjem povijesnih podataka.

**Mogućnosti:**
- Predviđanje ETA (Estimated Time of Arrival)
- Analiza povijesnih podataka
- Model training na temelju:
  - Povijesnih dostava
  - Udaljenosti između lokacija
  - Trenutnih GPS podataka

**Tehnologije:**
- **ML Serving:** TBD
- **Batch Processing:** TBD

---

## Preduvjeti

### Potreban Softver

1. **Docker** (verzija 20.10 ili novija)
   ```bash
   docker --version
   ```

2. **Docker Compose** (verzija 2.0 ili novija)
   ```bash
   docker compose version
   # ili
   docker-compose --version
   ```

3. **Sudo pristup** (potreban za inicijalizaciju Neo4j-a)

### Instalacija Docker-a na WSL2/Ubuntu

```bash
# Ažuriraj paket listu
sudo apt-get update

# Instaliraj Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Dodaj korisnika u docker grupu
sudo usermod -aG docker $USER

# Instaliraj Docker Compose
sudo apt-get install docker-compose-plugin

# Restart terminala ili logout/login
```

---

## Instalacija i Deployment

### 1. Preuzimanje Projekta

```bash
cd ~
git clone <repository-url> delivery-logistics-demo
cd delivery-logistics-demo
```

### 2. Priprema Deploy Skripte

Projekt sadrži dvije verzije deploy skripte:
- **`deploy.sh`** - Hrvatska verzija (preporučeno)
- **`deploy-en.sh`** - Engleska verzija

```bash
cd scripts

# Daj executable permisije
chmod +x ./deploy.sh

# Ili za englesku verziju
chmod +x ./deploy-en.sh
```

### 3. Pokretanje Deploya

```bash
# Pokreni deployment
./deploy.sh
```

### 4. Interaktivni Setup

Skripta će vas voditi kroz proces:

#### **Korak 1: Provjera Preduvjeta**
Automatski provjerava Docker i Docker Compose.

#### **Korak 2: Opcionalni Cleanup**
```
Želite li izvršiti potpuni cleanup prije deploya?
Ovo će obrisati sve kontejnere, mreže i volume-e (svi podaci će biti izgubljeni!).
Preporučeno ako imate problema sa mrežama ili želite fresh start. (Y/n):
```

**Preporuke:**
- **Pritisnite `Y`** za prvi put ili ako imate probleme
- **Pritisnite `n`** za brži restart bez gubitka podataka

#### **Korak 3: Automatski Deployment**

Skripta će automatski:

1. Zaustavljanje postojećih servisa (ako postoje)
2. Pokretanje MongoDB replica set (primary + 2 secondary)
   - Čeka 15 sekundi za stabilizaciju
3. Inicijalizacija MongoDB replica set
   - Konfigurira replikaciju
4. Pokretanje Neo4j graph baze
   - Čeka 20 sekundi za pokretanje
   - **ZAHTIJEVA SUDO LOZINKU** za inicijalizaciju mreže
5. Pokretanje Phase 3 servisa (Kafka, GPS, ELK)
   - Čeka 15 sekundi za Kafka
6. Pokretanje web servisa (Flask + Nginx)

#### **Korak 4: Verifikacija Statusa**

Skripta prikazuje status svih servisa:

```
=== Pregled statusa servisa ===

Faza 2:
NAME                      STATUS              PORTS
phase2_mongo_primary      Up (healthy)        0.0.0.0:27017->27017/tcp
phase2_mongo_secondary1   Up (healthy)        0.0.0.0:27018->27017/tcp
phase2_mongo_secondary2   Up (healthy)        0.0.0.0:27019->27017/tcp
phase2_neo4j              Up (healthy)        0.0.0.0:7474->7474/tcp, 0.0.0.0:7687->7687/tcp
phase2_nginx              Up                  0.0.0.0:80->80/tcp
phase2_opensearch         Up                  0.0.0.0:9200->9200/tcp
phase2_web1               Up                  5000/tcp
phase2_web2               Up                  5000/tcp
phase2_web3               Up                  5000/tcp

Faza 3:
NAME                           STATUS              PORTS
phase3_redpanda                Up                  0.0.0.0:9092->9092/tcp
phase3_location_consumer       Up                  
phase3_fluentbit_v2            Up                  2020/tcp
phase3_opensearch_dashboards   Up                  0.0.0.0:5601->5601/tcp
```

---

## Pristup Servisima

Po završetku deploya, dostupni su sljedeći servisi:

| Servis | URL | Opis | Credentials |
|--------|-----|------|-------------|
| **Web Aplikacija** | http://localhost | Glavno sučelje za upravljanje pošiljkama | - |
| **Neo4j Browser** | http://localhost:7474 | Graf baza - pregled mreže distribucije | user: `neo4j`<br>pass: `deliverypass123` |
| **OpenSearch** | http://localhost:9200 | Search engine API | - |
| **Kibana/Dashboards** | http://localhost:5601 | Vizualizacija metrika i logova | - |

---

## Web Sučelje

Sustav ima intuitivno web sučelje dostupno na **http://localhost** koje omogućava potpuno upravljanje pošiljkama.

### Kreiranje Pošiljki

1. **Navigacija:** Otvorite http://localhost/create
2. **Unos podataka:**
   - Pošiljatelj i primatelj (ime, adresa)
   - Težina pošiljke
   - Proizvodi
   - **Odabir grada** (automatski se koristi za računanje rute)
3. **Optimizacija rute:** 
   - Pri kreiranju, sustav automatski računa optimalnu rutu
   - Možete odabrati atribut po kojem želite optimizaciju:
     - **Udaljenost** - najkraća ruta
     - **Vrijeme** - najbržа ruta
     - **Troškovi** - najjeftinija ruta
4. **Kreiranje:** Pošiljka dobiva jedinstveni tracking broj i spremaju se u MongoDB

### Baza Pošiljaka - CRUD Operacije

Nakon kreiranja, sve pošiljke su dostupne u bazi gdje možete izvršavati:

- **Create (Kreiranje):** Dodavanje novih pošiljaka
- **Read (Čitanje):** Pregled svih pošiljaka i njihovih detalja
- **Update (Ažuriranje):** 
  - Izmjena podataka o pošiljci
  - **Promjena statusa** (CREATED → WAREHOUSE → IN_TRANSIT → DELIVERED)
  - Izmjena rute ili drugih atributa
- **Delete (Brisanje):** Uklanjanje pošiljaka iz sustava

### Real-time Praćenje (IN_TRANSIT Status)

Kada se status pošiljke promijeni u **"IN_TRANSIT"**, aktivira se GPS praćenje:

1. **Automatski start:** Pošiljka kreće na svoju izračunatu rutu
2. **Vizualizacija:** Otvorite http://localhost/map
3. **Praćenje kamiona:**
   - Kamion se prikazuje na interaktivnoj mapi
   - Vozi točnom rutom koja je izračunata pri kreiranju
   - **Skalirano vrijeme:** Simulacija radi 100x brže od stvarnog vremena
   - Real-time ažuriranje pozicije
4. **GPS događaji:** Svaki GPS događaj se šalje kroz Kafka i pohranjuje u OpenSearch

### Pretraživanje i Filtriranje

Sustav omogućava naprednu pretragu pošiljaka prema:
- **Tracking broju:** Pronađi specifičnu pošiljku
- **Statusu:** Filtriraj po trenutnom stanju (IN_TRANSIT, DELIVERED, itd.)
- **Primatelju:** Pretraživanje po imenu primatelja
- **Gradu:** Filtriraj po odredištu

---

## Demo Skripta

Projekt uključuje **`demo.sh`** skriptu koja automatski testira sve funkcionalnosti sustava kroz 38 različitih testova organiziranih po fazama.

### Pokretanje Demo Skripte

```bash
cd scripts
chmod +x ./demo.sh
./demo.sh
```

### Što Demo Skripta Radi

Demo skripta izvršava sveobuhvatno testiranje sustava organizirano u 4 faze plus end-to-end testove:

#### **FAZA 1: Upravljanje Pošiljkama i Load Balancing (7 testova)**

1. **Load Balancer Test (Enhanced):**
   - Šalje 50 HTTP zahtjeva na nginx
   - Analizira distribuciju zahtjeva preko web1, web2, web3
   - Prikazuje postotak distribucije i prosječno vrijeme odgovora
   - Verificira da je load balancing ujednačen (max deviation < 10%)

2. **MongoDB Replica Set Konfiguracija:**
   - Provjerava status svih članova replica seta
   - Verificira 1 PRIMARY + 2 SECONDARY konfiguraciju
   - Prikazuje tablicu sa svim članovima i njihovim statusima

3. **MongoDB Replikacija (Write/Read Separation):**
   - Testira pisanje na PRIMARY node
   - Verificira propagaciju podataka na SECONDARY-1
   - Verificira propagaciju podataka na SECONDARY-2
   - Provjerava logičku konzistentnost podataka preko svih nodova

4. **Read Preference (Demonstracija Read Distribucije):**
   - Kreira test dataset od 10 dokumenata
   - Čita podatke sa svih nodova (PRIMARY i oba SECONDARY)
   - Demonstrira mogućnost distribucije čitanja preko replica seta
   - Verificira identične podatke na svim nodovima

5. **Kreiranje Pošiljke:**
   - Kreira testnu pošiljku preko API-ja
   - Verificira generiranje tracking broja
   - Provjerava izračun rute (udaljenost, vrijeme, trošak)

6. **Ažuriranje Statusa:**
   - Testira prijelaze između statusa
   - IN_WAREHOUSE → IN_TRANSIT → DELIVERED

7. **Tracking Funkcionalnost:**
   - Testira pretraživanje po tracking broju

#### **FAZA 2: Logistička Mreža i Graf Baza (5 testova)**

1. **Neo4j Konekcija:**
   - Provjerava dostupnost Neo4j baze

2. **Mrežni Čvorovi:**
   - Broji Distribution Centers (4)
   - Broji Warehouses (7)

3. **Rute i Relacije:**
   - Verificira postojanje 334 rute u mreži
   - Provjerava dinamičko računanje atributa (distance, time, cost)

4. **Računanje Optimalne Rute:**
   - Testira shortest path algoritam (Zagreb → Rijeka)
   - Verificira funkcionalnost računanja rute

5. **Vizualizacija Mreže:**
   - Provjerava API za statistiku mreže

#### **FAZA 3: Real-time Praćenje i Analitika (7 testova)**

1. **Event Streaming (Kafka/Redpanda):**
   - Provjerava zdravlje Kafka clustera
   - Verificira postojanje 'vehicle-location-events' topica

2. **GPS Event Streaming:**
   - Provjerava status location consumer servisa

3. **Real-time Vehicle Tracking:**
   - Verificira da vehicle simulator radi
   - Prikazuje broj trenutno praćenih vozila

4. **Centralizirano Logiranje (Fluent Bit):**
   - Provjerava da li Fluent Bit radi
   - Verificira procesiranje logova

5. **Indeksiranje (OpenSearch):**
   - Provjerava zdravlje OpenSearch clustera
   - Broji indeksirane pošiljke

6. **Napredna Pretraga:**
   - Testira search API funkcionalnost

7. **Dashboards:**
   - Verificira dostupnost OpenSearch Dashboards na port 5601

#### **FAZA 4: Prediktivna Dostava - Opcionalno (1 test)**

1. **ETA Servis:**
   - Testira predviđanje procijenjenog vremena dostave
   - Koristi heurističke predikcije (ML model je opcionalan)
   - Prikazuje izvor predikcije (heuristic ili ML)

#### **End-to-End Integration Test (1 test)**

1. **Kompletan Životni Ciklus Pošiljke:**
   - Korak 1: Kreiranje pošiljke
   - Korak 2: Postavljanje statusa u IN_TRANSIT
   - Korak 3: Tracking preko API-ja
   - Korak 4: Verificiranje rute i simulacije vozila

### Vizualne Značajke Demo Skripte

- **Tablični prikaz:** Load distribution, replica set members, route attributes
- **Progress bar:** Prikazuje napredak kod testiranja load balancera
- **Grafički prikazi:** Vizualna distribucija zahtjeva po serverima
- **Boje i oznake:** Zelene kvačice za uspjeh, žute za upozorenja
- **Strukturirani output:** Jasno organiziran po fazama s grafikama

### Koristi Demo Skripte

- **Automatska Verifikacija:** Brzo provjeri da li sve komponente rade nakon deploya
- **Regression Testing:** Provjeri da promjene nisu pokvarile postojeću funkcionalnost
- **Demonstracija Mogućnosti:** Pokaži sve značajke sustava u 2-3 minute
- **Debugging Tool:** Identificiraj koja komponenta ne radi ispravno
- **Dokumentacija:** Vidi praktične primjere kako koristiti svaki dio sustava

---

## Arhitektura Sustava

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS / BROWSERS                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  NGINX (LB)    │  ← Load Balancer
                    └────────┬───────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         ┌────────┐     ┌────────┐     ┌────────┐
         │ Web 1  │     │ Web 2  │     │ Web 3  │  ← Flask Apps
         └────┬───┘     └────┬───┘     └────┬───┘
              └──────────────┼──────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌─────────┐
    │ MongoDB │◄───────►│ MongoDB │◄──────►│ MongoDB │
    │ Primary │         │ Second1 │        │ Second2 │
    └─────────┘         └─────────┘        └─────────┘
         ▲
         │                   ┌──────────────┐
         │                   │    Neo4j     │  ← Graph DB
         │                   └──────────────┘
         │
         │              ┌────────────────────────────┐
         └──────────────┤  GPS Location Producer     │
                        └────────────┬───────────────┘
                                     ▼
                             ┌───────────────┐
                             │   Redpanda    │  ← Kafka
                             │   (Kafka)     │
                             └───────┬───────┘
                                     ▼
                        ┌─────────────────────┐
                        │ Location Consumer   │
                        └──────────┬──────────┘
                                   ▼
                         ┌──────────────────┐
                         │   OpenSearch     │  ← Search & Analytics
                         └──────────┬───────┘
                                    │
                           ┌────────┴─────────┐
                           │  Fluent Bit      │  ← Log Aggregation
                           └──────────────────┘
                                    │
                                    ▼
                         ┌──────────────────┐
                         │ OpenSearch       │  ← Visualization
                         │ Dashboards       │
                         └──────────────────┘
```

### Komponente

#### **Load Balancing Layer**
- **Nginx:** Round-robin distribucija zahtjeva na 3 Flask instance

#### **Application Layer**
- **Flask Web Servers (x3):** Python web aplikacije
  - Upravljanje pošiljkama
  - REST API
  - GPS tracking

#### **Data Layer**
- **MongoDB Replica Set:**
  - 1x Primary (port 27017)
  - 2x Secondary (ports 27018, 27019)
  - Automatski failover
  
- **Neo4j Graph Database:**
  - Modeliranje logističke mreže
  - Optimizacija ruta

#### **Streaming Layer**
- **Redpanda (Kafka):** Message broker za GPS događaje
- **Location Consumer:** Python servis za obradu GPS stream-a
- **Fluent Bit:** Log agregacija iz svih kontejnera

#### **Analytics Layer**
- **OpenSearch:** Indeksiranje i pretraživanje
- **OpenSearch Dashboards:** Vizualizacija metrika

---

## Upravljanje Sustavom

### Pregled Logova

#### Svi servisi odjednom (Faza 2)
```bash
docker-compose -f phase2/docker-compose.phase2.yml logs -f
```

#### Svi servisi odjednom (Faza 3)
```bash
docker-compose -f docker-compose.phase3.yml logs -f
```

#### Pojedinačni servisi
```bash
# MongoDB Primary
docker logs -f phase2_mongo_primary

# Neo4j
docker logs -f phase2_neo4j

# Web servisi
docker logs -f phase2_web1
docker logs -f phase2_web2
docker logs -f phase2_web3

# Nginx
docker logs -f phase2_nginx

# Kafka/Redpanda
docker logs -f phase3_redpanda

# GPS Consumer
docker logs -f phase3_location_consumer

# OpenSearch
docker logs -f phase2_opensearch
```

### Zaustavljanje Sustava

#### Zaustavi sve servise (Faza 2)
```bash
cd phase2
docker-compose -f docker-compose.phase2.yml down
```

#### Zaustavi sve servise (Faza 3)
```bash
docker-compose -f docker-compose.phase3.yml down
```

#### Zaustavi SVE i obriši podatke
```bash
cd phase2
docker-compose -f docker-compose.phase2.yml down -v

cd ..
docker-compose -f docker-compose.phase3.yml down -v
```

**PAŽNJA:** `-v` flag briše i volume-e (sve podatke)!

### Ponovno Pokretanje

```bash
# Jednostavno ponovno pokreni deploy skriptu
cd scripts
./deploy.sh

# Odgovori 'n' na cleanup ako želiš zadržati podatke
```

### Provjera Statusa Servisa

```bash
# Faza 2
docker-compose -f phase2/docker-compose.phase2.yml ps

# Faza 3
docker-compose -f docker-compose.phase3.yml ps

# Ili sve Docker kontejnere
docker ps -a
```

### Restart Pojedinačnog Servisa

```bash
# Primjer: restart web1 servisa
docker restart phase2_web1

# Primjer: restart MongoDB primary-a
docker restart phase2_mongo_primary
```

---

## Rješavanje Problema

### Problem: Port već zauzet

**Simptomi:**
```
Error: bind: address already in use
```

**Rješenje:**
```bash
# Pronađi koji proces koristi port (npr. 80)
sudo lsof -i :80

# Zaustavi proces ili promijeni port u docker-compose.yml
```

### Problem: MongoDB replica set se ne inicijalizira

**Simptomi:**
```
Error: Replica set not initialized
```

**Rješenje:**
```bash
# Ručna inicijalizacija
docker exec -it phase2_mongo_primary mongosh

# U mongo shell-u:
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
});

# Provjeri status
rs.status();
```

### Problem: Neo4j ne prihvaća konekcije

**Simptomi:**
```
ServiceUnavailable: WebSocket connection failure
```

**Rješenje:**
```bash
# Čekaj dulje (može trebati do 30-60 sekundi)
docker logs -f phase2_neo4j

# Kada vidiš "Started.", otvori browser
# http://localhost:7474
```

### Problem: Nedostaje sudo pristup za Neo4j init

**Simptomi:**
```
Permission denied: cannot chown neo4j directory
```

**Rješenje:**
```bash
# Ručno promijeni vlasništvo
sudo chown -R $USER:$USER ./phase2/neo4j/

# Ponovno pokreni init
docker exec -i phase2_neo4j cypher-shell -u neo4j -p deliverypass123 \
  < ./phase2/neo4j/import/init-network.cypher
```

### Problem: Kafka/Redpanda se ne pokreće

**Simptomi:**
```
Redpanda startup timeout
```

**Rješenje:**
```bash
# Provjeri logove
docker logs phase3_redpanda

# Restart
docker restart phase3_redpanda

# Pričekaj 20-30 sekundi
```

### Problem: Nedovoljno RAM memorije

**Simptomi:**
```
Cannot allocate memory
Killed
```

**Rješenje:**
```bash
# Provjeri Docker memoriju
docker stats

# Povećaj u Docker Desktop settings:
# Settings → Resources → Memory → 8GB+

# Ili zaustavi nepotrebne servise
```

### Problem: "Network not found" greška

**Simptomi:**
```
Error: network phase2_delivery-network not found
```

**Rješenje:**
```bash
# Potpuni cleanup i ponovno pokretanje
./deploy.sh
# Odgovori 'Y' na cleanup pitanje
```

### Debugging Checklist

Kada nešto ne radi:

1. **Provjeri je li Docker pokrenut:**
   ```bash
   docker ps
   ```

2. **Provjeri logove:**
   ```bash
   docker-compose -f phase2/docker-compose.phase2.yml logs
   ```

3. **Provjeri diskografski prostor:**
   ```bash
   df -h
   ```

4. **Provjeri memoriju:**
   ```bash
   free -h
   docker stats
   ```

5. **Potpuni restart:**
   ```bash
   ./deploy.sh  # Odgovori 'Y' na cleanup
   ```

---

## Kontakt i Podrška

**Autori:**
- Tin Barbarić
- Dino Drčec
---

**Uspješan deployment!**

Sustav je sada spreman za korištenje. Pristupite web aplikaciji na **http://localhost** i započnite s upravljanjem dostavama!