#!/usr/bin/env bash
# Lorien rice installer for Arch / EndeavourOS / CachyOS: the earlier GNOME look (lorien-bar).
# The current GNOME look is in everforest/; the KDE Plasma look moved to minimal-rice-kde.
#
#   ./install.sh                 everything: packages, files, builds, the GNOME look
#   ./install.sh --yes           no questions
#   --no-packages  --no-build  --no-apply   skip that step
#
# Before overwriting anything it saves a copy in ~/lorien-backup-<date>; ./uninstall.sh restores it.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

yes=false packages=true build=true apply=true
while (($#)); do
    case "$1" in
        --gnome) ;;   # kept for old command lines: GNOME is the only desktop here now
        --yes|-y) yes=true ;;
        --no-packages) packages=false ;;
        --no-build) build=false ;;
        --no-apply) apply=false ;;
        -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done
noconfirm=(); $yes && noconfirm=(--noconfirm)

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
ask() { $yes && return 0; read -rp "$1 [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
list() { grep -v '^\s*#' "$1" | tr -s ' \n' '\n' | grep -v '^$'; }

[[ $EUID -ne 0 ]] || { echo "Run this as your normal user, not root (sudo asks for the password when needed)." >&2; exit 1; }
command -v pacman >/dev/null || { echo "This installer is for Arch and its derivatives (pacman not found)." >&2; exit 1; }

# ---------------------------------------------------------------- packages
if $packages; then
    say "Packages"
    mapfile -t repo < <(list "$REPO/packages.txt")
    mapfile -t aur < <(list "$REPO/packages-aur.txt")
    echo "From the repositories: ${repo[*]}"
    echo "From the AUR: ${aur[*]}"
    if ask "Install the missing packages?"; then
        sudo pacman -S --needed "${noconfirm[@]}" "${repo[@]}"
        if ! command -v yay >/dev/null; then
            say "Installing yay (AUR helper)"
            tmp="$(mktemp -d)"
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
            rm -rf "$tmp"
        fi
        yay -S --needed "${noconfirm[@]}" "${aur[@]}"
    fi
fi

# ---------------------------------------------------------------- backup
BACKUP="$HOME/lorien-backup-$(date +%Y%m%d-%H%M%S)"
say "Backup: $BACKUP"
mkdir -p "$BACKUP"
for rel in .config/konsolerc .config/environment.d/20-lorien-decorations.conf .config/autostart/lorien-accent.desktop \
           .config/autostart/waywallen.desktop .local/bin/updateall; do
    [[ -e "$HOME/$rel" ]] && { mkdir -p "$BACKUP/$(dirname "$rel")"; cp -a "$HOME/$rel" "$BACKUP/$rel"; }
done
command -v dconf >/dev/null && dconf dump / > "$BACKUP/dconf.ini" || true

# ---------------------------------------------------------------- files
say "Copying files"
L="$HOME/.local/share"
mkdir -p "$L/lorien-rice" "$HOME/.local/bin" "$L/konsole" "$HOME/.config/autostart" "$HOME/.config/environment.d" \
         "$HOME/.config/lorien-rice" "$L/gnome-shell/extensions"
cp -a "$REPO/scripts/." "$L/lorien-rice/"
cp -a "$REPO/bin/updateall" "$HOME/.local/bin/"
fill() { sed "s|@HOME@|$HOME|g" "$1" > "$2"; }
for f in "$REPO"/konsole/*; do fill "$f" "$L/konsole/$(basename "$f")"; done
fill "$REPO/config/autostart/lorien-accent.desktop.in" "$HOME/.config/autostart/lorien-accent.desktop"
cp "$REPO/config/autostart/waywallen.desktop" "$HOME/.config/autostart/"
rm -rf "$L/gnome-shell/extensions/lorien-bar@lorien-rice"
cp -a "$REPO/gnome/lorien-bar@lorien-rice" "$L/gnome-shell/extensions/"
cp "$REPO/config/environment.d/20-lorien-decorations.conf" "$HOME/.config/environment.d/"

# ---------------------------------------------------------------- builds
if $build; then
    say "Smaller title bars for Qt apps in GNOME (patched qadwaitadecorations)"
    src="$HOME/.local/src/qadwaitadecorations"
    rm -rf "$src"
    git clone --depth 1 https://aur.archlinux.org/qadwaitadecorations.git "$src"
    printf '\n' >> "$src/PKGBUILD"
    cat "$REPO/patches/qadwaitadecorations/prepare.sh" >> "$src/PKGBUILD"
    sed -i 's/^pkgrel=\([0-9]*\)$/pkgrel=\1.1/' "$src/PKGBUILD"
    (cd "$src" && makepkg -sfi "${noconfirm[@]}") || echo "Title bars: the build failed (everything else works)."

    say "GNOME extensions (Dash to Dock, Blur my Shell, Just Perfection, ArcMenu, Isle)"
    "$L/lorien-rice/install-gnome-extensions.sh"   # Dash to Dock, Blur my Shell, Just Perfection, Isle
    "$L/lorien-rice/install-gnome-extensions.sh" arcmenu@arcmenu.com
fi

# ---------------------------------------------------------------- look
if $apply; then
    say "GNOME settings"
    "$L/lorien-rice/make-gnome.sh"
    "$L/lorien-rice/make-gnome-apps.sh"
fi

say "Done"
echo "Backup of your previous settings: $BACKUP (restore it with: $REPO/uninstall.sh)"
echo "Log out and log back in. Wallpaper Engine wallpapers: open Waywallen from the tray and point it to your Steam library."
