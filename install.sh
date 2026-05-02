#!/bin/bash
# archnirinoc v0.0.1
# Post-install script: Arch Linux base TTY -> Cinnamon (optional) + niri + Noctalia
# Optionally installs Cinnamon Desktop as a base layer for lightdm, PipeWire, and polkit,
# or layers on top of an existing desktop environment.
# Run as your regular user with sudo access.

set -euo pipefail

SCRIPT_USER="${USER}"
SCRIPT_HOME="${HOME}"
NIRI_CONFIG_DIR="${SCRIPT_HOME}/.config/niri"
NIRI_CONFIG="${NIRI_CONFIG_DIR}/config.kdl"
INSTALL_CINNAMON=true

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

info()    { echo "  [INFO] $*"; }
success() { echo "  [ OK ] $*"; }
warn()    { echo "  [WARN] $*"; }
die()     { echo "  [FAIL] $*" >&2; exit 1; }

require_sudo() {
    if ! sudo -v 2>/dev/null; then
        die "sudo access required. Run as a regular user with sudo."
    fi
}

# ─────────────────────────────────────────────
# Cinnamon prompt
# ─────────────────────────────────────────────

ask_cinnamon() {
    echo ""
    echo "  ----------------------------------------------------------------"
    echo "          Cinnamon Desktop"
    echo "  ----------------------------------------------------------------"
    echo "  archnirinoc can install Cinnamon as its base desktop environment."
    echo "  It provides: lightdm, PipeWire, polkit, GTK env, and core deps."
    echo ""
    echo "  Skip this if you already have a desktop environment installed."
    echo "  ----------------------------------------------------------------"
    echo ""
    read -rp "  Install Cinnamon Desktop? [Y/n] " yn_cinnamon
    if [[ "${yn_cinnamon,,}" == "n" ]]; then
        INSTALL_CINNAMON=false
        info "Skipping Cinnamon install — existing DE assumed."
    else
        INSTALL_CINNAMON=true
    fi
}

# ─────────────────────────────────────────────
# Preflight checks
# ─────────────────────────────────────────────

preflight() {
    info "Running preflight checks..."

    require_sudo

    if [[ "${EUID}" -eq 0 ]]; then
        die "Do not run as root. Run as your regular user."
    fi

    if ! ping -c1 -W3 8.8.8.8 &>/dev/null; then
        die "No internet connection detected."
    fi

    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        die "This script is for Arch Linux only."
    fi

    success "Preflight passed. User: ${SCRIPT_USER}, Home: ${SCRIPT_HOME}"
}

# ─────────────────────────────────────────────
# Phase 1: yay (AUR helper)
# ─────────────────────────────────────────────

install_yay() {
    if command -v yay &>/dev/null; then
        info "yay already installed."
        return
    fi

    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git

    TMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "${TMP_DIR}/yay"
    (cd "${TMP_DIR}/yay" && makepkg -si --noconfirm)
    rm -rf "${TMP_DIR}"

    success "yay installed."
}

# ─────────────────────────────────────────────
# Phase 2: Cinnamon Desktop (optional)
# ─────────────────────────────────────────────

install_cinnamon() {
    info "Installing Cinnamon Desktop..."
    sudo pacman -S --needed --noconfirm cinnamon
    success "Cinnamon Desktop installed."
}

# ─────────────────────────────────────────────
# Phase 2b: Display manager (always runs)
# ─────────────────────────────────────────────

ensure_display_manager() {
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        EXISTING_DM=$(basename "$(readlink /etc/systemd/system/display-manager.service)" .service)
        info "Display manager already configured (${EXISTING_DM}) — skipping lightdm install."
        sudo systemctl set-default graphical.target
        return
    fi

    info "No display manager found — installing lightdm and GTK greeter..."

    sudo pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter

    sudo systemctl set-default graphical.target
    success "Default target set to graphical.target."

    sudo systemctl enable lightdm
    success "lightdm enabled."
}

# ─────────────────────────────────────────────
# Phase 3: Packages
# ─────────────────────────────────────────────

