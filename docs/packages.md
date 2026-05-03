# Package List

## Cinnamon Desktop (optional)

```bash
sudo pacman -S --needed --noconfirm cinnamon
```

Installed if the user opts in. Provides the display manager, PipeWire stack, polkit agent (for Cinnamon session), and core GTK environment. Niri/Noctalia layer on top — Cinnamon session remains available as a fallback.

**Provided by this group (when installed):**
- `lightdm` — display manager / greeter
- `pipewire` + `pipewire-pulse` + `wireplumber` — audio and screen share
- `gnome-keyring` — secret storage
- `gnome-menus` — `gnome-applications.menu` for app discovery
- `mate-polkit` — polkit auth agent for the Cinnamon session; not used by the niri session (Noctalia polkit plugin handles polkit there)

`gnome-keyring` and `gnome-menus` are also explicitly installed in the core package phase so they are present even when Cinnamon is skipped.

## Display Manager (installed if no DM is present)

```bash
sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm
```

If a display manager is already configured (e.g. SDDM from a KDE install), this phase is skipped entirely.

To remove lightdm after install for a minimal TTY-only setup:

```bash
sudo systemctl disable lightdm
sudo systemctl set-default multi-user.target
sudo pacman -Rs lightdm lightdm-gtk-greeter
```

Start niri manually from TTY with `niri-session`.

## AUR Helper

```bash
sudo pacman -S --needed --noconfirm base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm
```

Skipped if `yay` or `paru` is already installed. If an existing AUR helper is found it is used directly — yay is only installed when neither is present.

## Core Install (pacman)

```bash
sudo pacman -S --needed --noconfirm \
  niri \
  alacritty \
  brightnessctl \
  imagemagick \
  python \
  git \
  cava \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  xdg-utils \
  qt6ct \
  qt5ct \
  qt5-wayland \
  qt6-wayland \
  qt6-multimedia-ffmpeg \
  nwg-look \
  xsettingsd \
  gnome-keyring \
  gnome-menus \
  cliphist \
  papirus-icon-theme
```

## AUR Packages

```bash
yay -S --needed --noconfirm \
  noctalia-shell \
  matugen
```

`adw-gtk3` is also attempted but treated as optional — failure is warned and skipped rather than aborting the install.

> Building `noctalia-shell` produces many QML type registration warnings during compilation. These are normal — successful build ends with `Linking CXX executable src/quickshell`.

## Noctalia Polkit Plugin

Installed via sparse-checkout (not a pacman/AUR package):

```bash
git clone --no-checkout --depth=1 --filter=blob:none \
  https://github.com/noctalia-dev/noctalia-plugins.git /tmp/noctalia-plugins
git -C /tmp/noctalia-plugins sparse-checkout set polkit-agent
git -C /tmp/noctalia-plugins checkout
cp -r /tmp/noctalia-plugins/polkit-agent ~/.config/noctalia/plugins/polkit-agent
```

## Package Notes

| Package | Reason |
|---|---|
| `niri` | Wayland compositor |
| `alacritty` | Terminal emulator |
| `brightnessctl` | Screen brightness — Noctalia dep |
| `imagemagick` | Image processing — Noctalia dep |
| `python` | Noctalia dep |
| `git` | Noctalia dep; also used to install Noctalia polkit plugin |
| `cava` | Audio visualizer — Noctalia integration |
| `xdg-desktop-portal-gnome` | Screencasting support |
| `xdg-desktop-portal-gtk` | File picker, app chooser |
| `xdg-utils` | `xdg-mime` and `xdg-open` — required for file association persistence |
| `qt5-wayland` | Qt5 Wayland platform plugin — required for qt5ct and Qt5 apps to run on Wayland |
| `qt6-wayland` | Qt6 Wayland platform plugin — required for Qt6 apps on clean installs |
| `qt6-multimedia-ffmpeg` | Qt6 multimedia backend |
| `nwg-look` | GTK theme configuration tool for non-GNOME Wayland compositors |
| `xsettingsd` | Lightweight XSETTINGS daemon — serves nwg-look theme settings to GTK apps at session start so theming persists across reboots |
| `cliphist` | Clipboard history — Noctalia integrates directly |
| `papirus-icon-theme` | Icon theme |
| `qt6ct` | Qt6 theme config tool |
| `qt5ct` | Qt5 theme config tool |
| `adw-gtk3` (AUR, optional) | GTK theme — install failure is non-fatal |
| `matugen` (AUR) | Material You color generator — Noctalia dep |
| `noctalia-shell` (AUR) | Full desktop shell — bar, launcher, notifications, wallpaper, lock screen |

## Exclusions

- `xwayland-satellite` — niri ≥25.08 ships Xwayland support natively; separate package removed
- `waybar` — not needed, Noctalia provides the bar
- `mako` — not needed, Noctalia handles notifications
- `swaybg` / `wlsunset` — not needed, Noctalia handles wallpaper and night light

## Handled by Noctalia — do not install separately

- Notifications (replaces mako)
- Wallpaper (replaces swaybg)
- Night light (replaces wlsunset)
- Lock screen (Wayland session lock protocol)
- Bar (replaces waybar)
- Launcher
