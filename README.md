# 🧹 PC Clean & IP Reset

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-A3BE8C?style=for-the-badge)](LICENSE)
![Version](https://img.shields.io/badge/Version-1.1-88C0D0?style=for-the-badge)

**A Nord-themed terminal tool that cleans Windows system junk and optionally resets the network stack — with a detailed before/after report of everything deleted.**

*by [Harindu Jayakody](https://github.com/harindujayakody)*

</div>

---

## ✨ Features

- 🗑️ **Cleans system temp folders** — `%TEMP%`, `C:\Windows\Temp`, `C:\Windows\Prefetch`
- 🌐 **Full network stack reset** — releases IP, flushes DNS, renews IP, resets Winsock & TCP/IP
- 🛡️ **Network-safe cleaning mode (`-SkipNetwork`)** — clean junk without disconnecting internet, VPNs, or downloads
- 📊 **Before / After report** — shows exactly how much space was freed per location
- ✅ **Confirm before clean** — upfront size preview and disconnect warnings before touching anything
- 🧪 **Dry-run inspection (`-DryRun`)** — scan and preview actions without modifying files or network settings
- 🎨 **Nord-themed terminal UI** — box-drawing characters, colour-coded output
- 🖥️ **Opens in Windows Terminal** — falls back to PowerShell window gracefully

---

## 📸 Preview

```
  ╔══════════════════════════════════════════════════════════╗
  ║   ██████╗  ██████╗    ██████╗██╗     ███████╗ █████╗    ║
  ║   ██╔══██╗██╔════╝   ██╔════╝██║     ██╔════╝██╔══██╗   ║
  ║   ██████╔╝██║        ██║     ██║     █████╗  ███████║   ║
  ║   ██╔═══╝ ██║        ██║     ██║     ██╔══╝  ██╔══██║   ║
  ║   ██║     ╚██████╗   ╚██████╗███████╗███████╗██║  ██║   ║
  ║         P C   C L E A N   &   I P   R E S E T           ║
  ╚══════════════════════════════════════════════════════════╝

  >> Measuring system junk...
  >> User Temp (%TEMP%)       1,208.54 MB found
  >> Windows Temp                24.19 MB found
  >> Prefetch Cache               8.10 MB found

  >> Total found: 1,240.83 MB

  [!] WARNING: Network reset will temporarily disconnect your internet.
      Active downloads, VPNs, and remote sessions (RDP/SSH) will be interrupted.
      (Use -SkipNetwork to clean junk files without touching the network)

  >> Proceed? [Y] Yes   [N] No  :

  +-- CLEANING SYSTEM JUNK ---------------------------------------------+
  |  >> User Temp (%TEMP%)       1,208.54 MB freed
  |  >> Windows Temp                24.19 MB freed
  |  >> Prefetch Cache               8.10 MB freed
  +---------------------------------------------------------------------+

  +-- RESETTING NETWORK ------------------------------------------------+
  |  >> Releasing IP address              done
  |  >> Flushing DNS cache                done
  |  >> Renewing IP address               done
  |  >> Resetting Winsock                 done
  |  >> Resetting TCP/IP stack            done
  +---------------------------------------------------------------------+

  +==============================================================+
  |   SUMMARY REPORT                                             |
  +==============================================================+
  | SYSTEM JUNK CLEANED                                          |
  +--------------------------------------------------------------+
  |      Location                  Before      After      Freed |
  +--------------------------------------------------------------+
  | [OK] User Temp (%TEMP%)      1,208.54MB     0.00MB  1,208.54MB |
  | [OK] Windows Temp               24.19MB     0.00MB    24.19MB |
  | [OK] Prefetch Cache              8.10MB     0.00MB     8.10MB |
  +--------------------------------------------------------------+
  | TOTAL FREED  1,240.83 MB  (1.212 GB)                         |
  +--------------------------------------------------------------+
  | [OK] Freed:  1,240.83 MB  (1.212 GB)                         |
  | [OK] Network stack has been reset.                           |
  | [!!] Reboot recommended for network changes.                 |
  +==============================================================+
```

---

## 🌐 What Gets Reset

| Command | What It Does |
|---|---|
| `ipconfig /release` | Releases the current DHCP IP address |
| `ipconfig /flushdns` | Clears the DNS resolver cache |
| `ipconfig /renew` | Requests a fresh IP from the DHCP server |
| `netsh winsock reset` | Resets the Winsock catalog to default state |
| `netsh int ip reset` | Resets the TCP/IP stack to clean state |

> **Note:** Network reset temporarily disconnects your active network adapter and drops active downloads, VPN tunnels, and remote connections. If you only want to clean junk files without network interruptions, pass `-SkipNetwork`.

---

## 🗑️ What Gets Cleaned

| Location | Path |
|---|---|
| User Temp | `%TEMP%` |
| Windows Temp | `C:\Windows\Temp` |
| Prefetch Cache | `C:\Windows\Prefetch` |

Folders are emptied of unneeded cache files while locked in-use files are safely skipped.

---

## 🚀 Quick Start

### 1. Run via Launcher

Double-click **`RunPcClean.bat`**

- Auto-requests Administrator privileges
- Opens in **Windows Terminal** (falls back to PowerShell if WT not installed)
- Shows upfront warning and total junk found before doing anything
- Arguments can be forwarded directly (e.g. `RunPcClean.bat -SkipNetwork`)

### 2. Run via PowerShell

```powershell
# Standard run (Clean junk + Network reset)
.\PcClean-IpReset.ps1

# Clean junk ONLY (do not drop network / VPN / downloads)
.\PcClean-IpReset.ps1 -SkipNetwork

# Dry-run inspection (view junk sizes without modifying files or network)
.\PcClean-IpReset.ps1 -DryRun
```

### ⚙️ Command-Line Parameters

| Parameter | Alias | Description |
|---|---|---|
| `-SkipNetwork` | `-skip-network`, `-no-network` | Bypasses IP release/renew and Winsock reset |
| `-DryRun` | `-dry-run`, `-WhatIf` | Runs safely in preview mode without deleting files or altering network |
| `-Yes` | `-y`, `-AssumeYes` | Skips interactive confirmation prompt |

---

## 🎨 Recommended Terminal Setup

For the best visual experience with Nord colours and box-drawing characters:

### Font — JetBrains Mono Nerd Font

**Install via winget:**
```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont
```

**Or download manually:** [nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads) → search **JetBrainsMono**

### Windows Terminal — Nord Color Scheme

Open Windows Terminal Settings (`Ctrl+,`) → Profiles → Defaults → Appearance:
- **Font face:** `JetBrainsMono Nerd Font`
- **Font size:** `11`

Add to `settings.json` → `"schemes"` array (`Ctrl+Shift+,`):

```json
{
    "name": "Nord",
    "black": "#3B4252",
    "red": "#BF616A",
    "green": "#A3BE8C",
    "yellow": "#EBCB8B",
    "blue": "#81A1C1",
    "purple": "#B48EAD",
    "cyan": "#88C0D0",
    "white": "#E5E9F0",
    "brightBlack": "#4C566A",
    "brightRed": "#BF616A",
    "brightGreen": "#A3BE8C",
    "brightYellow": "#EBCB8B",
    "brightBlue": "#81A1C1",
    "brightPurple": "#B48EAD",
    "brightCyan": "#8FBCBB",
    "brightWhite": "#ECEFF4",
    "background": "#2E3440",
    "foreground": "#D8DEE9",
    "selectionBackground": "#4C566A",
    "cursorColor": "#D8DEE9"
}
```

---

## ⚠️ Notes

- **Reboot after running with network reset** — `netsh winsock reset` and `netsh int ip reset` require a restart to fully apply.
- Files currently locked by running applications in `%TEMP%` are silently preserved.
- This tool does **not** delete browser data, passwords, or personal documents.

---

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built-in)
- Administrator privileges (for cleaning system temp and network resets)

---

## 📁 Files

| File | Description |
|---|---|
| `PcClean-IpReset.ps1` | Main PowerShell script with cleaning, reset logic, and UI |
| `RunPcClean.bat` | Launcher script with UAC elevation and argument forwarding |
| `LICENSE` | MIT License |

---

## 📄 License

[MIT](LICENSE) — free to use, modify, and distribute.

---

<div align="center">
Made by <strong>Harindu Jayakody</strong>
</div>
