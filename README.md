# ioManager Releases

Dieses Repository enthält öffentliche Release-Pakete für ioManager.

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
curl -fsSL https://raw.githubusercontent.com/ehive-dev/iomanager-releases/main/install.sh | sudo bash -s -- --tag v1.0.3
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
