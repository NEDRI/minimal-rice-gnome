#!/bin/bash
# From KDE Plasma to GNOME: installs GNOME and GDM and makes GDM the login screen from the next boot.
# Run as your user (not with sudo); sudo asks for the password. KDE stays until you log in to GNOME and run
# remove-kde.sh from there. Then run ../install.sh in the GNOME session for the Everforest look.
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run it without sudo."; exit 1; }

sudo pacman -S --needed gnome gdm gnome-tweaks gnome-shell-extensions xdg-desktop-portal-gnome
sudo systemctl disable sddm.service 2>/dev/null || true
sudo systemctl enable gdm.service

echo "Done. Reboot and log in to the GNOME session, then run everforest/install.sh there."
