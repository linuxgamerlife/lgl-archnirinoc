# Install Sequence

Assumes: Arch Linux base install, boots to TTY, internet connected, logged in as regular user with sudo.

## Cinnamon Prompt

The script prompts before anything is installed. Answer `n` to skip if you already have a desktop environment installed.

## Preflight

- Checks sudo access
- Checks not running as root
- Checks internet connectivity (ping 8.8.8.8)
- Checks `/etc/os-release` for Arch Linux

## Phase 1: yay (AUR helper)

Skipped if yay is already installed. Otherwise:

```bash
sudo pacman -S --needed --noconfirm base-devel git
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si --noconfirm
```

## Phase 2: Cinnamon Desktop (optional)

```bash
sudo pacman -S --needed --noconfirm cinnamon
```

Provides: lightdm, PipeWire + WirePlumber, polkit agent, gnome-keyring, gnome-menus, GTK environment. Niri + Noctalia layer on top as a selectable DM session.

## Phase 2b: Display Manager

If a display manager is already configured (`/etc/systemd/system/display-manager.service` symlink exists), this phase is skipped entirely — the existing DM is left untouched.

If no DM is present:

```bash
sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm
```

## Phase 3: Packages

System update runs first:

```bash
sudo pacman -Syu --noconfirm
```

Then official repo packages:

```bash
sudo pacman -S --needed --noconfirm \
  niri \
  xwayland-satellite \
  alacritty \
  brightnessctl \
  imagemagick \
  python \
  git \
  cava \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  qt6ct \
  qt5ct \
  qt6-multimedia-ffmpeg \
  gnome-keyring \
  gnome-menus \
  cliphist \
  papirus-icon-theme
```

Then AUR packages:

```bash
yay -S --needed --noconfirm \
  noctalia-shell \
  adw-gtk3 \
  matugen
```

> `gnome-keyring` and `gnome-menus` explicitly installed — ensures they are present when Cinnamon is skipped.

> Building `noctalia-shell` from AUR will produce many QML type registration warnings. These are normal — the build is successful when it reaches `Linking CXX executable src/quickshell`.

## Phase 4: Niri Session File

Check for `/usr/share/wayland-sessions/niri.desktop` — write it if not present:

```bash
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF
```

This is what makes the display manager offer Niri as a selectable session.

## Phase 5: Niri Config

1. Create config dir: `mkdir -p ~/.config/niri`
2. Copy default config from niri package if none exists (do not overwrite): `pacman -Ql niri | grep default-config.kdl`
3. Comment out `spawn-at-startup "waybar"` if present
4. Append archnirinoc block (idempotent — skip if already present)

Appended block:
```kdl
// ---------------------------------------------
// archnirinoc -- appended by install.sh v0.0.1
// ---------------------------------------------

// Updates the D-Bus and systemd user environment
spawn-at-startup "dbus-update-activation-environment" "--systemd" "--all"

// Xwayland support
spawn-at-startup "xwayland-satellite"

// Noctalia shell
spawn-at-startup "qs" "-c" "noctalia-shell"

// Uncomment if apps fail to focus when launched via Noctalia
// debug {
//     honor-xdg-activation-with-invalid-serial
// }

// OUTPUT CONFIGURATION
// After first login run: niri msg outputs
// Note your output name and mode, then uncomment and edit below, then:
//   niri msg action quit
//
// output "Virtual-1" {
//     mode "1920x1080@60.000"
//     scale 1.0
//     transform "normal"
// }
```

**KDL rules — parse errors silently prevent all spawns:**
- `mode` string must have closing `"`
- `position x=0 y=0` not needed for single monitor
- Always run `niri validate` after editing config

## Phase 6: Portal Config

```bash
mkdir -p ~/.config/xdg-desktop-portal
cat > ~/.config/xdg-desktop-portal/niri-portals.conf << 'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
EOF
```

## Phase 7: System Environment

```bash
echo 'QT_QPA_PLATFORMTHEME=qt6ct' | sudo tee -a /etc/environment
```

## Phase 8: GTK Theme Autostart

Write `~/.config/autostart/archnirinoc-gtk-theme.desktop` — fires once on first login, sets dark mode via gsettings, then deletes itself.

## Phase 9: Noctalia Polkit Agent

Sparse-clone `polkit-agent` from [noctalia-dev/noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins) into `~/.config/noctalia/plugins/polkit-agent`. Idempotent — skipped if directory already exists.

Also writes `~/.config/noctalia/plugins.json` with the plugin enabled (skipped if the file already exists):

```json
{
    "sources": [
        {
            "enabled": true,
            "name": "Noctalia Plugins",
            "url": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    ],
    "states": {
        "polkit-agent": {
            "enabled": true,
            "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    },
    "version": 2
}
```

> If Noctalia overwrites `plugins.json` on first launch, enable the polkit-agent manually via the Noctalia plugin manager.

## Phase 10: Post-Install Banner

Prints display config instructions and a reboot prompt.

## Post-Install

Reboot → log in via display manager → select **Niri** from the session picker (gear/cog icon).

Display config (first login inside niri):
```bash
niri msg outputs
# Note output name and mode, edit ~/.config/niri/config.kdl
# Uncomment and fill the OUTPUT CONFIGURATION section
```

## Removing lightdm for a minimal install

If you want a TTY-only setup after install:

```bash
sudo systemctl disable lightdm
sudo systemctl set-default multi-user.target
sudo pacman -Rs lightdm lightdm-gtk-greeter
```

Start niri manually from TTY with `niri-session`.

## Known Issues

| Issue | Workaround |
|---|---|
| Screencasting broken | Restart portals: stop all 3, start portal + portal-gnome only |
| Suspend → red screen | Known niri + GPU bug. Avoid suspend. |
| Noctalia not launching | Run `niri validate` — config parse error kills all spawns |
| Two Noctalia instances | Only use spawn-at-startup, not systemd unit |
