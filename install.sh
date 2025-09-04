#!/usr/bin/env bash
set -euo pipefail
umask 022

# ioManager Installer/Updater (DietPi / arm64)
# - lädt .deb aus GitHub Releases (stable default, optional pre oder bestimmter Tag)
# - installiert/upgraded via dpkg, fixt Abhängigkeiten
# - startet Service neu und prüft /healthz
#
# Nutzung:
#   sudo bash install_iomanager.sh                # neueste STABLE
#   sudo bash install_iomanager.sh --pre         # neueste PRE-RELEASE
#   sudo bash install_iomanager.sh --tag v1.0.12 # bestimmte Version
#   sudo bash install_iomanager.sh --repo owner/repo  # Repo überschreiben (optional)
#
# Optional: GITHUB_TOKEN setzen für höhere API-Limits.

APP_NAME="iomanager"
REPO="${REPO:-ehive-dev/iomanager-releases}"
CHANNEL="stable"     # stable | pre
TAG="${TAG:-}"       # z. B. v1.0.12
ARCH_REQ="arm64"

# ---- args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pre) CHANNEL="pre"; shift ;;
    --stable) CHANNEL="stable"; shift ;;
    --tag) TAG="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: sudo $0 [--pre|--stable] [--tag vX.Y.Z] [--repo owner/repo]"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ---- helpers ----
info(){ printf '\033[1;34m[i]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[✗]\033[0m %s\n' "$*" >&2; }

need_root(){
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    err "Bitte als root ausführen (sudo)."
    exit 1
  fi
}
need_tools(){
  command -v curl >/dev/null || { apt-get update -y; apt-get install -y curl; }
  command -v jq   >/dev/null || { apt-get update -y; apt-get install -y jq; }
  command -v ss   >/dev/null || true
}

api(){
  local url="$1"
  local hdr=(-H "Accept: application/vnd.github+json")
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    hdr+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  curl -fsSL "${hdr[@]}" "$url"
}

get_release_json(){
  if [[ -n "$TAG" ]]; then
    api "https://api.github.com/repos/${REPO}/releases/tags/${TAG}"
  else
    # Liste holen und passende (stable/pre) erste wählen
    api "https://api.github.com/repos/${REPO}/releases?per_page=20" \
      | jq -c "
          if \"${CHANNEL}\" == \"pre\" then
            ([ .[] | select(.draft==false and .prerelease==true) ] | .[0])
          else
            ([ .[] | select(.draft==false and .prerelease==false) ] | .[0])
          end
        "
  fi
}

pick_deb_from_release(){
  # erwartet JSON einer Release
  jq -r --arg arch "$ARCH_REQ" '
    .assets[]?.browser_download_url as $u
    | .assets[]?
    | select(.name | test("^iomanager_.*_" + $arch + "\\.deb$"))
    | .browser_download_url
    ' 2>/dev/null \
    || true
}

installed_version(){
  dpkg-query -W -f='${Version}\n' "$APP_NAME" 2>/dev/null || true
}

get_port(){
  local port="3000"
  if [[ -r "/etc/default/${APP_NAME}" ]]; then
    # shellcheck disable=SC1091
    . "/etc/default/${APP_NAME}" || true
    port="${PORT:-3000}"
  fi
  echo "$port"
}

wait_port(){
  local port="$1"
  command -v ss >/dev/null 2>&1 || return 0
  for i in {1..60}; do ss -ltn 2>/dev/null | grep -q ":${port} " && return 0; sleep 0.5; done
  return 1
}

wait_health(){
  local url="$1"
  for i in {1..30}; do curl -fsS "$url" >/dev/null && return 0; sleep 1; done
  return 1
}

# ---- start ----
need_root
need_tools

# Arch prüfen
ARCH_SYS="$(dpkg --print-architecture 2>/dev/null || echo unknown)"
if [[ "$ARCH_SYS" != "$ARCH_REQ" ]]; then
  warn "Systemarchitektur ist '$ARCH_SYS', Release ist für '$ARCH_REQ'. Abbruch."
  exit 1
fi

# Bereits installierte Version
OLD_VER="$(installed_version || true)"
if [[ -n "$OLD_VER" ]]; then
  info "Installiert: ${APP_NAME} ${OLD_VER}"
else
  info "Keine bestehende ${APP_NAME}-Installation gefunden."
fi

info "Ermittle Release aus ${REPO} (${CHANNEL}${TAG:+, tag=$TAG}) ..."
RELEASE_JSON="$(get_release_json)"
if [[ -z "$RELEASE_JSON" || "$RELEASE_JSON" == "null" ]]; then
  err "Keine passende Release gefunden."
  exit 1
fi

TAG_NAME="$(printf '%s' "$RELEASE_JSON" | jq -r '.tag_name')"
if [[ -z "$TAG" ]]; then TAG="$TAG_NAME"; fi
VER_CLEAN="${TAG#v}"

DEB_URL="$(printf '%s' "$RELEASE_JSON" | pick_deb_from_release)"
if [[ -z "$DEB_URL" ]]; then
  err "Kein .deb Asset für ${ARCH_REQ} in Release ${TAG} gefunden."
  exit 1
fi

TMPDIR="$(mktemp -d -t iomanager-install.XXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT
DEB_FILE="${TMPDIR}/iomanager_${VER_CLEAN}_${ARCH_REQ}.deb"

info "Lade: ${DEB_URL}"
curl -fsSL -o "$DEB_FILE" "$DEB_URL"
ok "Download: $DEB_FILE"

# Sanity: Datei prüfen
if ! dpkg-deb --info "$DEB_FILE" >/dev/null 2>&1; then
  err "Ungültiges .deb (dpkg-deb --info fehlgeschlagen)."
  exit 1
fi

# (Optional) Service vor Upgrade stoppen – dpkg/postinst startet später neu
if systemctl list-units --type=service | grep -q "^${APP_NAME}\.service"; then
  info "Stoppe Service vor Upgrade ..."
  systemctl stop "$APP_NAME" || true
fi

info "Installiere Paket ..."
set +e
dpkg -i "$DEB_FILE"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then
  warn "dpkg meldete Fehler — versuche Abhängigkeitsfix ..."
  apt-get update -y
  apt-get -f install -y
  dpkg -i "$DEB_FILE"
fi
ok "Installiert: ${APP_NAME} ${VER_CLEAN}"

# Service/Health prüfen
systemctl daemon-reload || true
systemctl enable "$APP_NAME" || true
systemctl restart "$APP_NAME" || true

PORT="$(get_port)"
URL="http://127.0.0.1:${PORT}/healthz"
info "Warte auf Port :${PORT} ..."
wait_port "$PORT" || { err "Port ${PORT} lauscht nicht."; journalctl -u "$APP_NAME" -n 200 --no-pager -o cat || true; exit 1; }

info "Prüfe Health ${URL} ..."
wait_health "$URL" || { err "Health-Check fehlgeschlagen."; journalctl -u "$APP_NAME" -n 200 --no-pager -o cat || true; exit 1; }

NEW_VER="$(installed_version || echo "$VER_CLEAN")"
ok "Fertig: ${APP_NAME} ${OLD_VER:+${OLD_VER} → }${NEW_VER} (healthy @ ${URL})"
