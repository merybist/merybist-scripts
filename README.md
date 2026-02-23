
# WinTools

> Fast Windows initial setup — interactive app installer + system optimizer.

<img src="https://socialify.git.ci/merybist/wintools/image?custom_language=PowerShell&font=Bitter&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F86554244%3Fv%3D4&name=1&owner=1&pattern=Circuit+Board&stargazers=1&theme=Dark" alt="wintools" width="640" height="320" class="center" />

---

## Quick Start

Open PowerShell **as Administrator** and run:

```powershell
# Installer
irm https://soft.merybist.pp.ua/installer.ps1 -OutFile $env:TEMP\install.ps1; pwsh -File $env:TEMP\install.ps1

# Optimizer
irm https://soft.merybist.pp.ua/optimization.ps1 -OutFile $env:TEMP\optimize.ps1; pwsh -File $env:TEMP\optimize.ps1
```

**Requirements:** Windows 10 / 11 · PowerShell 5.1+ · Administrator rights · [winget](https://aka.ms/getwinget)

---

## installer.ps1

Full-screen TUI with real-time search across 120+ apps.

```
  merybist-scripts  •  Installer              F5=update all   Esc=exit
  🔍  git▌                  type name or category  •  cat:dev  cat:gaming  •  ↑↓ Space Tab Enter
     NAME                                              CATEGORY
  ──────────────────────────────────────────────────────────────────
   ○  Git                                              [Dev]
   ◉  GitHub Desktop                                   [Dev]
   ○  ...
```

**Controls**

| Key | Action |
|-----|--------|
| Type anything | Filter by name or category in real time |
| `cat:dev` / `cat gaming` / `category media` | Filter by exact category |
| `↑` `↓` `PgUp` `PgDn` `Home` `End` | Navigate the list |
| `Space` | Check / uncheck app |
| `Tab` | Select all / deselect all visible |
| `Enter` | Install checked apps (or current if none checked) |
| `Backspace` | Delete last search character |
| `Esc` | Clear search → exit |
| `F5` | `winget upgrade --all` |

**Categories**

| Category | Apps (examples) |
|----------|----------------|
| Browser | Chrome, Firefox, Brave, Opera GX, Tor, Vivaldi |
| Chat | Telegram, Discord, Signal, Slack, Zoom, Viber |
| Dev | VS Code, Git, Node.js, Python, Docker, Postman, JetBrains |
| Gaming | Steam, Epic, GOG, Dolphin, PPSSPP, Ryujinx, RetroArch |
| Media | Spotify, VLC, OBS Studio, foobar2000, Kdenlive, Audacity |
| Design | GIMP, Blender, Figma, Krita, Inkscape, DaVinci Resolve |
| Office | LibreOffice, Obsidian, Notion, Bitwarden, Thunderbird |
| Security | Malwarebytes, Wireshark, WireGuard, VeraCrypt, Nmap |
| Utils | PowerToys, Everything, CPU-Z, HWiNFO, Rufus, ShareX |

---

## optimization.ps1

Menu-driven optimizer — pick individual modules or run everything at once.

```
  [1]  ⚡ Performance    power plan, SvcHostSplitThresholdInKB, PowerThrottling...
  [2]  🔒 Privacy        telemetry, Cortana, camera, error reporting...
  [3]  🚀 Services       disable 17 unnecessary Windows services
  [4]  🗑  Junk Cleaner  temp files, prefetch, WU cache, Disk Cleanup
  [5]  🌐 Network        DNS picker, IRPStackSize, Nagle, QoS, TCP tweaks
  [6]  🗂  Explorer & UI  MenuShowDelay, dark mode, classic menu, OneDrive
  [A]  ✅ Run ALL        (creates registry backup on Desktop first)
  [B]  💾 Backup registry only
```

**What each module does**

<details>
<summary>⚡ Performance</summary>

- Activates **Ultimate Performance** power plan (or High Performance as fallback)
- Sets **`SvcHostSplitThresholdInKB`** to your RAM size — reduces 80+ svchost processes down to a sane number
- **`SystemResponsiveness`** 20 → 10 — gives more CPU to the foreground app via MMCSS
- **`PowerThrottlingOff`** — stops Windows from throttling background processes
- **`WaitToKillServiceTimeout`** 5000 → 2000 ms — faster shutdown
- **`StartupDelayInMSec = 0`** — removes artificial startup app delay
- Disables SysMain (Superfetch), Fast Startup, Hibernate, Game DVR
- Reduces visual effects, disables transparency

</details>

<details>
<summary>🔒 Privacy</summary>

- Disables telemetry, Cortana, Advertising ID, Activity History
- Blocks app access to camera and microphone
- Disables tailored experiences, feedback prompts, error reporting
- Disables app launch tracking and Remote Assistance

</details>

<details>
<summary>🚀 Services</summary>

Disables 17 services: DiagTrack, dmwappushservice, MapsBroker, lfsvc, RetailDemo, WbioSrvc, XblAuthManager, XblGameSave, XboxNetApiSvc, XboxGipSvc, wisvc, WMPNetworkSvc, Fax, RemoteRegistry, TrkWks, SysMain, WSearch.

</details>

<details>
<summary>🗑 Junk Cleaner</summary>

Cleans: User Temp, System Temp, Prefetch, IE/Edge Cache, Local Temp, Windows Update download cache, Error Reports, Thumbnail Cache, Delivery Optimization cache. Empties Recycle Bin. Runs Windows Disk Cleanup silently.

</details>

<details>
<summary>🌐 Network</summary>

- Interactive **DNS picker**: Cloudflare `1.1.1.1`, Google `8.8.8.8`, or Quad9 `9.9.9.9`
- **`IRPStackSize = 32`** (LanmanServer) — more simultaneous I/O buffers, better file sharing throughput
- **Nagle off** (`TCPNoDelay`, `TcpAckFrequency = 1`) — lower latency
- **QoS bandwidth reserve removed** — Windows reserves up to 20% by default, this frees it
- TCP: SACK enabled, ECN on, auto-tuning normal

</details>

<details>
<summary>🗂 Explorer & UI</summary>

- Show file extensions and hidden files
- **`MenuShowDelay`** 400 → 50 ms — right-click menus appear instantly
- Disable Bing in Start Menu, lock screen ads, Start suggestions, News & Interests
- Enable dark mode
- Restore **classic right-click context menu** on Windows 11
- Remove OneDrive from Explorer sidebar
- Taskbar left-align (Windows 11)

</details>

---

## File structure

```
merybist-scripts/
├── installer.ps1      TUI app installer (120+ apps, real-time search)
├── optimization.ps1   System optimizer (6 modules, registry tweaks)
├── activate.cmd       Helper launcher
└── Soft/              Additional configs
```

---

## License

Open for personal and educational use.

