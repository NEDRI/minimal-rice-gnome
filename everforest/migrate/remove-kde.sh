#!/bin/bash
# Removes KDE Plasma (with SDDM, rofi and the KDE apps) once you have moved to GNOME.
# Run as your user from the GNOME session; sudo asks for the password. Your KDE settings are saved first.
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run it without sudo."; exit 1; }
[ "${XDG_CURRENT_DESKTOP:-}" = GNOME ] || { echo "Run it from the GNOME session, not from KDE."; exit 1; }

mkdir -p "$HOME/lorien-backup-$(date +%F)"; B="$HOME/lorien-backup-$(date +%F)/kde-config.tar.gz"
echo "== 1/2 Saving the KDE settings to $B =="
cd "$HOME"
tar -czf "$B" --ignore-failed-read \
    .config/kdeglobals .config/kwinrc .config/kglobalshortcutsrc .config/plasma-org.kde.plasma.desktop-appletsrc \
    .config/plasmashellrc .config/powerdevilrc .config/kscreenlockerrc .config/konsolerc .config/dolphinrc \
    .config/kde-mimeapps.list .config/rofi .config/systemd/user/lorien-launcher.service \
    .local/share/plasma .local/share/kwin .local/share/konsole .local/share/color-schemes 2>/dev/null || true
ls -lh "$B"

echo "== 2/2 Removing the KDE packages =="
list=$(mktemp)
{ pacman -Qqg plasma kde-applications | grep -vx layer-shell-qt   # layer-shell-qt: other Wayland apps may need it
  for p in sddm sddm-kcm eos-breeze-sddm rofi breeze-gtk; do pacman -Qq "$p" >/dev/null 2>&1 && echo "$p"; done
} | sort -u > "$list"
echo "To remove: $(wc -l < "$list") packages (and their dependencies nothing else needs)."
sudo pacman -Rs $(cat "$list")
rm -f "$list"

echo
echo "KDE removed. Your KDE settings: $B"
