ioManager (DietPi / arm64)
==========================

Verteilung als Binary und Debian-Paket (.deb). Quellcode wird nicht mitgeliefert.

RELEASES
--------
GitHub Releases: https://github.com/ehive-dev/iomanager-releases/releases

DOWNLOAD
--------
Mit GitHub CLI (empfohlen):
  # .deb
  gh release download -R ehive-dev/iomanager-releases -p "iomanager_*_arm64.deb" -O iomanager.deb

  # nur Binary
  gh release download -R ehive-dev/iomanager-releases -p "iomanager" -O iomanager && chmod +x iomanager

Ohne gh: Datei direkt von der Releases-Seite herunterladen.

VORAUSSETZUNGEN (Zielsystem)
----------------------------
sudo apt-get update
sudo apt-get install -y gpiod curl

INSTALLATION (.deb)
-------------------
sudo dpkg -i iomanager.deb \
  || (sudo apt-get -f install -y && sudo dpkg -i iomanager.deb)

sudo systemctl daemon-reload
sudo systemctl enable iomanager
sudo systemctl restart iomanager

HEALTH-CHECK
------------
curl -fsS http://127.0.0.1:3000/healthz

START OHNE .deb (NUR BINARY)
----------------------------
# Binary bereitstellen
sudo install -m0755 ./iomanager /usr/local/bin/iomanager

# Start mit ENV-Parametern (Beispielwerte anpassen)
PORT=3000 HOST=0.0.0.0 GPIO_CHIP_DEV=/dev/gpiochip3 GPIO_LINE=4 \
POLL_MS=1000 TREND_FILE=/opt/iomanager/data/trend.json \
RETENTION_DAYS=30 SAMPLES_PER_POLL=5 SAMPLE_SPACING_US=500 DEBUG_TREND=0 \
iomanager

KONFIGURATION (ENV)
-------------------
Beim .deb über /etc/default/iomanager steuerbar. Nach Änderungen:
  sudo systemctl restart iomanager

Parameter (Default → Beschreibung):
  PORT=3000                    → HTTP-Port
  HOST=0.0.0.0                 → Bind-Adresse (z. B. 127.0.0.1 nur lokal)
  GPIO_CHIP_DEV=/dev/gpiochip3 → gpiod Chip-Device (Board-abhängig)
  GPIO_LINE=4                  → GPIO-Line/PIN
  POLL_MS=1000                 → Polling-Intervall in ms (min. 50)
  TREND_FILE=/opt/iomanager/data/trend.json → Trend-Datei
  RETENTION_DAYS=30            → Aufbewahrungszeit (Tage)
  SAMPLES_PER_POLL=5           → Samples pro Poll (Mehrfachmessung)
  SAMPLE_SPACING_US=500        → Abstand zwischen Samples (µs)
  DEBUG_TREND=0                → 1 = zusätzliche Trend-Logs

SERVICE-KOMMANDOS
-----------------
Status:
  sudo systemctl status iomanager --no-pager
Neustart:
  sudo systemctl restart iomanager
Logs:
  sudo journalctl -u iomanager -n 200 --no-pager -o cat

TROUBLESHOOTING (KURZ)
----------------------
- Health schlägt fehl:
  ss -ltnp | grep :3000
  sudo journalctl -u iomanager -n 200 --no-pager -o cat
- gpioget fehlt:
  sudo apt-get install -y gpiod
- Falscher GPIO:
  /etc/default/iomanager anpassen (GPIO_CHIP_DEV / GPIO_LINE), dann Service neu starten.
