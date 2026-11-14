#!/bin/bash
# endri-lp-rice: the GNOME 50/51 desktop on Arch (EndeavourOS, CachyOS), as described in the README.
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
    say "Reversal icons, black variant"
    git clone -q --depth 1 https://github.com/yeyushengfan258/Reversal-icon-theme "$T/reversal"
    "$T/reversal/install.sh" -t black
    for t in Reversal-black Reversal-black-dark; do   # breeze is gone without KDE: fall back to GNOME's icons
        sed -i 's/^Inherits=hicolor,breeze$/Inherits=Adwaita,hicolor,breeze/' "$L/icons/$t/index.theme"
    done
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
say "Qogir Dark cursor"
mkdir -p "$L/icons"
if [ ! -d /usr/share/icons/Qogir-Dark/cursors ]; then   # EndeavourOS ships it (eos-qogir-icons); elsewhere take it from upstream
    curl -sfL https://github.com/vinceliuice/Qogir-icon-theme/archive/refs/heads/master.tar.gz -o "$T/qogir.tar.gz"
    tar -xzf "$T/qogir.tar.gz" -C "$T" Qogir-icon-theme-master/src/cursors/dist-Dark
    rm -rf "$L/icons/Qogir-Dark"
    cp -a "$T/Qogir-icon-theme-master/src/cursors/dist-Dark" "$L/icons/Qogir-Dark"
    sed -i 's/^Name=.*/Name=Qogir-Dark/' "$L/icons/Qogir-Dark/index.theme"
fi
say "Homenaje (the desktop clock font)"
mkdir -p "$L/fonts"
curl -sfL https://raw.githubusercontent.com/google/fonts/main/ofl/homenaje/Homenaje-Regular.ttf -o "$L/fonts/Homenaje-Regular.ttf"
say "Cascadia Code (the VS Code font)"
mkdir -p "$L/fonts/CascadiaCode"
B=https://raw.githubusercontent.com/google/fonts/main/ofl/cascadiacode
curl -sfL "$B/CascadiaCode%5Bwght%5D.ttf" -o "$L/fonts/CascadiaCode/CascadiaCode[wght].ttf" || true
curl -sfL "$B/CascadiaCode-Italic%5Bwght%5D.ttf" -o "$L/fonts/CascadiaCode/CascadiaCode-Italic[wght].ttf" || true
fc-cache -f "$L/fonts" >/dev/null

# ---- 4. GNOME extensions ----
say "GNOME extensions from extensions.gnome.org (GNOME $SHELL_MAJOR)"
mkdir -p "$EXT"
# User Themes, Dash to Dock, Blur my Shell, Just Perfection, System Monitor, Weather O'Clock, Kiwi Menu,
# AppIndicator, Dynamic Music Pill, OSD Volume Number, Color Picker, ArcMenu (the app list on Super+D), GSConnect (KDE Connect for the phone),
# Multi Monitor Bar (the top bar on the other monitors too)
for pk in 19 307 3193 3843 6807 5470 8697 615 9334 5461 3396 3628 1319 8773; do
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
say "Floating windows (Super+H, new windows open centred with gaps)"
rm -rf "${EXT:?}/lorien-float@lorien-rice"; cp -a "$HERE/extensions/lorien-float@lorien-rice" "$EXT/"
glib-compile-schemas "$EXT/lorien-float@lorien-rice/schemas"
say "Top bar notches (dark pills behind the top bar icons)"
rm -rf "${EXT:?}/lorien-pills@lorien-rice"; cp -a "$HERE/extensions/lorien-pills@lorien-rice" "$EXT/"
say "Kiwi Menu: white EndeavourOS logo, no blurred shadow"
kiwi_icon=$(python3 -I "$HERE/patches/kiwimenu/apply.py" || true)
say "Dynamic Music Pill: slower scrolling, hidden unless something plays"
python3 -I "$HERE/patches/dynamic-music-pill/apply.py" || true
say "Multi Monitor Bar: workspace dots next to ArcMenu, uncut System Monitor values"
python3 -I "$HERE/patches/multi-monitors-bar/apply.py" || true
say "Isle: its copy on the other monitors sized like the bar (15 px clock)"
python3 -I "$HERE/patches/isle/apply.py" || true
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
say "Eight more wallpapers from Wallhaven -> ~/Pictures/Wallpapers/wallhaven"
WH="$HOME/Pictures/Wallpapers/wallhaven"; mkdir -p "$WH"
while read -r name file; do
    [ -e "$WH/$name.${file##*.}" ] || curl -sfL "https://w.wallhaven.cc/full/${file:0:2}/wallhaven-$file" -o "$WH/$name.${file##*.}" || echo "  ! $name"
