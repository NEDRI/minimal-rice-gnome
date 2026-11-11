#!/bin/bash
# Installs the "endri-lp-rice login" GNOME Shell theme for the login screen: only login-fields.css, which
# GDM Settings adds on top of GNOME's own theme (all its variants, dark included). Then pick
# "endri-lp-rice login" as the shell theme in GDM Settings and press Apply.
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
T="$HOME/.local/share/themes/endri-gdm"
rm -rf "${T:?}/gnome-shell"; mkdir -p "$T/gnome-shell"
cp "$HERE/login-fields.css" "$T/gnome-shell/gnome-shell.css"
printf '[Desktop Entry]\nType=X-GNOME-Metatheme\nName=endri-lp-rice login\n' > "$T/index.theme"
echo "Installed $T. In GDM Settings: Appearance > Shell theme > endri-lp-rice login, then Apply."
