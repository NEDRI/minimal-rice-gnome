# endri-lp-rice

My desktop on a TUXEDO laptop with EndeavourOS: **GNOME 50/51**, near-black and minimal, with an island in the top bar, floating windows and a keyboard-first workflow. An older GNOME version is kept further down; the **KDE Plasma 6** look lives in its own repository, [minimal-rice-kde](https://github.com/NEDRI/minimal-rice-kde).

## The GNOME desktop (current)

Everything in [`everforest/`](everforest/), installed by one script from a GNOME session:

```bash
git clone https://github.com/NEDRI/minimal-rice.git
cd minimal-rice/everforest
./install.sh
```

Then log out and log back in. Options: `--no-packages`, `--no-themes`, `--yes`. Your old GNOME settings are saved to `~/lorien-backup-<date>` first.

**Look**
- Near-black windows: libadwaita and [adw-gtk3](https://github.com/lassekongo83/adw-gtk3) (for GTK3 apps) with darker colours from [`config/gtk/gtk.css`](everforest/config/gtk/gtk.css); the default GNOME Shell theme.
- [Reversal](https://github.com/yeyushengfan258/Reversal-icon-theme) icons (black variant), [Bibata Modern Ice](https://github.com/ful1e5/Bibata_Cursor) cursor, JetBrains Mono Nerd Font.
- Windows slightly see-through over a blurred wallpaper (Blur my Shell, static blur so it does not flicker); Ghostty, Firefox, players and Steam stay opaque.
- Wallpapers: nine from [everforest-walls](https://github.com/Apeiros-46B/everforest-walls) in `~/Pictures/Wallpapers/everforest` and eight from Wallhaven in `~/Pictures/Wallpapers/wallhaven`; the desktop uses GNOME's own dark "Tubes"; every wallpaper on the computer shows up in Settings → Appearance ([`wallpapers-list.py`](everforest/wallpapers-list.py)).

**Top bar**
- The [Isle](https://github.com/zickrian/isle) island in the middle (installed separately): clock, music, notifications, calendar and more.
- See-through dark notches behind the left and right parts (the `lorien-pills` extension in this repo), so the icons stay readable on light wallpapers.
- Left: the Kiwi Menu with a white EndeavourOS logo drawn on the 16 px grid, and the workspace dots. Right: CPU, RAM, network, the tray and the system menu. 24 h clock.
- With a second monitor: the same bar there too ([Multi Monitor Bar](https://extensions.gnome.org/extension/8773/), patched by [`patches/multi-monitors-bar`](everforest/patches/multi-monitors-bar/apply.py) so the workspace dots stay next to ArcMenu and System Monitor values are not cut). There it is solid black, without the tray icons, and Isle's island takes the bar's sizes ([`patches/isle`](everforest/patches/isle/apply.py)).

**Dock and apps**
- Dock at the bottom (Dash to Dock), hidden when a window covers it, with a bar under running apps.
- The Dynamic Music Pill in the dock, only while something plays: title and artist, no lyrics.
- `Super+D`: the app list ([ArcMenu](https://gitlab.com/arcmenu/ArcMenu), Whisker layout, centred): categories on the left, apps as a list, search at the top.
- `Super+A` or the dock button: the app grid, everything on the first page in folders (Internet, Programming, Electronics, Office, Multimedia, Games, System, Customize, Tools).

**Windows and shortcuts**
- New windows open floating in the middle with 16 px gaps (the `lorien-float` extension in this repo).
- `Super+H`: the window goes onto that floating "stage"; pressed again, a smaller window in the middle (60 % × 70 %). Works on maximized windows too. On a monitor without GNOME's top bar the stage starts below the Isle island.
- `Super+F` maximizes (and back), `Super+Q` closes, `Super+Enter` opens Ghostty, `Super+E` a new Files window every time, `Super+Shift+S` a screenshot.
- Window buttons on the right: minimize, maximize, close.

**Terminal**
- Ghostty on #111112 with a neutral palette, a Starship powerline prompt in slate tones, and fastfetch with the small distro logo in every new window.

**Also included**
- [GSConnect](https://github.com/GSConnect/gnome-shell-extension-gsconnect) (KDE Connect for the phone); the installer opens its ports if firewalld runs.
- The same near-black colours in other apps: TIDAL Hi-Fi ([`config/tidal-hifi/Black.css`](everforest/config/tidal-hifi/Black.css), pick "Black" in TIDAL's settings), Discord through Vesktop's custom CSS ([`config/vesktop/quickCss.css`](everforest/config/vesktop/quickCss.css)) VS Code ([`config/vscode/colors.json`](everforest/config/vscode/colors.json): Dark Modern with near-black backgrounds, brighter syntax colours and the Cascadia Code font) and Spotify through [Spicetify](https://spicetify.app) ([`config/spicetify/endri`](everforest/config/spicetify/endri); after a Spotify update run `spicetify backup apply`, after changing the theme `spicetify apply`).
- Logging out waits at most 10 s for apps that ignore it (TUXEDO Control Center otherwise holds the next login for 90 s).
- Desktop Widgets, Weather O'Clock, OSD Volume Number, Color Picker, System Monitor, Just Perfection.

**Spotify and TIDAL launchers** ([`config/applications/`](everforest/config/applications/)): Spotify gets its icon in the dock on Wayland, TIDAL a dark title bar.

**Login screen (GDM):** [`everforest/gdm-setup.sh`](everforest/gdm-setup.sh) gives it the dark look, 24 h clock, cursor and icons, without the distro logo (needs sudo). For the wallpaper, the black top bar and black login fields, use [GDM Settings](https://github.com/gdm-settings/gdm-settings) (`yay -S gdm-settings`): the installer fills in its settings, run [`gdm-theme/build.sh`](everforest/gdm-theme/build.sh), then open GDM Settings and press Apply.

**Coming from KDE?** (For Plasma itself see [minimal-rice-kde](https://github.com/NEDRI/minimal-rice-kde).) [`everforest/migrate/kde-to-gnome.sh`](everforest/migrate/kde-to-gnome.sh) installs GNOME and switches the login screen to GDM; after you log in to GNOME, [`remove-kde.sh`](everforest/migrate/remove-kde.sh) saves your KDE settings and removes Plasma.

**After updates of Kiwi Menu or Dynamic Music Pill** my changes to them are gone; run `python3 everforest/patches/kiwimenu/apply.py` or `python3 everforest/patches/dynamic-music-pill/apply.py`, then log in again.

Names like `lorien-pills`, `lorien-float` and `~/lorien-backup-*` are the folders and IDs from the project's old name; they stay so that existing installs keep working.

The rest of this README describes the earlier GNOME look (`./install.sh` in the repo root).

## What you get (earlier GNOME look)

- The bar extension (`lorien-bar`): a transparent top bar with black pills like the Isle island; when a menu is open, its button fills with the accent colour.
- Isle (the island in the middle of the bar), Dash to Dock, ArcMenu, Vitals, Blur my Shell.
- App folders in the app grid.
- Smaller, dark title bars for Qt and Electron apps.
- Shortcuts: `Super+Q` closes the window, `Super+Enter` opens Konsole, `Super+E` opens Files, `Super+Shift+S` takes a region screenshot, `Super+arrows` tile windows.
- Waywallen: Wallpaper Engine wallpapers on Wayland.
- Accent from the wallpaper: it changes with the wallpaper, and without Wallpaper Engine it takes the colour from the regular wallpaper.
- `updateall` updates everything: pacman and AUR, flatpak, firmware, rust, distrobox, oh-my-zsh, tldr. `updateall --check` only lists what is pending.

## Installation

```bash
git clone https://github.com/NEDRI/minimal-rice.git
cd minimal-rice
./install.sh
```

The installer:
1. Shows the package list and asks before installing (`packages.txt` and `packages-aur.txt`; installs `yay` if you don't have it).
2. Saves a copy of your settings in `~/lorien-backup-<date>`.
3. Builds the title bars; `sudo` will ask for your password.
4. Applies the GNOME settings and the app folders.

When it finishes, **log out and log back in**.

Options: `--yes` (no questions), `--no-packages`, `--no-build`, `--no-apply` (skip that step).

## Wallpaper Engine wallpapers

Waywallen uses the wallpapers from **your own** Steam library: you need a purchased copy of Wallpaper Engine and wallpapers downloaded from the Workshop. Open Waywallen from the system tray, point it to your Steam library and pick a wallpaper.

Without Wallpaper Engine everything works with a regular wallpaper, and the accent takes its colour from it.

## After updates

- **When `yay` updates `qadwaitadecorations-qt6`**, the GNOME title bars go back to the large size. Rebuild them:
  ```bash
  ./install.sh --no-packages --no-apply
  ```

## Uninstalling

```bash
./uninstall.sh
```

Restores your settings from the newest `~/lorien-backup-*` copy and removes the files this rice installed. Packages stay installed.

## Credits

- [zickrian/isle](https://github.com/zickrian/isle), [Waywallen](https://github.com/waywallen/waywallen), [QAdwaitaDecorations](https://github.com/FedoraQt/QAdwaitaDecorations).

License: GPL-3.0-or-later (see `LICENSE`).
