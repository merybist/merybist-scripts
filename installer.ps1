# merybist Windows Fast Installer
# Single-file version with categories and protected section

# =========================
# Hash helper
# =========================
function Get-SHA256Hash {
    param([string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
}

# =========================
# Categories & Apps
# =========================
$Categories = @(
    @{
        Name = "Browsers"
        Protected = $false
        Apps = @(
            @{
                Name = "Google Chrome"
                Url  = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/ChromeSetup.exe"
                Args = ""
                InstallPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
            }
        )
    },

    @{
        Name = "Messengers"
        Protected = $false
        Apps = @(
            @{
                Name = "Telegram"
                Url  = "https://td.telegram.org/tx64/tsetup-x64.6.3.4.exe"
                Args = ""
                InstallPath = "$env:APPDATA\Telegram Desktop\Telegram.exe"
            },
            @{
                Name = "iMe"
                Url  = "https://imem.app/download/desktop/win64"
                Args = "/S"
                InstallPath = "$env:LOCALAPPDATA\iMe\iMe.exe"
            }
        )
    },

    @{
        Name = "Development"
        Protected = $false
        Apps = @(
            @{
                Name = "Visual Studio Code"
                Url  = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
                Args = "--silent --mergetasks=!runcode"
                InstallPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
            }
        )
    },

    @{
        Name = "Education & Coding"
        Protected = $false
        Apps = @(
            @{
                Name = "Scratch"
                Url  = "https://downloads.scratch.mit.edu/desktop/Scratch%20Setup.exe"
                Args = ""
                InstallPath = "C:\Program Files\Scratch 3\Scratch.exe"
            },
            @{
                Name = "Thonny"
                Url  = "https://github.com/thonny/thonny/releases/download/v4.1.7/thonny-4.1.7.exe"
                Args = ""
                InstallPath = "C:\Program Files\Thonny\thonny.exe"
            },
            @{
                Name = "Python 3.14"
                Url  = "https://www.python.org/ftp/python/3.14.2/python-3.14.2-amd64.exe"
                Args = ""
                InstallPath = "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe"
            },
            @{
               Name = "SketchUp"
               Url = "https://sketchup.trimble.com/sketchup/2026/SketchUpPro-exe"
               Args = ""
               InstallPath = "C:\Program Files\SketchUp"
            }
        )
    },

    @{
        Name = "Creative & Design"
        Protected = $false
        Apps = @(
            @{
                Name = "Paint.NET"
                Url  = "https://github.com/paintdotnet/release/releases/download/v5.1.11/paint.net.5.1.11.install.x64.zip"
                Args = ""
                InstallPath = "C:\Program Files\paint.net\PaintDotNet.exe"
                Type = "zip"
                InstallerExe = "paint.net.5.1.11.install.x64.exe"
            },
            @{
                Name = "Inkscape"
                Url  = "https://inkscape.org/gallery/item/58917/inkscape-1.4.3.msi"
                Args = ""
                InstallPath = "C:\Program Files\Inkscape\bin\inkscape-1.4.3.msi"
            }
        )
    },

    @{
        Name = "Audio"
        Protected = $false
        Apps = @(
            @{
                Name = "Audacity"
                Url  = "https://github.com/audacity/audacity/releases/download/Audacity-3.7.7/audacity-win-3.7.7-64bit.exe"
                Args = ""
                InstallPath = "C:\Program Files\Audacity\audacity.exe"
            }
        )
    },

    @{
        Name = "Video"
        Protected = $false
        Apps = @(
            @{
                Name = "CapCut"
                Url  = "https://www.capcut.com/activity/download_pc"
                InstallPath = ""
                Type = "open"
            }
        )
    },

    @{
        Name = "Utilities"
        Protected = $false
        Apps = @(
            @{
                Name = "WinRAR"
                Url  = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/winrar.exe"
                Args = "/S"
                InstallPath = "C:\Program Files\WinRAR\WinRAR.exe"
            },
            @{
                Name = "Notepad++"
                Url  = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.9/npp.8.9.Installer.x64.exe"
                Args = "/S"
                InstallPath = "C:\Program Files\Notepad++\notepad++.exe"
            }
        )
    },

    @{
        Name = "Activate Windows & Office"
        Protected = $false
        Apps = @(
            @{
                Name = "Activate Windows & Office"
                Url = "https://raw.githubusercontent.com/merybist/merybist-scripts/refs/heads/main/activate.cmd"
                InstallPath = ""
                Type = "cmd"
            }
        )
    },

    @{
        Name = "Optimization by merybist"
        Protected = $true
        PasswordHash = "25f06c7f42032ca027b5ae6b0d2d3b052ff6056ceec9b07be7e72874cc963783"
        Apps = @(
            @{
                Name = "WinRAR License Key"
                Url  = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/rarreg.key"
                Args = ""
                InstallPath = "C:\Program Files\WinRAR\rarreg.key"
            },
            @{
                Name = "Optimization by merybist"
                Url = "https://raw.githubusercontent.com/merybist/merybist-scripts/refs/heads/main/optimization.ps1"
                Args = ""
                Type = "command"
            },
            @{
                Name = "Sparkle"
                Url = "https://raw.githubusercontent.com/Parcoil/Sparkle/v2/get.ps1"
                Args = ""
                Type = "command"
            },
            @{
                Name = "W10Tweaker"
                Url = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/W10Tweaker.exe"
                Args = ""
                InstallPath = "C:\"
            },
            @{
                Name = "RemWinAi"
                Url = "https://raw.githubusercontent.com/merybist/merybist-scripts/refs/heads/main/Soft/RemWinAi.ps1"
                Args = ""
                Type = "command"
            }
        )
    }
)

# =========================
# UI functions
# =========================
function Show-CategoryMenu {
    Clear-Host
    Write-Host "merybist Windows Fast Installer" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Categories.Count; $i++) {
        $cat = $Categories[$i]
        if ($cat.Protected) {
            Write-Host "$($i+1). $($cat.Name) (protected)" -ForegroundColor Red
        } else {
            Write-Host "$($i+1). $($cat.Name)" -ForegroundColor Yellow
        }
    }

    Write-Host "0. Exit"
}

function Show-AppMenu {
    param($Category)

    Clear-Host
    Write-Host $Category.Name -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Category.Apps.Count; $i++) {
        $app = $Category.Apps[$i]

        $installed = $false
        if ($app.PSObject.Properties.Match('InstallPath').Count -gt 0 -and
            -not [string]::IsNullOrWhiteSpace($app.InstallPath) -and
            (Test-Path $app.InstallPath)) {
            $installed = $true
        }

        if ($installed) {
            Write-Host "$($i+1). $($app.Name) [Installed]" -ForegroundColor Green
        } else {
            Write-Host "$($i+1). $($app.Name)"
        }
    }

    Write-Host "0. Back"
}

