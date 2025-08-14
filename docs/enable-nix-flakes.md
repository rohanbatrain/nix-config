### 📄 `enable-nix-flakes.md`

````md
# 🔧 Enabling Nix Flakes on macOS (Multi-User Install)

This guide explains how to enable Nix flakes and the modern nix CLI on **macOS** using a safe and automated Bash script.

---

## 📋 Requirements

- macOS with Nix installed in **multi-user mode**
- `sudo` access (required to edit `/etc/nix/nix.conf`)

---

## 🚀 Quick Start

1. **Download the script:**

   Save the following script as `enable-nix-flakes.sh` in your local machine:

   ```bash
   #!/usr/bin/env bash

   set -e

   NIX_CONF="/etc/nix/nix.conf"

   echo "🔧 Enabling Nix flakes and nix-command..."

   # Check if running as root
   if [[ $EUID -ne 0 ]]; then
     echo "❌ Please run this script with sudo:"
     echo "   sudo $0"
     exit 1
   fi

   # Create /etc/nix if it doesn't exist
   if [[ ! -d /etc/nix ]]; then
     echo "📁 Creating /etc/nix..."
     mkdir -p /etc/nix
   fi

   # Enable experimental features if not already present
   if grep -q "experimental-features" "$NIX_CONF"; then
     echo "⚠️  Updating existing experimental-features line..."
     sed -i '' 's/^experimental-features.*/experimental-features = nix-command flakes/' "$NIX_CONF"
   else
     echo "✅ Adding experimental-features = nix-command flakes"
     echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
   fi

   echo "🔄 Restarting Nix daemon..."
   launchctl stop org.nixos.nix-daemon
   launchctl start org.nixos.nix-daemon

   echo "✅ Flakes are now enabled system-wide!"
````

2. **Run the script:**

   ```bash
   chmod +x enable-nix-flakes.sh
   sudo ./enable-nix-flakes.sh
   ```

---

## ✅ What This Script Does

* Ensures `/etc/nix/nix.conf` exists

* Adds or updates this line:

  ```ini
  experimental-features = nix-command flakes
  ```

* Restarts the Nix daemon to apply changes

---

## 📎 Related Commands

* Check if flakes are enabled:

  ```bash
  nix flake --help
  ```

* Enter a flake-based dev shell:

  ```bash
  nix develop
  ```

---

## 🛠 Optional Tools

* [direnv](https://direnv.net/) for auto-loading your Nix shell
* [cachix](https://cachix.org/) for binary caching

---

## 📦 Recommended Flake-Based Workflow

1. Keep your Nix config in a GitHub repo (e.g., `nix-config`)
2. Use `nix develop` to enter reproducible environments
3. Push changes, and use the flake remotely via:

   ```bash
   nix develop github:yourusername/nix-config
   ```

---

Happy hacking 🧪💻