done <<'LIST'
alpine_lake_village 1qqwq3.jpg
fuji_cherry_blossom 5ymyz7.jpg
green_lake_castle 6lwr2x.jpg
foggy_grass 8g8q32.jpg
japanese_gate_night d8wvxo.jpg
cabin_dark_forest ogyeol.jpg
japanese_village_autumn yqvj5g.jpg
boat_red_fog zpoxyj.png
LIST
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
    mkdir -p "$HOME/.config/tidal-hifi/themes"; cp "$HERE/config/tidal-hifi/Everforest.css" "$HERE/config/tidal-hifi/Black.css" "$HOME/.config/tidal-hifi/themes/"
fi
mkdir -p "$HOME/.config/systemd/user.conf.d"   # logging out waits at most 10 s for apps that ignore it
cp "$HERE/config/systemd/user.conf.d/lorien-timeout.conf" "$HOME/.config/systemd/user.conf.d/"
V="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings"   # Discord (Vesktop): near-black custom CSS
if [ -d "$V" ]; then
    [ -s "$V/quickCss.css" ] && cp -a "$V/quickCss.css" "$BACKUP/vesktop-quickCss.css"
    cp "$HERE/config/vesktop/quickCss.css" "$V/quickCss.css"
    python3 -c 'import json,sys;p=sys.argv[1];d=json.load(open(p));d["useQuickCss"]=True;json.dump(d,open(p,"w"),indent=4)' "$V/settings.json" || true
fi
C="$HOME/.config/Code/User/settings.json"   # VS Code: near-black backgrounds, brighter syntax colours, Cascadia Code
if [ -f "$C" ]; then
    cp -a "$C" "$BACKUP/vscode-settings.json"
    python3 -c 'import json,sys;p,c=sys.argv[1:];d=json.load(open(p));d.update(json.load(open(c)));json.dump(d,open(p,"w"),indent=4)' "$C" "$HERE/config/vscode/colors.json" || echo "  ! VS Code settings.json has comments; add config/vscode/colors.json by hand"
fi
if command -v spicetify >/dev/null; then   # Spotify (through Spicetify): the near-black "endri" theme
    mkdir -p "$HOME/.config/spicetify/Themes"; cp -r "$HERE/config/spicetify/endri" "$HOME/.config/spicetify/Themes/"
    spicetify config current_theme endri color_scheme Base >/dev/null && spicetify backup apply >/dev/null 2>&1 || echo "  ! spicetify apply failed; run it again with Spotify closed"
fi
mkdir -p "$HOME/.local/share/applications"   # Spotify: the right icon in the dock on Wayland; TIDAL: dark title bar
command -v spotify-launcher >/dev/null && cp "$HERE/config/applications/spotify-launcher.desktop" "$HOME/.local/share/applications/"
command -v tidal-hifi >/dev/null && cp "$HERE/config/applications/tidal-hifi.desktop" "$HOME/.local/share/applications/"
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

command -v gdm-settings >/dev/null && bash "$HERE/gdm-theme/build.sh" >/dev/null   # login theme for GDM Settings (press Apply there)

say "Done"
echo "Log out and log back in: GNOME loads new extensions only at login."
echo "Shortcuts: Super+Enter Ghostty, Super+D app list, Super+A app grid, Super+F maximize, Super+H float with gaps, Super+Q close,"
echo "           Super+Shift+S screenshot. Your old settings: $BACKUP"
