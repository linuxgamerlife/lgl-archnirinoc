# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Live hardware testing (additional distros)

---

## [0.0.2] - 2026-05-03

### Added
- Arch-based distro support — script now works on any distro with `pacman` and `ID_LIKE=arch` (CachyOS, EndeavourOS, Manjaro, Garuda, Artix, etc.)
- AUR helper detection — uses existing `yay` or `paru` if present; only installs yay if neither is found
- Preflight disk space check — aborts if less than 10 GB free on `/`
- `pacman -Sc` cache clean before install to free disk space
- Force-resync package databases (`pacman -Syy`) before upgrade to fix stale mirror 404 errors
- `xdg-utils` — required for `xdg-mime` and file association persistence
- `qt5-wayland` — Qt5 Wayland platform plugin; required for qt5ct and Qt5 apps on Wayland
- `qt6-wayland` — Qt6 Wayland platform plugin; required on clean installs without a prior DE
- `nwg-look` — GTK theme configuration tool for non-GNOME Wayland environments
- `xsettingsd` — lightweight XSETTINGS daemon; serves nwg-look theme settings to GTK apps so theming persists across reboots
- `xsettingsd` spawned in niri config block
- `XDG_DATA_DIRS=/usr/local/share:/usr/share` written to `/etc/environment` — ensures portals and app choosers locate `.desktop` files
- `AppChooser=gtk` added to `niri-portals.conf` — routes "Open With" dialog to GTK portal backend; fixes empty app list when gnome-shell is not running
- `update-desktop-database` and `update-mime-database` run after package install
- `applications.menu` symlink created (`gnome-applications.menu` → `applications.menu`) for KDE app discovery via `kbuildsycoca6`
- `AUR_CMD` guard in `install_packages()` — dies with a clear message if AUR helper is unset
- `repair_scripts/fix-portal.sh` — restarts xdg-desktop-portal services
- `repair_scripts/fix-kde-apps.sh` — creates `applications.menu` symlink and rebuilds KDE sycoca cache

### Changed
- `install_yay()` renamed to `ensure_aur_helper()` — detects yay/paru before installing
- Package update split into `pacman -Syy` (force db resync) + `pacman -Su` (upgrade) instead of `pacman -Syu`
- `adw-gtk3` install is now non-fatal — failure warns and continues rather than aborting
- niri config spawn comments expanded with full explanations of what each daemon does and why

### Removed
- `xwayland-satellite` — niri ≥25.08 ships Xwayland support natively; separate package and spawn-at-startup entry removed
- `configure_gtk_theme()` — one-shot autostart for adw-gtk3-dark removed; GTK theming now owned by nwg-look + xsettingsd

---

## [0.0.1] - 2026-05-02

Initial Arch Linux release. Converted from [lgl-fednirinoc](https://github.com/linuxgamerlife/lgl-fednirinoc).

### Added
- `install.sh` — bash install script for Arch Linux base TTY
- `install_yay()` phase — builds and installs yay (AUR helper) from source if not present
- `ask_cinnamon()` — prompts to install Cinnamon Desktop as optional base layer (provides lightdm, PipeWire, polkit, GTK env)
- `ensure_display_manager()` — installs lightdm + lightdm-gtk-greeter only if no display manager is already configured; detects existing DMs (e.g. SDDM from KDE) and leaves them untouched
- `install_packages()` — pacman + yay split: pacman for official repo packages, yay for AUR (`noctalia-shell`, `adw-gtk3`, `matugen`)
- `ensure_niri_session_file()` — writes `/usr/share/wayland-sessions/niri.desktop` if not already present
- `configure_niri()` — copies default config, comments out waybar, appends archnirinoc block (idempotent)
- `configure_portals()` — writes `~/.config/xdg-desktop-portal/niri-portals.conf`
- `configure_system_env()` — writes `QT_QPA_PLATFORMTHEME=qt6ct` to `/etc/environment`
- `configure_gtk_theme()` — one-shot autostart applies adw-gtk3-dark + prefer-dark on first login
- `install_noctalia_polkit()` — sparse-clones polkit-agent plugin, writes plugins.json with it enabled
- Package list: `niri`, `xwayland-satellite`, `alacritty`, `brightnessctl`, `imagemagick`, `python`, `git`, `cava`, `xdg-desktop-portal`, `xdg-desktop-portal-gtk`, `xdg-desktop-portal-gnome`, `qt6ct`, `qt5ct`, `qt6-multimedia-ffmpeg`, `gnome-keyring`, `gnome-menus`, `cliphist`, `papirus-icon-theme`
- AUR packages: `noctalia-shell`, `adw-gtk3`, `matugen`
- `xwayland-satellite` spawned via `spawn-at-startup` in niri config (required on Arch — not built into niri package unlike Fedora)

[0.0.2]: https://github.com/linuxgamerlife/lgl-archnirinoc/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/linuxgamerlife/lgl-archnirinoc/releases/tag/v0.0.1
