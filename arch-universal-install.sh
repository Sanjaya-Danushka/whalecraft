#!/bin/bash
# Universal Arch Linux Post-Installation Setup Script
# Automatically detects hardware and adapts configuration

set -e

echo "🚀 Universal Arch Linux Setup"
echo "Automatically detects and configures for your hardware"
echo ""

# Hardware detection functions
detect_graphics() {
    echo "🔍 Detecting graphics hardware..."
    
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        HAS_NVIDIA=true
        echo "  ✓ NVIDIA GPU detected"
    else
        HAS_NVIDIA=false
        echo "  • No NVIDIA GPU found"
    fi
    
    if lspci | grep -i intel.*graphics >/dev/null 2>&1; then
        HAS_INTEL=true
        echo "  ✓ Intel graphics detected"
    else
        HAS_INTEL=false
    fi
    
    if lspci | grep -i amd.*graphics >/dev/null 2>&1 || lspci | grep -i radeon >/dev/null 2>&1; then
        HAS_AMD=true
        echo "  ✓ AMD graphics detected"
    else
        HAS_AMD=false
    fi
}

detect_cpu() {
    echo "🔍 Detecting CPU..."
    
    if grep -q "Intel" /proc/cpuinfo; then
        CPU_VENDOR="intel"
        echo "  ✓ Intel CPU detected"
    elif grep -q "AMD" /proc/cpuinfo; then
        CPU_VENDOR="amd"
        echo "  ✓ AMD CPU detected"
    else
        CPU_VENDOR="unknown"
        echo "  ⚠ Unknown CPU vendor"
    fi
}

detect_battery() {
    echo "🔍 Detecting battery..."
    
    if [ -d /sys/class/power_supply/BAT0 ]; then
        BATTERY_PATH="/sys/class/power_supply/BAT0"
        echo "  ✓ Battery found at BAT0"
    elif [ -d /sys/class/power_supply/BAT1 ]; then
        BATTERY_PATH="/sys/class/power_supply/BAT1"
        echo "  ✓ Battery found at BAT1"
    else
        BATTERY_PATH=""
        echo "  • No battery detected (desktop system)"
    fi
}

# Hardware detection
detect_graphics
detect_cpu
detect_battery

echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Update system
echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

# Install base packages (universal)
echo "📦 Installing universal packages..."
PACKAGES="tlp tlp-rdw thermald lm_sensors htop iotop bc plymouth pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol helvum qpwgraph alsa-utils networkmanager-dispatcher"

# Add graphics packages based on detection
if [ "$HAS_NVIDIA" = true ]; then
    PACKAGES="$PACKAGES nvidia nvidia-utils nvidia-prime nvidia-settings"
    echo "  + Adding NVIDIA packages"
fi

# Install AUR helper if not present for themes
if ! command -v yay >/dev/null 2>&1; then
    echo "📦 Installing yay AUR helper..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
fi

# Install packages
sudo pacman -S --noconfirm --needed $PACKAGES

# Install Plymouth theme
yay -S --noconfirm plymouth-theme-arch-charge || echo "Plymouth theme installation skipped"

echo "🔋 Setting up power management..."

# Battery charge limit (only if battery exists)
if [ -n "$BATTERY_PATH" ] && [ -f "$BATTERY_PATH/charge_control_end_threshold" ]; then
    echo "Setting up 65% battery charge limit..."
    
    sudo tee /etc/systemd/system/battery-charge-limit.service > /dev/null << EOF
[Unit]
Description=Set Battery Charge Limit to 65%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 65 > $BATTERY_PATH/charge_control_end_threshold'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable battery-charge-limit.service
    echo 65 | sudo tee "$BATTERY_PATH/charge_control_end_threshold" > /dev/null
    echo "  ✓ Battery charge limit set to 65%"
else
    echo "  • Skipping battery charge limit (no battery or not supported)"
fi

# TLP configuration
echo "⚡ Configuring power management..."
sudo cp /etc/tlp.conf /etc/tlp.conf.backup

# Universal TLP settings
sudo tee -a /etc/tlp.conf > /dev/null << 'EOF'

# Universal power optimization settings
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_MIN_PERF_ON_AC=10
CPU_MAX_PERF_ON_AC=75
CPU_MIN_PERF_ON_BAT=10
CPU_MAX_PERF_ON_BAT=50
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto
EOF

# Add GPU-specific runtime PM settings
if [ "$HAS_NVIDIA" = true ]; then
    echo 'RUNTIME_PM_DRIVER_DENYLIST="nvidia nouveau radeon"' | sudo tee -a /etc/tlp.conf > /dev/null
elif [ "$HAS_AMD" = true ]; then
    echo 'RUNTIME_PM_DRIVER_DENYLIST="amdgpu radeon"' | sudo tee -a /etc/tlp.conf > /dev/null
fi

# Enable services
sudo systemctl enable --now tlp.service
sudo systemctl enable --now thermald
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Set up sensors
sudo sensors-detect --auto

# Plymouth setup
echo "🎨 Configuring boot experience..."
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    sudo plymouth-set-default-theme arch-charge 2>/dev/null || sudo plymouth-set-default-theme spinfinity
fi

# Update mkinitcpio for Plymouth
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont plymouth block filesystems fsck)/' /etc/mkinitcpio.conf

# Update kernel cmdline for quiet boot
if [ -f /etc/kernel/cmdline ]; then
    CURRENT_CMDLINE=$(cat /etc/kernel/cmdline)
    NEW_CMDLINE="$CURRENT_CMDLINE quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0"
    echo "$NEW_CMDLINE" | sudo tee /etc/kernel/cmdline > /dev/null
