# 🧹 PC Clean & IP Reset

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-A3BE8C?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0-88C0D0?style=for-the-badge)

**A Nord-themed terminal tool that cleans Windows system junk and fully resets the network stack — with a detailed before/after report of everything deleted.**

*by [Harindu Jayakody](https://github.com/harindu)*

</div>

---

## ✨ Features

- 🗑️ **Cleans system temp folders** — `%TEMP%`, `C:\Windows\Temp`, `C:\Windows\Prefetch`
- 🌐 **Full network stack reset** — releases IP, flushes DNS, renews IP, resets Winsock & TCP/IP
- 📊 **Before / After report** — shows exactly how much space was freed per location
- ✅ **Confirm before clean** — tells you how much junk was found before touching anything
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

  ► Found 1,240.83 MB of junk to clean.
  ► Proceed? [Y] Yes   [N] No  :

  ╭── CLEANING SYSTEM JUNK ───────────────────────────────╮
  │  ► Cleaning User Temp (%TEMP%)       1,208.54 MB freed
  │  ► Cleaning Windows Temp                24.19 MB freed
  │  ► Cleaning Prefetch Cache               8.10 MB freed
  ╰───────────────────────────────────────────────────────╯

  ╭── RESETTING NETWORK ──────────────────────────────────╮
  │  ► Releasing IP address              done
  │  ► Flushing DNS cache                done
  │  ► Renewing IP address               done
  │  ► Resetting Winsock                 done
  │  ► Resetting TCP/IP stack            done
  ╰───────────────────────────────────────────────────────╯

  ╭── SUMMARY REPORT ─────────────────────────────────────╮
  │ SYSTEM JUNK CLEANED                                   │
  ├───────────────────────────────────────────────────────┤
  │   Location                 Before     After    Freed  │
  ├───────────────────────────────────────────────────────┤
  │ ✔ User Temp (%TEMP%)    1208.5 MB   0.0 MB  1208.5 MB │
  │ ✔ Windows Temp            24.2 MB   0.0 MB    24.2 MB │
  │ ✔ Prefetch Cache           8.1 MB   0.0 MB     8.1 MB │
  ├───────────────────────────────────────────────────────┤
  │ TOTAL FREED  1,240.83 MB  (1.212 GB)                  │
  ╰───────────────────────────────────────────────────────╯

  ╭───────────────────────────────────────────────────────╮
  │ ✔  Freed:  1,240.83 MB  (1.212 GB)                   │
  │ ✔  Network stack has been reset.                     │
  │ ⚠  Reboot recommended for network changes.           │
  ╰───────────────────────────────────────────────────────╯
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

> **When to use this:** Slow internet, websites not loading, DNS errors, IP conflicts, VPN issues, or after malware removal.

---

## 🗑️ What Gets Cleaned

| Location | Path |
|---|---|
| User Temp | `%TEMP%` |
| Windows Temp | `C:\Windows\Temp` |
| Prefetch Cache | `C:\Windows\Prefetch` |

Folders are deleted and immediately recreated (same behaviour as the original `.bat` — `rd /s /q` + `mkdir`).

---

## 🚀 Quick Start

### 1. Download

```
PcClean-IpReset/
├── PcClean-IpReset.ps1   ← main script
└── RunPcClean.bat         ← launcher (double-click this)
```

### 2. Run

Double-click **`RunPcClean.bat`**

- Auto-requests Administrator privileges
- Opens in **Windows Terminal** (falls back to PowerShell if WT not installed)
- Shows how much space will be freed before doing anything
- Reboot after running for network changes to fully take effect

> ⚠️ Administrator is required for `C:\Windows\Temp`, Prefetch, and network stack reset.

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

- **Reboot after running** — `netsh winsock reset` and `netsh int ip reset` require a restart to fully apply
- Some files in `%TEMP%` may be locked by running apps — those are silently skipped and will be cleaned next run
- This tool does **not** touch browser data, cookies, passwords, or any user files

---

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built-in)
- Administrator privileges

---

## 📁 Files

| File | Description |
|---|---|
| `PcClean-IpReset.ps1` | Main script — all cleaning, network reset, and report logic |
| `RunPcClean.bat` | Launcher — UAC elevation + Windows Terminal |

---

## 📄 License

MIT — free to use, modify, and distribute.

---

<div align="center">
Made by <strong>Harindu Jayakody</strong>
</div>
