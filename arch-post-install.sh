#!/bin/bash
# Complete Arch Linux Post-Installation Setup Script
# Recreates the exact configuration we built together

set -e  # Exit on any error

echo "🚀 Starting Arch Linux Complete Setup..."
echo "This will install and configure:"
echo "  - Battery management (65% charge limit)"
echo "  - Hybrid graphics (Intel + NVIDIA)"
echo "  - Thermal management"
echo "  - Developer power modes"
echo "  - Beautiful boot experience"
echo "  - Complete PipeWire audio"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Update system first
echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

# Install base packages
echo "📦 Installing base packages..."
sudo pacman -S --noconfirm --needed \
    nvidia nvidia-utils nvidia-prime nvidia-settings \
    tlp tlp-rdw thermald \
    lm_sensors htop iotop bc \
    plymouth plymouth-theme-arch-charge \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    pavucontrol helvum qpwgraph alsa-utils \
    networkmanager-dispatcher

echo "🔋 Setting up battery charge limit..."
# Create systemd service for 65% charge limit
sudo tee /etc/systemd/system/battery-charge-limit.service > /dev/null << 'EOF'
[Unit]
Description=Set Battery Charge Limit to 65%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 65 > /sys/class/power_supply/BAT0/charge_control_end_threshold'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable battery-charge-limit.service

# Set up TLP configuration
echo "⚡ Configuring power management..."
sudo cp /etc/tlp.conf /etc/tlp.conf.backup

sudo tee -a /etc/tlp.conf > /dev/null << 'EOF'

# Thermal-optimized TLP settings
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
RUNTIME_PM_DRIVER_DENYLIST="nvidia nouveau radeon"
EOF

# Enable services
echo "🔧 Enabling services..."
sudo systemctl enable --now tlp.service
sudo systemctl enable --now thermald
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Set up sensors
echo "🌡️ Configuring sensors..."
sudo sensors-detect --auto

# Set up Plymouth boot splash
echo "🎨 Configuring beautiful boot..."
sudo plymouth-set-default-theme arch-charge

# Add plymouth to mkinitcpio
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont plymouth block filesystems fsck)/' /etc/mkinitcpio.conf

# Update kernel cmdline for quiet boot
CURRENT_CMDLINE=$(cat /etc/kernel/cmdline)
NEW_CMDLINE="$CURRENT_CMDLINE quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0"
echo "$NEW_CMDLINE" | sudo tee /etc/kernel/cmdline > /dev/null

# Configure systemd-boot
sudo tee /boot/loader/loader.conf > /dev/null << 'EOF'
# Enhanced systemd-boot configuration
timeout 1
console-mode max
default arch-linux.efi
editor no
EOF

# Rebuild kernel images
echo "🔄 Rebuilding kernel images..."
sudo mkinitcpio -P

# Enable PipeWire audio services
echo "🎵 Setting up PipeWire audio..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "✅ Base system configuration complete!"

# Create utility scripts
echo "🛠️ Creating utility scripts..."

# Developer power management script
sudo tee /usr/local/bin/dev-power > /dev/null << 'DEVPOWER_SCRIPT'
#!/bin/bash
# Developer-Optimized Power Management

CHARGE_LIMIT=65
CHARGE_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"

set_charge_limit() {
    echo $CHARGE_LIMIT | sudo tee "$CHARGE_FILE" > /dev/null
    echo "Charge limit maintained at ${CHARGE_LIMIT}%"
}

check_power_source() {
    if [ -f /sys/class/power_supply/AC0/online ]; then
        cat /sys/class/power_supply/AC0/online
    else
        acpi -a 2>/dev/null | grep -q "on-line" && echo 1 || echo 0
    fi
}

get_cpu_temp() {
    sensors | grep "Package id 0:" | awk '{print $4}' | sed 's/+//;s/°C//' | cut -d. -f1 2>/dev/null || echo "0"
}

