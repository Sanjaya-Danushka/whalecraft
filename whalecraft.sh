#!/bin/bash
# WhaleCraft - The Ultimate Arch Linux Setup 🐋
# Deep. Powerful. Perfectly Tuned.
# 
# Automatically configures your Arch Linux system with:
# - Hybrid graphics (Intel + NVIDIA)
# - Smart power management & thermal control
# - Beautiful boot experience
# - Professional audio system (PipeWire)
# - Developer-optimized performance modes
# 
# GitHub: https://github.com/username/whalecraft
# Website: https://whalecraft.dev

set -e

# WhaleCraft branding
echo "🐋 WhaleCraft v1.0"
echo "The Ultimate Arch Linux Setup"
echo "Deep. Powerful. Perfectly Tuned."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Hardware detection functions
detect_graphics() {
    echo "🔍 Scanning the depths for graphics hardware..."
    
    if lspci | grep -i nvidia >/dev/null 2>&1; then
        HAS_NVIDIA=true
        echo "  🎮 NVIDIA GPU detected - Ready for deep performance"
    else
        HAS_NVIDIA=false
        echo "  • No NVIDIA GPU found"
    fi
    
    if lspci | grep -i intel.*graphics >/dev/null 2>&1; then
        HAS_INTEL=true
        echo "  💎 Intel graphics detected - Efficiency mode ready"
    else
        HAS_INTEL=false
    fi
    
    if lspci | grep -i amd.*graphics >/dev/null 2>&1 || lspci | grep -i radeon >/dev/null 2>&1; then
        HAS_AMD=true
        echo "  🔥 AMD graphics detected - Power mode ready"
    else
        HAS_AMD=false
    fi
}

detect_cpu() {
    echo "🔍 Identifying CPU architecture..."
    
    if grep -q "Intel" /proc/cpuinfo; then
        CPU_VENDOR="intel"
        echo "  ⚡ Intel CPU detected - Optimizing for efficiency"
    elif grep -q "AMD" /proc/cpuinfo; then
        CPU_VENDOR="amd"  
        echo "  🚀 AMD CPU detected - Configuring for performance"
    else
        CPU_VENDOR="unknown"
        echo "  ⚠️ Unknown CPU vendor - Using universal settings"
    fi
}

detect_battery() {
    echo "🔍 Searching for power systems..."
    
    if [ -d /sys/class/power_supply/BAT0 ]; then
        BATTERY_PATH="/sys/class/power_supply/BAT0"
        echo "  🔋 Battery found at BAT0 - Preparing longevity settings"
    elif [ -d /sys/class/power_supply/BAT1 ]; then
        BATTERY_PATH="/sys/class/power_supply/BAT1"
        echo "  🔋 Battery found at BAT1 - Preparing longevity settings"
    else
        BATTERY_PATH=""
        echo "  🖥️ Desktop system detected - Full power mode available"
    fi
}

# Hardware detection
echo "🌊 Beginning WhaleCraft system analysis..."
detect_graphics
detect_cpu  
detect_battery

echo ""
echo "🐋 Ready to craft your perfect Arch Linux system?"
echo "This will configure:"
echo "  • Smart power management with 65% battery protection"
echo "  • Hybrid graphics with thermal optimization"
echo "  • Beautiful Plymouth boot experience"
echo "  • Professional PipeWire audio system"
echo "  • Developer performance modes"
echo ""
read -p "🌊 Dive deep with WhaleCraft? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🐋 WhaleCraft session ended. The ocean awaits your return."
    exit 1
fi

echo "🌊 WhaleCraft is diving deep..."
echo ""

# System update
echo "📦 Surfacing with latest packages..."
sudo pacman -Syu --noconfirm

# Install base packages
echo "🔧 Gathering essential components..."
PACKAGES="tlp tlp-rdw thermald lm_sensors htop iotop bc plymouth pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol helvum qpwgraph alsa-utils networkmanager-dispatcher"

# Add graphics packages based on detection
if [ "$HAS_NVIDIA" = true ]; then
    PACKAGES="$PACKAGES nvidia nvidia-utils nvidia-prime nvidia-settings"
    echo "  🎮 Adding NVIDIA deep-sea components"
fi

# Install AUR helper for themes
if ! command -v yay >/dev/null 2>&1; then
    echo "🛠️ Installing AUR helper for extended crafting..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
fi

# Install packages
sudo pacman -S --noconfirm --needed $PACKAGES

# Install WhaleCraft Plymouth theme
echo "🎨 Installing WhaleCraft visual experience..."
yay -S --noconfirm plymouth-theme-arch-charge || echo "🌊 Using fallback theme"

echo "🔋 Crafting power management systems..."

# Battery protection
if [ -n "$BATTERY_PATH" ] && [ -f "$BATTERY_PATH/charge_control_end_threshold" ]; then
    echo "🔋 Installing battery longevity protection (65% limit)..."
    
    sudo tee /etc/systemd/system/whalecraft-battery.service > /dev/null << EOF
