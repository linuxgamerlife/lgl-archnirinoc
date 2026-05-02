# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Live hardware testing

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

[0.0.1]: https://github.com/linuxgamerlife/lgl-archnirinoc/releases/tag/v0.0.1
