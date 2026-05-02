# GOAL
Post-install bash script for Arch Linux base (TTY) that sets up Cinnamon (optional) + niri + Noctalia.

User logs in at TTY after Arch base install, runs the script, then reboots into the display manager and selects the Niri session.

# Approach

## Script: install.sh
Single bash script. Phases:
1. Preflight checks (sudo, internet, Arch Linux)
2. yay (AUR helper — builds from AUR if not present)
3. Cinnamon Desktop install (optional — provides DM, PipeWire, polkit, GTK env)
4. Display manager (lightdm — skipped if a DM is already configured)
5. Packages (pacman + yay AUR)
6. Niri session file (write /usr/share/wayland-sessions/niri.desktop if missing)
7. Niri config (append to config.kdl, do not overwrite)
8. Portal config
9. System env (QT_QPA_PLATFORMTHEME)
10. GTK theme autostart
11. Noctalia polkit plugin
12. Banner with post-install instructions

If a display manager is already configured (e.g. SDDM from KDE), lightdm install is skipped entirely — niri.desktop appears as a session in the existing DM.

## To Start niri
Reboot → log in at DM → select **Niri** session from session picker (gear/cog icon).

# Cinnamon
- Installed via `pacman -S cinnamon`
- Provides: lightdm, PipeWire + WirePlumber, polkit agent, gnome-keyring, gnome-menus, GTK env
- Cinnamon session remains available as fallback

# Niri
- In official Arch repos
- Session file: /usr/share/wayland-sessions/niri.desktop — written by script if not present
- Config: append to default config.kdl, never overwrite
- Comment out spawn-at-startup "waybar" if present
- KDL parse errors silently prevent all spawns — always validate after editing

# xwayland-satellite
- Separate package on Arch (not bundled with niri unlike Fedora)
- Spawned via spawn-at-startup in config.kdl

# Noctalia
- Installed via yay (AUR)
- Spawn: `qs -c noctalia-shell` via spawn-at-startup
- Handles: bar, notifications, wallpaper, lock screen, night light, launcher
- External deps: brightnessctl, imagemagick, python, git, cliphist, matugen, cava

# Polkit
- Noctalia polkit plugin — sparse-cloned from noctalia-dev/noctalia-plugins
- Placed in ~/.config/noctalia/plugins/polkit-agent

# Known Issues
- Display output config requires niri running — manual post-install step
- KDL syntax: strings need closing quotes
