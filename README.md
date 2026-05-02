# archnirinoc

A post-install bash script that sets up [niri](https://github.com/niri-wm/niri) + [Noctalia](https://noctalia.dev) on a base Arch Linux install. Optionally installs Cinnamon Desktop as a base layer for lightdm, PipeWire, and polkit — or layers on top of an existing desktop environment.

---

> [!WARNING]
> **Tested on VMs only.**
>
> **VM requirements:** GPU acceleration must be enabled with OpenGL support (e.g. VirtIO GPU + 3D acceleration in QEMU/KVM). Without this niri will not start.
>
> **Terminal:** Alacritty is installed. You will need to install any other apps. Additional app decisions have not been made for you.
>
> **To start after install:** reboot → log in via the display manager. If you installed Cinnamon, select **Niri** from the session menu (gear/cog icon at the login screen). Otherwise Niri will appear as a session in your existing display manager.
>
> **First boot:** Noctalia may not appear the first time you run Niri. Log back out, select Niri again — it will start correctly.

---

## Concept

Arch Linux (base) → run `install.sh` → reboot → DM login → select Niri session

lightdm is installed as the display manager if no DM is already present. If a display manager is already configured (e.g. SDDM from a KDE install), it is left untouched — Niri will appear as a selectable session automatically. Cinnamon Desktop is optional — install it to get a full GTK environment and PipeWire stack, or skip it if you already have a desktop environment installed. Niri + Noctalia sit on top as a selectable DM session.

## Install

Install [Arch Linux](https://archlinux.org/download/) and boot to a TTY. From the TTY:

```bash
sudo pacman -S git
git clone https://github.com/linuxgamerlife/lgl-archnirinoc.git
cd lgl-archnirinoc
chmod +x install.sh
./install.sh
```

## What it does

1. Prompts whether to install Cinnamon Desktop — skip if you already have a DE installed
2. Installs and enables lightdm + lightdm-gtk-greeter if no display manager is already configured
3. Installs yay (AUR helper)
4. Installs Cinnamon Desktop (optional)
5. Ensures display manager is present and enabled
6. Installs niri, Noctalia, and required deps via pacman and yay
7. Ensures `/usr/share/wayland-sessions/niri.desktop` exists so the DM offers the Niri session
8. Appends Noctalia startup config to `~/.config/niri/config.kdl`
9. Writes xdg-portal config
10. Sets `QT_QPA_PLATFORMTHEME=qt6ct` in `/etc/environment` (system-wide, covers polkit dialogs)
11. Registers a one-shot autostart to apply dark mode GTK theme on first login
12. Installs Noctalia polkit agent plugin to `~/.config/noctalia/plugins/polkit-agent`
13. Prints post-install instructions and prompts for reboot

## What Noctalia handles

These are not configured by the script — Noctalia manages them internally:

| Feature | Handler |
|---|---|
| Status bar | Noctalia built-in |
| App launcher | Noctalia built-in |
| Notifications | Noctalia built-in |
| Wallpaper | Noctalia built-in |
| Lock screen | Noctalia built-in |
| Night light | Noctalia NightLightService |
| Polkit | Noctalia polkit plugin (`~/.config/noctalia/plugins/polkit-agent`) |

## After install

Reboot, then at the login screen select the **Niri** session from the session picker (gear/cog icon).

On first login:
- Dark mode GTK theme is applied automatically by a one-shot autostart, then removes itself
- Run `qt6ct` to configure Qt6 app theming and `qt5ct` for Qt5 apps (apply the Noctalia color scheme)
- The Noctalia polkit plugin is pre-enabled in `plugins.json` — if polkit dialogs don't appear, open the Noctalia plugin manager and enable it manually

Display config (run inside niri after first launch):
```bash
niri msg outputs
# Note your output name and mode
# Edit ~/.config/niri/config.kdl — uncomment the OUTPUT CONFIGURATION section
# Then: niri msg action quit
```

## Browser File Picker

The install script configures the GTK portal as the FileChooser handler. If the file picker still doesn't work in Firefox, in `about:config` set `widget.use-xdg-desktop-portal.file-picker` to `0` to use the native GTK file picker as a fallback.

## Removing lightdm for a minimal install

If you want a TTY-only setup after install:

```bash
sudo systemctl disable lightdm
sudo systemctl set-default multi-user.target
sudo pacman -Rs lightdm lightdm-gtk-greeter
```

Then start niri manually from TTY with `niri-session`.

## During Install

When yay builds `noctalia-shell` from the AUR you will see a large number of QML type registration warnings (e.g. `ProxyWindowBase is used as base type but cannot be found`). These are normal build-time output from the quickshell Qt/QML compilation and can be ignored. The build is successful when it reaches `Linking CXX executable src/quickshell`.

## Known Issues

| Issue | Workaround |
|---|---|
| Screencasting — improved in niri 26.04 but portal conflicts can still occur | Restart portals manually |
| Suspend → red screen (niri + GPU bug) | Avoid suspend |
| Display output config requires niri running | Manual step post-install (see After install above) |
| Noctalia polkit plugin not appearing | Enable manually via Noctalia plugin manager |

## Docs

- [`packages.md`](docs/packages.md) — full package list with rationale
- [`niri-config.md`](docs/niri-config.md) — niri config.kdl reference
- [`install-sequence.md`](docs/install-sequence.md) — install phase reference
- [`open-questions.md`](docs/open-questions.md) — unresolved items

## License

[MIT](LICENSE)