apply_settings() {
    local mode=$1
    local temp=$(get_cpu_temp)
    
    case "$mode" in
        "dev-performance")
            echo "🚀 DEVELOPER PERFORMANCE MODE"
            sudo tee /tmp/dev-performance.conf > /dev/null << 'EOF'
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_BOOST_ON_AC=1
CPU_MIN_PERF_ON_AC=20
CPU_MAX_PERF_ON_AC=100
PLATFORM_PROFILE_ON_AC=performance
RUNTIME_PM_ON_AC=on
RUNTIME_PM_DRIVER_DENYLIST="nvidia nouveau radeon"
EOF
            sudo cp /etc/tlp.conf.backup /etc/tlp.conf
            sudo tee -a /etc/tlp.conf < /tmp/dev-performance.conf > /dev/null
            sudo tlp ac
            echo "   ✓ CPU: 100% max performance"
            echo "   ✓ GPU: NVIDIA available via prime-run"
            ;;
            
        "dev-quiet")
            echo "🤫 DEVELOPER QUIET MODE"
            sudo tee /tmp/dev-quiet.conf > /dev/null << 'EOF'
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_BOOST_ON_AC=1
CPU_MIN_PERF_ON_AC=10
CPU_MAX_PERF_ON_AC=75
PLATFORM_PROFILE_ON_AC=balanced
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_DRIVER_DENYLIST="nvidia nouveau radeon"
EOF
            sudo cp /etc/tlp.conf.backup /etc/tlp.conf
            sudo tee -a /etc/tlp.conf < /tmp/dev-quiet.conf > /dev/null
            sudo tlp ac
            echo "   ✓ CPU: 75% max performance (quiet for coding)"
            ;;
            
        "dev-auto")
            power_source=$(check_power_source)
            if [ "$power_source" = "1" ]; then
                apply_settings "dev-quiet"
            else
                sudo tlp bat
                echo "🔋 Battery - Power save mode"
            fi
            ;;
    esac
    
    set_charge_limit
}

case "$1" in
    "performance"|"perf") apply_settings "dev-performance" ;;
    "quiet") apply_settings "dev-quiet" ;;
    "auto") apply_settings "dev-auto" ;;
    "status")
        echo "=== Developer Power Status ==="
        echo "Power: $([ "$(check_power_source)" = "1" ] && echo "AC" || echo "Battery")"
        echo "Temperature: $(get_cpu_temp)°C"
        echo "Charge Limit: $(cat $CHARGE_FILE 2>/dev/null || echo 'Unknown')%"
        echo "Max CPU Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo 'N/A')%"
        ;;
    *)
        echo "Developer Power Management"
        echo "Usage: $0 {performance|quiet|auto|status}"
        echo "  performance - 100% CPU for builds"
        echo "  quiet       - 75% CPU for coding (quieter fans)"  
        echo "  auto        - Auto based on power source"
        echo "  status      - Show current status"
        ;;
esac
DEVPOWER_SCRIPT

# Audio manager script
sudo tee /usr/local/bin/audio-manager > /dev/null << 'AUDIO_SCRIPT'
#!/bin/bash
# PipeWire Audio Management Utility

case "$1" in
    "status")
        echo "=== PipeWire Audio Status ==="
        echo "🎵 Server: $(pactl info | grep "Server Name" | cut -d: -f2 | xargs)"
        echo "🔊 Output: $(pactl list short sinks | head -1 | cut -f2)"
        echo "📊 Volume: $(pactl list sinks | grep -A 5 "State: RUNNING" | grep Volume | head -1 | grep -o '[0-9]*%' | head -1)"
        ;;
    "volume")
        if [ -z "$2" ]; then
            echo "Usage: $0 volume <0-100>"
            exit 1
        fi
        pactl set-sink-volume @DEFAULT_SINK@ "$2%"
        echo "Volume set to $2%"
        ;;
    "mute")
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        echo "Mute toggled"
        ;;
    "gui")
        pavucontrol &
        ;;
    "fix")
        systemctl --user restart pipewire pipewire-pulse wireplumber
        pactl set-sink-mute @DEFAULT_SINK@ false
        pactl set-sink-volume @DEFAULT_SINK@ 50%
        echo "Audio services restarted and unmuted"
        ;;
    *)
        echo "Audio Manager: {status|volume|mute|gui|fix}"
        ;;
