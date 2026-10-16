#!/usr/bin/env bash
# Install (or reinstall) Tailscale Panel for the current user: the script goes
# to ~/.local/bin, the launcher entry to ~/.local/share/applications and the
# icon to ~/.local/share/icons.
# Safe to run repeatedly; the previous script is kept as a timestamped backup.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin/tailscale-panel"
DESKTOP="$HOME/.local/share/applications/tailscale-panel.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor"
ICON="$ICON_DIR/scalable/apps/tailscale-panel.svg"

echo "==> Checking syntax"
python3 - "$HERE/tailscale-panel" <<'PY'
import ast, sys
ast.parse(open(sys.argv[1]).read(), sys.argv[1])
PY

# The launcher runs with Terminal=false, so a broken interpreter fails silently.
PY_BIN="$(head -1 "$HERE/tailscale-panel" | sed 's|^#!||')"
echo "==> Checking $PY_BIN can import PySide6"
if ! "$PY_BIN" -c 'import PySide6.QtWidgets' 2>/dev/null; then
    echo "error: $PY_BIN is missing or has no PySide6." >&2
    echo "       sudo apt install python3-pyside6.qtwidgets" >&2
    exit 1
fi

mkdir -p "$(dirname "$BIN")" "$(dirname "$DESKTOP")" "$(dirname "$ICON")"
if [[ -f "$BIN" ]] && ! cmp -s "$HERE/tailscale-panel" "$BIN"; then
    cp -p "$BIN" "$BIN.bak.$(date +%Y%m%d-%H%M%S)"
fi

echo "==> Installing $BIN"
install -m 755 "$HERE/tailscale-panel" "$BIN"

echo "==> Installing $ICON"
install -m 644 "$HERE/tailscale-panel.svg" "$ICON"
# Refresh the cache only where one exists; a stale one would hide the icon.
if [[ -f "$ICON_DIR/icon-theme.cache" ]] && command -v gtk-update-icon-cache >/dev/null; then
    # -t: the per-user hicolor has no index.theme of its own.
    gtk-update-icon-cache -q -t "$ICON_DIR" || true
fi

echo "==> Installing $DESKTOP"
sed "s|@BIN@|$BIN|" "$HERE/tailscale-panel.desktop" > "$DESKTOP"
command -v update-desktop-database >/dev/null && \
    update-desktop-database "$(dirname "$DESKTOP")" 2>/dev/null || true

echo
echo "Installed. Quit any running panel (tray icon -> Quit) and relaunch it."
