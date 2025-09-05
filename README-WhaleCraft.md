# 🐋 WhaleCraft
**The Ultimate Arch Linux Setup**

*Deep. Powerful. Perfectly Tuned.*

---

Transform your fresh Arch Linux installation into a perfectly optimized system with a single command.

## 🌊 What is WhaleCraft?

WhaleCraft automatically configures your Arch Linux system with professional-grade optimizations:

- **🔋 Smart Power Management** - 65% battery protection + intelligent thermal control
- **🎮 Hybrid Graphics** - Seamless Intel + NVIDIA switching with thermal awareness
- **🎨 Beautiful Boot** - Plymouth splash screen with optimized systemd-boot
- **🎵 Professional Audio** - Complete PipeWire stack for low-latency audio
- **⚡ Developer Modes** - Performance/quiet modes with one command

## 🚀 Quick Start

```bash
# Download WhaleCraft
curl -O https://raw.githubusercontent.com/username/whalecraft/main/whalecraft.sh

# Make executable and dive deep
chmod +x whalecraft.sh
./whalecraft.sh
```

## 🐋 WhaleCraft Commands

After installation, control your system like a majestic whale:

### Power Management
```bash
dive              # 🌊 Deep performance mode (100% CPU for builds)
surface           # 🐋 Quiet balanced mode (75% CPU for coding)
sonar             # 📡 System status check
whale-build make  # 🔨 Smart build (auto performance switching)
```

### Audio & Graphics
```bash
whale-audio sonar     # 🎵 Check audio system
whale-audio volume 75 # 🔊 Set volume
prime-run steam       # 🎮 Use NVIDIA GPU (if detected)
```

## 🌊 Hardware Support

WhaleCraft automatically detects and configures:

| Hardware | Support | Configuration |
|----------|---------|---------------|
| Intel + NVIDIA | ✅ Perfect | Full hybrid graphics + thermal mgmt |
| Intel only | ✅ Perfect | Optimized power management |
| AMD + NVIDIA | ✅ Perfect | AMD optimization + NVIDIA support |
| AMD only | ✅ Perfect | AMD power optimization |
| Desktop systems | ✅ Perfect | No battery limits, all other features |

## 🛠️ What Gets Configured

### Power & Thermal
- **Battery protection** at 65% charge limit (laptops only)
- **TLP power management** with thermal-aware CPU scaling
- **thermald** for intelligent thermal control
- **Automatic AC/battery mode switching**

### Graphics
- **NVIDIA drivers** + PRIME offload (if NVIDIA detected)
- **Hybrid graphics** with thermal protection
- **Intel/AMD optimization** based on detected hardware

### Boot Experience  
- **Plymouth splash screen** with Arch theme
- **systemd-boot optimization** (1 second timeout)
- **Silent boot** with minimal logging
- **High-resolution console mode**

### Audio System
- **PipeWire** professional audio stack
- **ALSA/JACK compatibility** for all applications
- **GUI audio tools** (pavucontrol, helvum, qpwgraph)
- **Low-latency** configuration

## 🎯 Perfect For

- **Developers** - Smart build system with auto performance switching
- **Content Creators** - Professional audio + hybrid graphics
- **Gamers** - NVIDIA support + thermal management
- **Power Users** - Complete system optimization
- **Anyone** who wants a perfectly tuned Arch Linux system

## 🌊 Philosophy

Like a whale diving to great depths and surfacing gracefully, WhaleCraft gives you:

- **🌊 Deep Performance** when you need maximum power
- **🐋 Graceful Efficiency** for everyday computing  
- **📡 Intelligent Awareness** of your system's needs

## 🔧 Advanced Usage

### Custom CPU Limits
Edit `/etc/tlp.conf` and look for WhaleCraft sections to modify power limits.

### Different Battery Limits
```bash
# Edit the whale script
sudo nano /usr/local/bin/whale
# Change CHARGE_LIMIT=65 to your preferred percentage
```

### Boot Timeout
```bash
# Ultra-fast boot (0 seconds)
sudo sed -i 's/timeout 1/timeout 0/' /boot/loader/loader.conf

# Longer timeout
sudo sed -i 's/timeout 1/timeout 3/' /boot/loader/loader.conf
```

## 🤝 Contributing

WhaleCraft is open source! Contribute at:
- **GitHub:** `https://github.com/username/whalecraft`
- **Issues:** Report bugs or request features
- **Pull Requests:** Improvements welcome

## 📜 License

WhaleCraft is released under the MIT License.

## 🙏 Credits

Created by passionate Arch Linux users who believe your system should be as magnificent as a whale in the ocean.

---

## 🐋 Join the Pod

*Deep. Powerful. Perfectly Tuned.*

Transform your Arch Linux experience with WhaleCraft today.

```
🌊━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌊
                            🐋 WhaleCraft - Dive Deep 🐋
🌊━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🌊
```