# =========================
# Access control
# =========================
function Check-CategoryAccess {
    param($Category)

    if (-not $Category.Protected) { return $true }

    $secure = Read-Host "Enter password" -AsSecureString
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )

    if ((Get-SHA256Hash $plain) -eq $Category.PasswordHash) {
        return $true
    }

    Write-Host "Wrong password." -ForegroundColor Red
    Start-Sleep 2
    return $false
}

# =========================
# Installer
# =========================
function Install-App {
    param($app)

    # If InstallPath is present and exists - treat as installed
    if ($app.PSObject.Properties.Match('InstallPath').Count -gt 0 -and
        -not [string]::IsNullOrWhiteSpace($app.InstallPath) -and
        (Test-Path $app.InstallPath)) {
        Write-Host "$($app.Name) already installed." -ForegroundColor Green
        return
    }

    $dir = "$env:TEMP\merybist-installer"
    if (!(Test-Path $dir)) { New-Item $dir -ItemType Directory | Out-Null }

    $file = ($app.Url.Split('/')[-1])
    if ($file -notmatch "\.(exe|msi|zip|cmd|bat|ps1)$") {
        $file = ($app.Name -replace '[^\w]', '') + ".exe"
    }

    $path = Join-Path $dir $file

    if ($app.Type -eq "cmd") {
        $cmdDir = "C:\Windows\System32\merybist"
        if (!(Test-Path $cmdDir)) {
            New-Item $cmdDir -ItemType Directory | Out-Null
            try { attrib +h $cmdDir } catch { }
        }

        if ($file -notmatch "\.(cmd|bat)$") {
            $file = ($app.Name -replace '[^\w]', '') + ".cmd"
        }

        $path = Join-Path $cmdDir $file

        if (!(Test-Path $path)) {
            Write-Host "Downloading $($app.Name)..."
            Start-BitsTransfer -Source $app.Url -Destination $path
        }

        $cmd = "call `"$path`""
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -Wait
        return
    }

    if ($app.Type -eq "open") {
        Start-Process $app.Url
        return
    }

    if ($app.Type -eq "zip") {
        if (!(Test-Path $path)) {
            Write-Host "Downloading $($app.Name)..."
            Start-BitsTransfer -Source $app.Url -Destination $path
        }

        $extractDir = Join-Path $dir (($app.Name -replace '[^\w]', '') + "-zip")
        if (!(Test-Path $extractDir)) { New-Item $extractDir -ItemType Directory | Out-Null }
        Expand-Archive -Path $path -DestinationPath $extractDir -Force

        $exe = $null
        if ($app.PSObject.Properties.Match('InstallerExe').Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($app.InstallerExe)) {
            $exe = Join-Path $extractDir $app.InstallerExe
        } else {
            $exeItem = Get-ChildItem -Path $extractDir -Filter *.exe -Recurse | Select-Object -First 1
            if ($exeItem) { $exe = $exeItem.FullName }
        }

        if ($exe -and (Test-Path $exe)) {
            Write-Host "Installing $($app.Name)..."
            if ($app.PSObject.Properties.Match('Args').Count -eq 0 -or [string]::IsNullOrWhiteSpace($app.Args)) {
                Start-Process -FilePath $exe -Wait
            } else {
                Start-Process -FilePath $exe -ArgumentList $app.Args -Wait
            }
        } else {
            Write-Host "Installer not found inside zip." -ForegroundColor Red
        }
        return
    }

    if ($app.Type -eq "command") {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-Command", "irm $($app.Url) | iex"
        return
    }

    if (!(Test-Path $path)) {
        Write-Host "Downloading $($app.Name)..."
        Start-BitsTransfer -Source $app.Url -Destination $path
    }

    if ($app.Name -match "Key|License") {
        if ($app.PSObject.Properties.Match('InstallPath').Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($app.InstallPath)) {
            Copy-Item $path $app.InstallPath -Force
            Write-Host "License applied." -ForegroundColor Green
        } else {
            Write-Host "InstallPath not set for license file." -ForegroundColor Yellow
        }
        return
    }

    Write-Host "Installing $($app.Name)..."
    if ($app.PSObject.Properties.Match('Args').Count -eq 0 -or [string]::IsNullOrWhiteSpace($app.Args)) {
        Start-Process -FilePath $path -Wait
    } else {
        Start-Process -FilePath $path -ArgumentList $app.Args -Wait
    }
}

# =========================
# Main loop
# =========================
do {
    Show-CategoryMenu
    $c = (Read-Host "Select category").Trim()

    if ($c -eq '0') { break }

    $catIndex = 0
    if ([int]::TryParse($c, [ref]$catIndex) -and $catIndex -ge 1 -and $catIndex -le $Categories.Count) {
        $cat = $Categories[$catIndex - 1]
        if (-not (Check-CategoryAccess $cat)) { continue }

        do {
            Show-AppMenu $cat
            $a = (Read-Host "Select app").Trim()

            if ($a -eq '0') { break }

            $appIndex = 0
            if ([int]::TryParse($a, [ref]$appIndex) -and $appIndex -ge 1 -and $appIndex -le $cat.Apps.Count) {
                Install-App $cat.Apps[$appIndex - 1]
                Write-Host "Press any key..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        } while ($true)
    } else {
        Write-Host "Invalid category input: '$c'" -ForegroundColor Red
        Start-Sleep 1
    }
} while ($true)
