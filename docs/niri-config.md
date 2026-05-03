# Niri Configuration

Config file: `~/.config/niri/config.kdl`

## Display / Output Setup

Run this after first niri launch to enumerate outputs:

```bash
niri msg outputs
```

Output example:
```
Output: eDP-1
  make: "BOE"
  model: "0x0BCA"
  ...
  Modes:
    2560x1600@120.000 (current, preferred)
```

Then add to config.kdl (replace output name and mode with actual values):

```kdl
output "eDP-1" {
    mode "2560x1600@120.000"
    scale 1.5
    transform "normal"
}
```

**Critical — KDL syntax rules (parse errors silently prevent all spawn-at-startup):**
- `mode` value must have closing `"` — `mode "1920x1080@60.000"` not `mode "1920x1080@60.000`
- `position x=0 y=0` not needed for single monitor — omit it
- Always run `niri validate` after editing config. Any parse error = no spawns fire.

> If Noctalia or other spawn-at-startup apps fail to launch, run `niri validate` first — config parse error is the most likely cause.

## Xwayland

niri ≥25.08 ships Xwayland support natively. No separate package or spawn-at-startup entry is needed. `xwayland-satellite` is not installed by this script.

## Noctalia Required Settings

These must be present for Noctalia to work correctly:

```kdl
window-rule {
  geometry-corner-radius 20
  clip-to-geometry true
}

debug {
  honor-xdg-activation-with-invalid-serial
}
```

## Noctalia Wallpaper (choose one)

**Option A — Blurred overview background (recommended):**
```kdl
layer-rule {
  match namespace="^noctalia-overview*"
  place-within-backdrop true
}
```

**Option B — Stationary wallpaper:**
```kdl
layer-rule {
  match namespace="^noctalia-wallpaper*"
  place-within-backdrop true
}

layout {
  background-color "transparent"
}

overview {
  workspace-shadow {
    off
  }
}
```

**Option C — Flat color (simplest):**
```kdl
overview {
  backdrop-color "#26233a"
}
```

## Qt Theming

`QT_QPA_PLATFORMTHEME=qt6ct` is set system-wide in `/etc/environment` by the install script.

After first login, run `qt6ct` to apply the Noctalia color scheme: **Settings → Color Scheme → Templates → enable Qt**.

Qt5 apps use `qt5ct` — both are installed by the script. Run `qt5ct` to configure Qt5 theming separately.

Note: KDE6's `breeze` package no longer ships a Qt5 style plugin. Qt5 apps are limited to the built-in Fusion and Windows styles in qt5ct unless a third-party Qt5 style engine is installed.

Noctalia (Quickshell/QML) is unaffected — styles itself independently.

## GTK Theming

Use `nwg-look` to set GTK theme, icon theme, and fonts. Changes are written to `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`, and the `xsettingsd` config.

`xsettingsd` is spawned at niri startup and serves these settings to GTK apps via the XSETTINGS protocol, ensuring they persist across reboots.

## Dark Mode

**GTK3 apps** — set via nwg-look or gsettings:
```bash
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
```

**GTK4 apps + portal-aware apps** — color-scheme drives it:
```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```

**Qt apps** — configure dark palette in `qt6ct` GUI after first login. Noctalia's own color scheme is the recommended palette.

## Startup Applications

Remove default Waybar entry if present. Noctalia handles: bar, notifications, wallpaper, lock screen, night light — do not spawn these separately.

**Noctalia** — use this exact command (not just `noctalia-shell`):
```kdl
spawn-at-startup "qs" "-c" "noctalia-shell"
```

**Do NOT** also enable `noctalia.service` via systemd if using spawn-at-startup — two instances will launch. Pick one method. spawn-at-startup is simpler; systemd is more robust. Recommended: spawn-at-startup for now.

**polkit** — handled by the Noctalia polkit plugin installed to `~/.config/noctalia/plugins/polkit-agent`. No spawn-at-startup entry needed — Noctalia manages it.

## Portal Config

Create `~/.config/xdg-desktop-portal/niri-portals.conf`:

```ini
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.AppChooser=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
```

`AppChooser=gtk` is required — without it the "Open With" app list is empty because the GNOME portal fallback requires gnome-shell to enumerate installed applications.

> Prevents Nautilus being pulled in as file picker when xdg-desktop-portal-gnome is installed.

**Known issue — screencasting conflict:** `xdg-desktop-portal-gnome` and `xdg-desktop-portal-gtk` can conflict, breaking screencasting. If screencasting fails, manually restart portals:
```bash
systemctl --user stop xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
systemctl --user start xdg-desktop-portal xdg-desktop-portal-gnome
```
This is a known niri issue ([#2399](https://github.com/niri-wm/niri/issues/2399)) — no permanent fix yet.

## File Associations

File associations are stored in `~/.config/mimeapps.list`. For the "Open With" app chooser to show installed applications, the following must all be true:

- `xdg-utils` is installed
- `XDG_DATA_DIRS` includes `/usr/share` (set in `/etc/environment` by the script)
- `update-desktop-database` has been run (done automatically by the script)
- `AppChooser=gtk` is set in `niri-portals.conf`
- For Dolphin specifically: `applications.menu` symlink exists at `/etc/xdg/menus/applications.menu` and `kbuildsycoca6` has been run

If the app list is empty in Dolphin, run `repair_scripts/fix-kde-apps.sh`.
If the app list is empty in GTK apps, run `repair_scripts/fix-portal.sh`.

## ARM / Asahi / kmsro Devices

If display doesn't appear, specify render device explicitly:

```kdl
debug {
  render-drm-device "/dev/dri/renderD128"
}
```

## Session Start

Reboot → log in via display manager → select **Niri** from the session picker (gear/cog icon at the login screen).

## Blur

Added in niri 26.04. No custom build required.

Blur uses the `ext-background-effect` Wayland protocol. Apps that support the protocol request blur themselves. For apps that don't, enable it manually via window or layer rules:

```kdl
window-rule {
    match app-id="^Alacritty$"
    background-effect {
        blur true
    }
}
```

```kdl
layer-rule {
    match namespace="^launcher$"
    background-effect {
        blur true
    }
}
```

Blur requires the window to be semitransparent to be visible. When enabled via a window rule it respects `geometry-corner-radius`.