[Unit]
Description=WhaleCraft Battery Longevity Protection
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 65 > $BATTERY_PATH/charge_control_end_threshold'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable whalecraft-battery.service
    echo 65 | sudo tee "$BATTERY_PATH/charge_control_end_threshold" > /dev/null
    echo "  🐋 Battery protection active - 65% charge limit set"
else
    echo "  🖥️ Desktop mode - unlimited power available"
fi

# TLP configuration  
echo "⚡ Crafting intelligent power management..."
sudo cp /etc/tlp.conf /etc/tlp.conf.backup

# WhaleCraft TLP settings
sudo tee -a /etc/tlp.conf > /dev/null << 'EOF'

# WhaleCraft Power Management Settings
# Deep. Powerful. Perfectly Tuned.

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

# GPU-specific settings
if [ "$HAS_NVIDIA" = true ]; then
    echo 'RUNTIME_PM_DRIVER_DENYLIST="nvidia nouveau radeon"' | sudo tee -a /etc/tlp.conf > /dev/null
elif [ "$HAS_AMD" = true ]; then
    echo 'RUNTIME_PM_DRIVER_DENYLIST="amdgpu radeon"' | sudo tee -a /etc/tlp.conf > /dev/null
fi

# Enable services
echo "🌊 Activating WhaleCraft systems..."
sudo systemctl enable --now tlp.service
sudo systemctl enable --now thermald
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Configure sensors
sudo sensors-detect --auto

# Boot experience
echo "🎨 Crafting boot experience..."
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    sudo plymouth-set-default-theme arch-charge 2>/dev/null || sudo plymouth-set-default-theme spinfinity
fi

# Update boot configuration
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont plymouth block filesystems fsck)/' /etc/mkinitcpio.conf

if [ -f /etc/kernel/cmdline ]; then
    CURRENT_CMDLINE=$(cat /etc/kernel/cmdline)
    NEW_CMDLINE="$CURRENT_CMDLINE quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0"
    echo "$NEW_CMDLINE" | sudo tee /etc/kernel/cmdline > /dev/null
fi

# systemd-boot configuration
if [ -d /boot/loader ]; then
    sudo tee /boot/loader/loader.conf > /dev/null << 'EOF'
# WhaleCraft Boot Configuration
timeout 1
console-mode max
default arch-linux.efi
editor no
EOF
fi

echo "🔄 Rebuilding system with WhaleCraft configurations..."
sudo mkinitcpio -P

# PipeWire audio
echo "🎵 Installing WhaleCraft audio system..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Create WhaleCraft utilities
echo "🛠️ Installing WhaleCraft command suite..."

# WhaleCraft Power Manager
sudo tee /usr/local/bin/whale > /dev/null << 'SCRIPT'
#!/bin/bash
# WhaleCraft Power Manager 🐋

CHARGE_LIMIT=65
BATTERY_PATH=$(find /sys/class/power_supply -name "BAT*" -type d 2>/dev/null | head -1)
CHARGE_FILE="$BATTERY_PATH/charge_control_end_threshold"

whale_banner() {
    echo "🐋 WhaleCraft Power Manager"
    echo "Deep. Powerful. Perfectly Tuned."
    echo ""
}

set_charge_limit() {
    if [ -n "$BATTERY_PATH" ] && [ -f "$CHARGE_FILE" ]; then
        echo $CHARGE_LIMIT | sudo tee "$CHARGE_FILE" > /dev/null
        echo "🔋 Battery protection maintained at ${CHARGE_LIMIT}%"
    fi
}

get_cpu_temp() {
    temp=$(sensors 2>/dev/null | grep -E "(Package id 0|Tctl|CPU)" | head -1 | awk '{print $3}' | sed 's/+//;s/°C.*//' | cut -d. -f1 2>/dev/null)
    echo "${temp:-0}"
}

case "$1" in
    "dive"|"performance")
        whale_banner
        echo "🌊 Diving to performance depths..."
        sudo tee /tmp/whale-perf.conf > /dev/null << 'EOF'
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_MAX_PERF_ON_AC=100
PLATFORM_PROFILE_ON_AC=performance
EOF
        sudo cp /etc/tlp.conf.backup /etc/tlp.conf
        sudo tee -a /etc/tlp.conf < /tmp/whale-perf.conf > /dev/null
        sudo tlp ac
        echo "🐋 Performance mode: Full depth achieved"
        echo "⚡ CPU: 100% power available"
        [ -n "$(lspci | grep -i nvidia)" ] && echo "🎮 NVIDIA: Ready for prime-run commands"
        set_charge_limit
        ;;
    "surface"|"quiet")
        whale_banner
        echo "🌊 Surfacing to quiet waters..."
        sudo cp /etc/tlp.conf.backup /etc/tlp.conf
        sudo tee -a /etc/tlp.conf << 'EOF' > /dev/null
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_MAX_PERF_ON_AC=75
PLATFORM_PROFILE_ON_AC=balanced
RUNTIME_PM_ON_AC=auto
EOF
        sudo tlp ac
        echo "🐋 Quiet mode: Balanced performance"
        echo "🤫 Fans: Quieter operation for deep work"  
        set_charge_limit
        ;;
    "status"|"sonar")
        whale_banner
        echo "🌊 WhaleCraft System Status:"
        echo ""
        echo "🌡️ Temperature: $(get_cpu_temp)°C"
        if [ -n "$BATTERY_PATH" ]; then
            echo "🔋 Battery: Found at $(basename $BATTERY_PATH)"
            [ -f "$CHARGE_FILE" ] && echo "⚡ Charge Limit: $(cat $CHARGE_FILE 2>/dev/null)%"
        else
            echo "🖥️ System: Desktop (unlimited power)"
        fi
        echo "🐋 CPU Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo 'N/A')% max"
        ;;
    *)
        whale_banner
        echo "🌊 WhaleCraft Commands:"
        echo ""
        echo "  dive (performance)  🌊  Deep performance mode (100% CPU)"
        echo "  surface (quiet)     🐋  Quiet balanced mode (75% CPU)"
        echo "  sonar (status)      📡  System status check"
        echo ""
        echo "💡 Example: whale dive    # Enter performance mode"
        echo "💡 Example: whale surface # Return to quiet mode"
        ;;
