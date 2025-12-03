# merybist-scripts

**merybist-scripts** repository contains PowerShell scripts for fast Windows initial setup and optimization. The main feature is an interactive installer script that allows you to choose which programs to install.

## Usage

To run the main installer, open PowerShell **as Administrator** and execute:

```
powershell
irm https://soft.merybist.pp.ua/file.ps1 | iex
```

This will launch an interactive menu to install selected applications (e.g. Chrome, WinRAR, Telegram, Dolphin Emulator, Visual Studio Code, Spotify).

## Features

- **Interactive program selection:** Choose which software to install; after each operation you can return to the main menu to select more.
- **Checks if apps are already installed:** If a program is found on your system, you’ll see a message and the app is skipped.
- **Safe to run multiple times:** Will only install missing apps.
- **Automatic downloading and installation:** Uses official sources.

## Other scripts

- [`optimization.ps1`](https://github.com/merybist/merybist-scripts/blob/main/optimization.ps1): Tweaks system settings to improve Windows performance, disables unnecessary services, cleans temp files.

## Requirements

- Windows 10/11
- PowerShell 5.x or later
- Administrator rights (recommended)

## License

Open for personal and educational use.

---

For questions and suggestions, use GitHub Issues.
