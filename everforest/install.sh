#!/bin/bash
# Lorien Everforest: the GNOME 50/51 desktop on Arch (EndeavourOS, CachyOS), as on the screenshots in the README.
# Run as your user from the GNOME session (not with sudo); sudo asks for the password for the packages.
#   ./install.sh                  everything
#   ./install.sh --no-packages    skip pacman/yay      --no-themes    skip building the GTK theme and icons
#   ./install.sh --yes            no questions
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run it without sudo."; exit 1; }

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
L="$HOME/.local/share"
EXT="$L/gnome-shell/extensions"
BACKUP="$HOME/lorien-backup-$(date +%F)"
packages=true themes=true yes=false
for a in "$@"; do
    case "$a" in
        --no-packages) packages=false ;;
        --no-themes) themes=false ;;
        --yes|-y) yes=true ;;
        -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
        *) echo "Unknown option: $a"; exit 1 ;;
    esac
done
say() { printf '\n\033[1;32m== %s\033[0m\n' "$*"; }
ask() { $yes && return 0; read -rp "$1 [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

[ "${XDG_CURRENT_DESKTOP:-}" = GNOME ] || echo "Note: not a GNOME session; the settings apply the next time you log in to GNOME."
SHELL_MAJOR=$(gnome-shell --version 2>/dev/null | grep -o '[0-9]\+' | head -1 || true)
SHELL_MAJOR=${SHELL_MAJOR:-51}

# ---- 1. packages ----
if $packages; then
    say "Packages"
    PKGS=(gnome-tweaks gnome-shell-extensions ghostty fastfetch starship ttf-jetbrains-mono-nerd adwaita-fonts
          sassc git curl python)
    echo "pacman: ${PKGS[*]}"
    if ask "Install them?"; then sudo pacman -S --needed "${PKGS[@]}"; fi
fi

# ---- 2. backup of what gets replaced ----
say "Backup -> $BACKUP"
mkdir -p "$BACKUP"
dconf dump / > "$BACKUP/dconf-before-everforest.ini"
for f in .config/ghostty/config .config/starship.toml; do
    [ -e "$HOME/$f" ] && { mkdir -p "$BACKUP/$(dirname "$f")"; cp -a "$HOME/$f" "$BACKUP/$f"; }
done
echo "dconf and the old configs are in $BACKUP"

# ---- 3. theme, icons, cursor, fonts ----
if $themes; then
    say "Everforest GTK + GNOME Shell theme (green accent, dark)"
    git clone -q --depth 1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme "$T/everforest"
    ( cd "$T/everforest/themes" && ./install.sh -t green -c dark -l )
    say "Colloid icons, Everforest green folders"
    git clone -q --depth 1 https://github.com/vinceliuice/Colloid-icon-theme "$T/colloid"
    ( cd "$T/colloid" && ./install.sh -s everforest -t green )
fi
say "adw-gtk3 (dark GTK3 apps that match libadwaita) and near-black window colours"
mkdir -p "$L/themes"
curl -sfL https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6.5.tar.xz -o "$T/adw.tar.xz" && tar -xf "$T/adw.tar.xz" -C "$L/themes"
for v in 3.0 4.0; do
    mkdir -p "$HOME/.config/gtk-$v"
    [ -L "$HOME/.config/gtk-$v/gtk.css" ] && rm "$HOME/.config/gtk-$v/gtk.css"   # an older theme's link
    [ -e "$HOME/.config/gtk-$v/gtk.css" ] && cp -a "$HOME/.config/gtk-$v/gtk.css" "$BACKUP/gtk-$v.css"
    cp "$HERE/config/gtk/gtk.css" "$HOME/.config/gtk-$v/gtk.css"
done
say "Bibata Modern Ice cursor"
mkdir -p "$L/icons"
curl -sfL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz -o "$T/bibata.tar.xz"
tar -xf "$T/bibata.tar.xz" -C "$L/icons"
say "Homenaje (the desktop clock font)"
mkdir -p "$L/fonts"
curl -sfL https://raw.githubusercontent.com/google/fonts/main/ofl/homenaje/Homenaje-Regular.ttf -o "$L/fonts/Homenaje-Regular.ttf"
fc-cache -f "$L/fonts" >/dev/null

# ---- 4. GNOME extensions ----
say "GNOME extensions from extensions.gnome.org (GNOME $SHELL_MAJOR)"
mkdir -p "$EXT"
# User Themes, Dash to Dock, Blur my Shell, Just Perfection, System Monitor, Weather O'Clock, Kiwi Menu,
# AppIndicator, Dynamic Music Pill, OSD Volume Number, Color Picker, ArcMenu (the app list on Super+D), GSConnect (KDE Connect for the phone)
for pk in 19 307 3193 3843 6807 5470 8697 615 9334 5461 3396 3628 1319; do
    info=$(curl -sf "https://extensions.gnome.org/extension-info/?pk=$pk&shell_version=$SHELL_MAJOR") || { echo "  ! $pk: no version for GNOME $SHELL_MAJOR"; continue; }
    read -r uuid url < <(python3 -c 'import json,sys;d=json.load(sys.stdin);print(d["uuid"],d["download_url"])' <<<"$info")
    curl -sfL "https://extensions.gnome.org$url" -o "$T/$uuid.zip"
    rm -rf "${EXT:?}/${uuid:?}"; mkdir -p "$EXT/$uuid"; bsdtar -xf "$T/$uuid.zip" -C "$EXT/$uuid"
    [ -d "$EXT/$uuid/schemas" ] && glib-compile-schemas "$EXT/$uuid/schemas"
    echo "  ok $uuid"
done
say "Desktop Widgets (r3nhick, from GitHub)"
git clone -q --depth 1 https://github.com/r3nhick/desktop-widgets "$T/dw"
rm -rf "${EXT:?}/desktop-widgets@r3nhick"; cp -a "$T/dw" "$EXT/desktop-widgets@r3nhick"; rm -rf "$EXT/desktop-widgets@r3nhick/.git"
glib-compile-schemas "$EXT/desktop-widgets@r3nhick/schemas"
say "Lorien float (Super+H, new windows open centred with gaps)"
rm -rf "${EXT:?}/lorien-float@lorien-rice"; cp -a "$HERE/extensions/lorien-float@lorien-rice" "$EXT/"
glib-compile-schemas "$EXT/lorien-float@lorien-rice/schemas"
say "Lorien pills (dark pills behind the top bar icons)"
rm -rf "${EXT:?}/lorien-pills@lorien-rice"; cp -a "$HERE/extensions/lorien-pills@lorien-rice" "$EXT/"
say "Kiwi Menu: white EndeavourOS logo, no blurred shadow"
kiwi_icon=$(python3 -I "$HERE/patches/kiwimenu/apply.py" || true)
say "Dynamic Music Pill: slower scrolling, hidden unless something plays"
python3 -I "$HERE/patches/dynamic-music-pill/apply.py" || true
[ -d "$EXT/isle@zickrian.github.io" ] || echo "Isle (the notch in the middle of the top bar) is not installed: get it from https://github.com/zickrian/isle"

# ---- 5. wallpapers ----
say "Everforest wallpapers -> ~/Pictures/Wallpapers/everforest"
W="$HOME/Pictures/Wallpapers/everforest"; mkdir -p "$W"
base=https://raw.githubusercontent.com/Apeiros-46B/everforest-walls/main
for f in other/car_rain.png nature/fog_forest_1.png nature/mist_forest_1.png nature/green_forest_1.png \
         nature/foggy_valley_1.png nature/lake_trees.jpg nature/forest_stairs.jpg close_up/raindrops_1.png \
         other/japanese_street_shop.png; do
    [ -e "$W/$(basename "$f")" ] || curl -sfL "$base/$f" -o "$W/$(basename "$f")" || echo "  ! $f"
done
python3 -I "$HERE/wallpapers-list.py"

# ---- 6. terminal: Ghostty (Everforest) + Starship (Everforest powerline) + fastfetch (distro logo) ----
say "Ghostty, Starship and fastfetch"
mkdir -p "$HOME/.config/ghostty"
cp "$HERE/config/ghostty/config" "$HOME/.config/ghostty/config"
cp "$HERE/config/starship.toml" "$HOME/.config/starship.toml"
if [ -f "$HOME/.zshrc" ] && ! grep -q 'starship init zsh' "$HOME/.zshrc"; then
    echo 'command -v starship >/dev/null && eval "$(starship init zsh)"' >> "$HOME/.zshrc"
fi
mkdir -p "$HOME/.config/fastfetch"
[ -e "$HOME/.config/fastfetch/config.jsonc" ] && cp -a "$HOME/.config/fastfetch/config.jsonc" "$BACKUP/fastfetch-config.jsonc"
cp "$HERE/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
if [ -f "$HOME/.zshrc" ] && ! grep -q 'fastfetch greeting' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" <<'EOF2'

# fastfetch greeting with the distro logo (Ghostty only, so editor terminals stay quiet)
[[ -o interactive && $TERM_PROGRAM == ghostty ]] && command -v fastfetch >/dev/null && fastfetch
EOF2
fi
if command -v tidal-hifi >/dev/null || [ -d "$HOME/.config/tidal-hifi" ]; then   # TIDAL Hi-Fi: pick "Everforest" in its settings
    mkdir -p "$HOME/.config/tidal-hifi/themes"; cp "$HERE/config/tidal-hifi/Everforest.css" "$HOME/.config/tidal-hifi/themes/"
fi
mkdir -p "$HOME/.config/systemd/user.conf.d"   # logging out waits at most 10 s for apps that ignore it
cp "$HERE/config/systemd/user.conf.d/lorien-timeout.conf" "$HOME/.config/systemd/user.conf.d/"
if [ -x /opt/tuxedo-control-center/tuxedo-control-center ]; then
    mkdir -p "$HOME/.config/autostart"; cp "$HERE/config/autostart/tuxedo-control-center-tray.desktop" "$HOME/.config/autostart/"
fi

# ---- 7. settings ----
say "GNOME settings (theme, dock, top bar, shortcuts, app folders)"
sed "s|@HOME@|$HOME|g" "$HERE/dconf/lorien-gnome.ini" | dconf load /
[ -n "${kiwi_icon:-}" ] && dconf write /org/gnome/shell/extensions/kiwimenu/icon "$kiwi_icon"

if systemctl is-active --quiet firewalld; then   # GSConnect / KDE Connect talks over ports 1714-1764
    say "Firewall: open KDE Connect for the phone"
    sudo firewall-cmd --permanent --add-service=kdeconnect && sudo firewall-cmd --reload || true
fi

say "Done"
echo "Log out and log back in: GNOME loads new extensions only at login."
echo "Shortcuts: Super+Enter Ghostty, Super+D app list, Super+A app grid, Super+F maximize, Super+H float with gaps, Super+Q close,"
echo "           Super+Shift+S screenshot. Your old settings: $BACKUP"