esac
AUDIO_SCRIPT

# Thermal monitor script
sudo tee /usr/local/bin/thermal-monitor > /dev/null << 'THERMAL_SCRIPT'
#!/bin/bash
case "$1" in
    "check")
        temp=$(sensors | grep "Package id 0:" | awk '{print $4}' | sed 's/+//;s/°C//' | cut -d. -f1 2>/dev/null || echo "0")
        fan_rpm=$(sensors | grep "cpu_fan" | awk '{print $2}' 2>/dev/null || echo "Unknown")
        echo "CPU: ${temp}°C | Fan: $fan_rpm"
        ;;
    *)
        echo "Thermal Monitor: {check}"
        ;;
esac
THERMAL_SCRIPT

# Smart build wrapper
sudo tee /usr/local/bin/smart-build > /dev/null << 'BUILD_SCRIPT'
#!/bin/bash
if [ -z "$*" ]; then
    echo "Smart Build - Usage: smart-build <command>"
    echo "Example: smart-build make -j8"
    exit 1
fi

echo "🔨 Smart Build: $*"
dev-power performance > /dev/null
eval "$*"
EXIT_CODE=$?
dev-power quiet > /dev/null
echo "✅ Build finished, switched back to quiet mode"
exit $EXIT_CODE
BUILD_SCRIPT

# Boot manager script  
sudo tee /usr/local/bin/boot-manager > /dev/null << 'BOOT_SCRIPT'
#!/bin/bash
case "$1" in
    "status")
        echo "=== Boot Status ==="
        bootctl status | grep "Current Entry"
        systemd-analyze
        echo "Boot timeout: $(grep timeout /boot/loader/loader.conf | cut -d' ' -f2)s"
        ;;
    "fast-boot")
        sudo sed -i 's/^timeout.*/timeout 0/' /boot/loader/loader.conf
        echo "Ultra-fast boot enabled (0s timeout)"
        ;;
    *)
        echo "Boot Manager: {status|fast-boot}"
        ;;
esac
BOOT_SCRIPT

# Make all scripts executable
sudo chmod +x /usr/local/bin/{dev-power,audio-manager,thermal-monitor,smart-build,boot-manager}

# Create convenient aliases
tee -a ~/.bashrc > /dev/null << 'EOF'

# Post-install setup aliases
alias dev-perf="dev-power performance"
alias dev-quiet="dev-power quiet"
alias dev-status="dev-power status"
alias audio-status="audio-manager status"
alias vol="audio-manager volume"
alias mute="audio-manager mute"
alias temp="thermal-monitor check"
alias boot-config="boot-manager status"
EOF

# Create udev rule for automatic power switching
sudo tee /etc/udev/rules.d/99-power-management.rules > /dev/null << 'EOF'
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/local/bin/dev-power auto"
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/local/bin/dev-power auto"
EOF

sudo udevadm control --reload-rules

# Apply initial settings
echo "🎯 Applying initial configuration..."
echo 65 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold > /dev/null
dev-power auto

echo ""
echo "🎉 SETUP COMPLETE! 🎉"
echo ""
echo "Your Arch Linux system now has:"
echo "✅ 65% battery charge limit"
echo "✅ Hybrid graphics (Intel + NVIDIA)"
echo "✅ Smart thermal management"  
echo "✅ Developer power modes"
echo "✅ Beautiful boot experience"
echo "✅ Complete PipeWire audio"
echo ""
echo "🚀 Key commands:"
echo "  dev-quiet     - Quiet coding mode"
echo "  dev-perf      - Performance mode for builds"
echo "  smart-build   - Auto performance for builds"
echo "  audio-status  - Check audio"
echo "  temp          - Check temperatures"
echo "  prime-run APP - Use NVIDIA GPU"
echo ""
echo "💡 Reboot to enjoy the beautiful boot experience!"