install_packages() {
    info "Updating system..."
    sudo pacman -Syu --noconfirm

    info "Installing packages..."

    PACMAN_PACKAGES=(
        # Core compositor
        niri
        xwayland-satellite

        # Terminal
        alacritty

        # Noctalia shell runtime deps
        brightnessctl
        imagemagick
        python
        git
        cava

        # Portals
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome

        # Qt theming
        qt6ct
        qt5ct
        qt6-multimedia-ffmpeg

        # Provided by Cinnamon if installed; explicit for non-Cinnamon installs
        gnome-keyring
        gnome-menus

        # Optional but integrated by Noctalia
        cliphist

        # Icons
        papirus-icon-theme
    )

    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    info "Installing AUR packages..."

    YAY_PACKAGES=(
        noctalia-shell
        adw-gtk3
        matugen
    )

    yay -S --needed --noconfirm "${YAY_PACKAGES[@]}"

    success "Packages installed."
}

# ─────────────────────────────────────────────
# Phase 4: Niri session file
# ─────────────────────────────────────────────

ensure_niri_session_file() {
    info "Checking for niri wayland session file..."

    NIRI_SESSION="/usr/share/wayland-sessions/niri.desktop"

    if [[ -f "${NIRI_SESSION}" ]]; then
        success "niri.desktop already present — lightdm will offer Niri session."
        return
    fi

    warn "niri.desktop not found — writing manually so lightdm can see the session."

    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee "${NIRI_SESSION}" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF

    success "Wrote ${NIRI_SESSION}"
}

# ─────────────────────────────────────────────
# Phase 5: Niri config
# ─────────────────────────────────────────────

configure_niri() {
    info "Configuring niri..."

    mkdir -p "${NIRI_CONFIG_DIR}"

    if [[ ! -f "${NIRI_CONFIG}" ]]; then
        DEFAULT_CONFIG=$(pacman -Ql niri 2>/dev/null | grep "default-config.kdl" | awk '{print $2}' | head -1)
        if [[ -n "${DEFAULT_CONFIG}" && -f "${DEFAULT_CONFIG}" ]]; then
            cp "${DEFAULT_CONFIG}" "${NIRI_CONFIG}"
            info "Copied default config from ${DEFAULT_CONFIG}"
        else
            touch "${NIRI_CONFIG}"
            warn "No default config found in niri package. Created empty config.kdl."
        fi
    else
        info "config.kdl already exists — leaving untouched, appending only."
    fi

    if grep -q '^spawn-at-startup "waybar"' "${NIRI_CONFIG}"; then
        sed -i 's|^spawn-at-startup "waybar"|// spawn-at-startup "waybar"  // disabled: Noctalia replaces waybar|' "${NIRI_CONFIG}"
        success "Commented out waybar spawn."
    else
        info "No active waybar spawn found."
    fi

    if grep -q "# archnirinoc" "${NIRI_CONFIG}"; then
        info "archnirinoc config block already present — skipping append."
        return
    fi

    cat >> "${NIRI_CONFIG}" << 'EOF'

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

// # archnirinoc
EOF

    success "Appended niri config block."
}

# ─────────────────────────────────────────────
# Phase 6: Portal config
# ─────────────────────────────────────────────

configure_portals() {
    info "Writing portal config..."

    PORTAL_CONF="${SCRIPT_HOME}/.config/xdg-desktop-portal/niri-portals.conf"
    mkdir -p "${SCRIPT_HOME}/.config/xdg-desktop-portal"

    if [[ -f "${PORTAL_CONF}" ]]; then
        info "niri-portals.conf already exists — skipping."
        return
    fi

    cat > "${PORTAL_CONF}" << 'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
EOF

    success "Portal config written."
}

# ─────────────────────────────────────────────
# Phase 7: System environment
# ─────────────────────────────────────────────

configure_system_env() {
    info "Writing system environment vars..."

    ENV_FILE="/etc/environment"
    ENV_LINE='QT_QPA_PLATFORMTHEME=qt6ct'

    if grep -q "QT_QPA_PLATFORMTHEME" "${ENV_FILE}" 2>/dev/null; then
        info "QT_QPA_PLATFORMTHEME already set in ${ENV_FILE} — skipping."
    else
        echo "${ENV_LINE}" | sudo tee -a "${ENV_FILE}" > /dev/null
        success "Added ${ENV_LINE} to ${ENV_FILE}"
    fi
}

# ─────────────────────────────────────────────
# Phase 8: GTK theme
# ─────────────────────────────────────────────