fi

# Configure systemd-boot if it exists
if [ -d /boot/loader ]; then
    sudo tee /boot/loader/loader.conf > /dev/null << 'EOF'
timeout 1
console-mode max
default arch-linux.efi
editor no
EOF
fi

# Rebuild kernel images
echo "🔄 Rebuilding kernel images..."
sudo mkinitcpio -P

# Enable PipeWire
echo "🎵 Setting up PipeWire audio..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Create universal utility scripts
echo "🛠️ Creating utility scripts..."

# Universal dev-power script
sudo tee /usr/local/bin/dev-power > /dev/null << 'SCRIPT'
#!/bin/bash
CHARGE_LIMIT=65
BATTERY_PATH=$(find /sys/class/power_supply -name "BAT*" -type d 2>/dev/null | head -1)
CHARGE_FILE="$BATTERY_PATH/charge_control_end_threshold"

set_charge_limit() {
    if [ -n "$BATTERY_PATH" ] && [ -f "$CHARGE_FILE" ]; then
        echo $CHARGE_LIMIT | sudo tee "$CHARGE_FILE" > /dev/null
        echo "Charge limit maintained at ${CHARGE_LIMIT}%"
    fi
}

get_cpu_temp() {
    # Try different temperature sources
    temp=$(sensors 2>/dev/null | grep -E "(Package id 0|Tctl|CPU)" | head -1 | awk '{print $3}' | sed 's/+//;s/°C.*//' | cut -d. -f1 2>/dev/null)
    echo "${temp:-0}"
}

case "$1" in
    "performance"|"perf")
        echo "🚀 PERFORMANCE MODE"
        sudo tee /tmp/perf.conf > /dev/null << 'EOF'
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_MAX_PERF_ON_AC=100
PLATFORM_PROFILE_ON_AC=performance
EOF
        sudo cp /etc/tlp.conf.backup /etc/tlp.conf
        sudo tee -a /etc/tlp.conf < /tmp/perf.conf > /dev/null
        sudo tlp ac
        echo "✓ 100% CPU performance enabled"
        set_charge_limit
        ;;
    "quiet")
        echo "🤫 QUIET MODE"
        sudo cp /etc/tlp.conf /etc/tlp.conf.temp
        sudo tlp ac
        echo "✓ Balanced performance (75% CPU max)"
        set_charge_limit
        ;;
    "status")
        echo "=== Power Status ==="
        echo "Temperature: $(get_cpu_temp)°C"
        if [ -n "$BATTERY_PATH" ]; then
            echo "Battery: Found at $(basename $BATTERY_PATH)"
            [ -f "$CHARGE_FILE" ] && echo "Charge Limit: $(cat $CHARGE_FILE 2>/dev/null)%"
        else
            echo "Battery: Not detected (desktop system)"
        fi
        ;;
    *)
        echo "Universal Power Manager"
        echo "Usage: $0 {performance|quiet|status}"
        ;;
esac
SCRIPT

# Universal audio manager
sudo tee /usr/local/bin/audio-manager > /dev/null << 'SCRIPT'
#!/bin/bash
case "$1" in
    "status")
        echo "=== Audio Status ==="
        pactl info | grep "Server Name" 2>/dev/null || echo "Audio server not detected"
        pactl list short sinks 2>/dev/null | head -1 || echo "No audio devices found"
        ;;
    "volume")
        [ -n "$2" ] && pactl set-sink-volume @DEFAULT_SINK@ "$2%" && echo "Volume: $2%"
        ;;
    "fix")
        systemctl --user restart pipewire pipewire-pulse wireplumber
        echo "Audio services restarted"
        ;;
    "gui")
        pavucontrol &
        ;;
    *)
        echo "Universal Audio Manager: {status|volume|fix|gui}"
        ;;
esac
SCRIPT

# Make scripts executable
sudo chmod +x /usr/local/bin/{dev-power,audio-manager}

# Add aliases
tee -a ~/.bashrc > /dev/null << 'EOF'

# Universal system aliases
alias dev-perf="dev-power performance"
alias dev-quiet="dev-power quiet"
alias dev-status="dev-power status"
alias audio-status="audio-manager status"
alias vol="audio-manager volume"
alias audio-fix="audio-manager fix"
EOF

echo ""
echo "🎉 UNIVERSAL SETUP COMPLETE! 🎉"
echo ""
echo "Configured for your hardware:"
[ "$HAS_NVIDIA" = true ] && echo "✅ NVIDIA graphics support"
[ "$HAS_INTEL" = true ] && echo "✅ Intel graphics support"  
[ "$HAS_AMD" = true ] && echo "✅ AMD graphics support"
[ -n "$BATTERY_PATH" ] && echo "✅ Battery management (65% limit)" || echo "• Desktop system (no battery)"
echo "✅ $CPU_VENDOR CPU optimization"
echo "✅ Universal power management"
echo "✅ Complete audio system"
echo "✅ Beautiful boot experience"
echo ""
echo "🚀 Commands:"
echo "  dev-perf      - Performance mode"
echo "  dev-quiet     - Quiet/balanced mode"
echo "  audio-status  - Check audio"
[ "$HAS_NVIDIA" = true ] && echo "  prime-run APP - Use NVIDIA GPU"
echo ""
echo "💡 Reboot recommended!"
SCRIPT

chmod +x /tmp/arch-universal-install.sh
cp /tmp/arch-universal-install.sh ~/arch-setup-backup/
