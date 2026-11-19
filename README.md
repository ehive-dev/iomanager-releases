# ioManager Releases

Dieses Repository enthält öffentliche Release-Pakete für ioManager.

## Version 1.1.2

- DI1 und DI2 getrennt anzeigen und abfragen; eigene Verläufe und CSV-Exporte.
- Die alte Abfrage `http://localhost:3000/api/gpio` mit `jq: .value` bleibt DI1.
- DI2 über dieselbe URL mit `jq: .di2` oder über `/api/gpio?input=di2` mit `.value` auslesen.
- Den gespeicherten SmartHub-Skin (hell/dunkel) beim Laden übernehmen. Nach einem Skinwechsel eine bereits geöffnete Ansicht neu laden.
- Lokale Diagrammbibliotheken ohne CDN und mitgelieferte, geprüfte Node.js-24.22.3-Laufzeit für ARM64; keine SmartHub-RC-Abhängigkeit.
- Bestehende Konfiguration in `/etc/default/iomanager` bleibt beim Upgrade erhalten.

API über SmartHub: `/apps/ioManager/api/gpio`. Der Dienst selbst lauscht auf Loopback. Die Eingänge werden im konfigurierten Pollingintervall eingelesen; keine garantierte Erfassung schneller Impulse.

## Kompatibilität

Updates sollen unabhängig von gleichzeitig installierten SmartHub- und App-Versionen möglich bleiben. Bestehende dokumentierte Schnittstellen und Konfigurationen bleiben erhalten; neue Funktionen ergänzen diese. Insbesondere bleibt `.value` dauerhaft DI1. Die eigene geprüfte Laufzeit vermeidet eine Kopplung an die Node.js-Version anderer Apps. Die Unterstützung des Betriebssystems und der ARM64-Hardware bleibt Voraussetzung.

## Schnellstart

Stable installieren oder aktualisieren:

```bash
curl -fsSL https://raw.githubusercontent.com/ehive-dev/iomanager-releases/main/install.sh | sudo bash
```

Pre-Release installieren:

```bash
curl -fsSL https://raw.githubusercontent.com/ehive-dev/iomanager-releases/main/install.sh | sudo bash -s -- --pre
```

Bestimmte Version installieren:

```bash
curl -fsSL https://raw.githubusercontent.com/ehive-dev/iomanager-releases/main/install.sh | sudo bash -s -- --tag v1.1.2
```

## Service

```bash
systemctl status iomanager --no-pager
journalctl -u iomanager -f
```

Health-Check lokal:

```bash
curl http://127.0.0.1:3000/healthz
```

## Lizenz

Die Nutzung ist für private und nicht-kommerzielle Zwecke erlaubt. Kommerzielle Nutzung benötigt eine vorherige schriftliche Zustimmung von ehive. Siehe `LICENSE.txt` und `THIRD_PARTY_NOTICES.txt`.

## Bilder

<img width="433" height="322" alt="ehive_ioManager1" src="https://github.com/user-attachments/assets/77f6c4e8-f4cc-44a7-8d67-9bd0b51c27e5" />
<img width="535" height="370" alt="ehive_ioManager2" src="https://github.com/user-attachments/assets/637ebb98-6b09-4135-bf18-88abfb6940d6" />