configure_gtk_theme() {
    info "Applying GTK theme..."

    AUTOSTART_DIR="${SCRIPT_HOME}/.config/autostart"
    AUTOSTART_FILE="${AUTOSTART_DIR}/archnirinoc-gtk-theme.desktop"

    mkdir -p "${AUTOSTART_DIR}"

    cat > "${AUTOSTART_FILE}" << EOF
[Desktop Entry]
Type=Application
Name=archnirinoc GTK theme setup
Exec=bash -c 'gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark && gsettings set org.gnome.desktop.interface color-scheme prefer-dark && rm -f ${AUTOSTART_FILE}'
X-GNOME-Autostart-enabled=true
EOF

    success "GTK theme autostart registered (runs once on first login)."
}

# ─────────────────────────────────────────────
# Phase 9: Noctalia polkit agent
# ─────────────────────────────────────────────

install_noctalia_polkit() {
    info "Installing Noctalia polkit agent..."

    NOCTALIA_PLUGINS_DIR="${SCRIPT_HOME}/.config/noctalia/plugins"
    POLKIT_DEST="${NOCTALIA_PLUGINS_DIR}/polkit-agent"

    if [[ -d "${POLKIT_DEST}" ]]; then
        info "Noctalia polkit-agent already installed — skipping."
        return
    fi

    mkdir -p "${NOCTALIA_PLUGINS_DIR}"

    TMP_DIR=$(mktemp -d)
    git clone --no-checkout --depth=1 --filter=blob:none \
        https://github.com/noctalia-dev/noctalia-plugins.git "${TMP_DIR}"
    git -C "${TMP_DIR}" sparse-checkout set polkit-agent
    git -C "${TMP_DIR}" checkout

    cp -r "${TMP_DIR}/polkit-agent" "${POLKIT_DEST}"
    rm -rf "${TMP_DIR}"

    success "Noctalia polkit-agent installed to ${POLKIT_DEST}"

    PLUGINS_JSON="${SCRIPT_HOME}/.config/noctalia/plugins.json"
    if [[ ! -f "${PLUGINS_JSON}" ]]; then
        cat > "${PLUGINS_JSON}" << 'EOF'
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
EOF
        success "Noctalia plugins.json written with polkit-agent enabled."
    else
        info "plugins.json already exists — skipping. Enable polkit-agent manually if needed."
    fi
}

# ─────────────────────────────────────────────
# Phase 10: Post-install banner + reboot prompt
# ─────────────────────────────────────────────

display_banner() {
    echo ""
    echo "================================================================"
    echo "  archnirinoc v0.0.1 -- Install Complete"
    echo "================================================================"
    echo ""
    echo "  TO START:"
    echo "    Reboot -> log in via the display manager -> select 'Niri'"
    echo "    from the session menu (gear/cog icon at login screen)."
    echo ""
    echo "  DISPLAY CONFIGURATION (after first login, inside niri):"
    echo "    1. Run: niri msg outputs"
    echo "    2. Note your output name (e.g. eDP-1) and mode"
    echo "       (e.g. 1920x1080@60.000)"
    echo "    3. Edit: ~/.config/niri/config.kdl"
    echo "    4. Find the OUTPUT CONFIGURATION section and uncomment:"
    echo ""
    echo "         output \"YOUR-OUTPUT-NAME\" {"
    echo "             mode \"WIDTHxHEIGHT@REFRESH\""
    echo "             scale 1.0"
    echo "             transform \"normal\""
    echo "         }"
    echo ""
    echo "    5. Restart niri: niri msg action quit"
    echo ""
    echo "  KNOWN ISSUE:"
    echo "    - Noctalia may not appear the first time you run Niri after first boot."
    echo "      Log back out, select Niri again, and it will start correctly."
    echo ""
    echo "================================================================"
    echo ""
    echo "  !! MAKE A NOTE OF THE ABOVE BEFORE REBOOTING !!"
    echo ""
    read -rp "  Reboot now? [y/N] " yn_reboot
    if [[ "${yn_reboot,,}" == "y" ]]; then
        sudo reboot
    else
        echo ""
        echo "  Reboot manually when ready: sudo reboot"
        echo ""
    fi
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    echo ""
    echo "  archnirinoc v0.0.1 -- Arch Linux base -> Cinnamon (optional) + niri + Noctalia"
    echo "  -------------------------------------------------------------------------------"
    echo ""

    ask_cinnamon
    preflight
    install_yay
    if [[ "${INSTALL_CINNAMON}" == "true" ]]; then
        install_cinnamon
    fi
    ensure_display_manager
    install_packages
    ensure_niri_session_file
    configure_niri
    configure_portals
    configure_system_env
    configure_gtk_theme
    install_noctalia_polkit
    display_banner
}

main
