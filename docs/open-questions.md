# Open Questions / Research Gaps

## Display Manager

- Does `cinnamon` package on Arch pull in `lightdm` or a different DM?

## Noctalia First Launch

- Does Noctalia generate its config automatically on first launch?
- Are there env vars that must be set before `qs -c noctalia-shell` starts?

## AUR Packages

- Confirm `matugen` and `adw-gtk3` are still AUR and not in official repos — package locations can change.

## Niri Package (Arch)

- Does the `niri` package on Arch ship `/usr/share/wayland-sessions/niri.desktop`?
  - Script writes it if missing — but if the package ships it, the script will skip and use theirs (check for conflicts)
- Default config.kdl location in the Arch package?

## Noctalia Polkit Plugin

- Does the polkit-agent plugin require any additional config or env vars to activate within Noctalia?
- Confirm plugin is auto-loaded from `~/.config/noctalia/plugins/` on Noctalia start

## honor-xdg-activation-with-invalid-serial

- Is this actually needed for Noctalia app launching to work correctly?
- Currently commented out in config — test with and without

## Qt5 Breeze Style

- KDE6 `breeze` package no longer ships a Qt5 style plugin — no standalone Qt5 Breeze package exists on Arch or AUR
- Qt5 apps in qt5ct are limited to Fusion/Windows built-in styles
- Worth revisiting if a community package appears

## adw-gtk3

- Install is non-fatal — confirm whether failure is a CachyOS-specific mirror/repo issue or a broader package availability problem