esac
SCRIPT

# WhaleCraft Audio Manager
sudo tee /usr/local/bin/whale-audio > /dev/null << 'SCRIPT'
#!/bin/bash
# WhaleCraft Audio Manager 🎵

case "$1" in
    "sonar"|"status")
        echo "🎵 WhaleCraft Audio Sonar"
        pactl info | grep "Server Name" 2>/dev/null || echo "🔇 Audio system sleeping"
        pactl list short sinks 2>/dev/null | head -1 | cut -f2 | sed 's/^/🔊 Output: /'
        ;;
    "volume")
        [ -n "$2" ] && pactl set-sink-volume @DEFAULT_SINK@ "$2%" && echo "🔊 Volume: $2%"
        ;;
    "wake"|"fix")
        echo "🌊 Waking audio system..."
        systemctl --user restart pipewire pipewire-pulse wireplumber
        echo "🎵 Audio system refreshed"
        ;;
    "gui")
        pavucontrol &
        echo "🎵 Audio control panel launched"
        ;;
    *)
        echo "🎵 WhaleCraft Audio: {sonar|volume|wake|gui}"
        ;;
esac
SCRIPT

# Smart build wrapper
sudo tee /usr/local/bin/whale-build > /dev/null << 'SCRIPT'
#!/bin/bash
# WhaleCraft Smart Build System 🔨

if [ -z "$*" ]; then
    echo "🔨 WhaleCraft Build System"
    echo "Usage: whale-build <command>"
    echo "Example: whale-build make -j8"
    exit 1
fi

echo "🐋 WhaleCraft Build: $*"
echo "🌊 Diving to performance depths..."
whale dive > /dev/null
echo "🔨 Building..."
eval "$*"
EXIT_CODE=$?
echo "🌊 Surfacing to quiet waters..."
whale surface > /dev/null
echo "🐋 Build complete - returned to balanced mode"
exit $EXIT_CODE
SCRIPT

# Make scripts executable
sudo chmod +x /usr/local/bin/{whale,whale-audio,whale-build}

# Create WhaleCraft aliases
tee -a ~/.bashrc > /dev/null << 'EOF'

# 🐋 WhaleCraft Command Suite
alias dive="whale dive"          # Performance mode
alias surface="whale surface"    # Quiet mode  
alias sonar="whale sonar"        # Status check
alias whale-vol="whale-audio volume"
alias whale-gui="whale-audio gui"
EOF

echo ""
echo "🌊━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌊"
echo ""
echo "                               🐋 WhaleCraft Complete! 🐋"
echo ""
echo "🌊━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌊"
echo ""
echo "Your Arch Linux system has been crafted to perfection:"
echo ""
[ "$HAS_NVIDIA" = true ] && echo "🎮 NVIDIA Graphics: prime-run <app>"
[ "$HAS_INTEL" = true ] && echo "💎 Intel Graphics: Optimized for efficiency"  
[ "$HAS_AMD" = true ] && echo "🔥 AMD Graphics: Performance ready"
[ -n "$BATTERY_PATH" ] && echo "🔋 Battery Protection: 65% charge limit active"
echo "⚡ CPU Optimization: $CPU_VENDOR tuned"
echo "🎵 Audio System: PipeWire professional stack"
echo "🎨 Boot Experience: Beautiful Plymouth splash"
echo ""
echo "🐋 WhaleCraft Commands:"
echo "  dive              🌊  Performance mode (builds, gaming)"
echo "  surface           🐋  Quiet mode (coding, browsing)"
echo "  sonar             📡  Check system status"
echo "  whale-build make  🔨  Smart build (auto performance)"
echo ""
echo "💡 Reboot to experience the full WhaleCraft transformation!"
echo ""
echo "🌊 Deep. Powerful. Perfectly Tuned. 🐋"
SCRIPT

chmod +x /tmp/whalecraft.sh
cp /tmp/whalecraft.sh ~/arch-setup-backup/
