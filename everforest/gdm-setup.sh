#!/bin/bash
# endri-lp-rice: the GDM login screen like the desktop: dark, slate accent, 24 h clock, Bibata cursor,
# Colloid icons, no distro logo, battery percentage, tap to click. Run as yourself; sudo asks for the password.
# Undo: sudo rm /etc/dconf/db/gdm.d/99-lorien && sudo dconf update
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run it without sudo."; exit 1; }

echo "== 1/3 Cursor and icons for the login screen (copied to /usr/share/icons)"
for t in Bibata-Modern-Ice Reversal-black Reversal-black-dark; do   # -dark links into Reversal-black
    [ -d "$HOME/.local/share/icons/$t" ] && sudo cp -a --no-preserve=ownership "$HOME/.local/share/icons/$t" /usr/share/icons/ && echo "   $t"
done

echo "== 2/3 GDM settings"
sudo mkdir -p /etc/dconf/profile /etc/dconf/db/gdm.d
sudo rm -f /etc/dconf/db/gdm.d/90-lorien   # older name; 99 wins over GDM Settings (95)
[ -f /etc/dconf/profile/gdm ] || printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' | sudo tee /etc/dconf/profile/gdm >/dev/null
sudo tee /etc/dconf/db/gdm.d/99-lorien >/dev/null <<'INI'
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
accent-color='slate'
clock-format='24h'
cursor-theme='Bibata-Modern-Ice'
cursor-size=24
icon-theme='Reversal-black-dark'
show-battery-percentage=true
font-name='Adwaita Sans 11'

[org/gnome/login-screen]
logo=''

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
INI

echo "== 3/3 dconf update"
sudo dconf update
echo
echo "Done. Log out to see it (the login screen restarts then)."
