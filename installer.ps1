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
        Name = "Utilities"
        Protected = $false
        Apps = @(
            @{
                Name = "WinRAR"
                Url  = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/winrar.exe"
                Args = "/S"
                InstallPath = "C:\Program Files\WinRAR\WinRAR.exe"
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
                Args = ""
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
                Url = "https://soft.merybist.pp.ua/merybist.ps1"
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
        if ($app.InstallPath -and (Test-Path $app.InstallPath)) {
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

    if (Test-Path $app.InstallPath) {
        Write-Host "$($app.Name) already installed." -ForegroundColor Green
        return
    }

    $dir = "$env:TEMP\merybist-installer"
    if (!(Test-Path $dir)) { New-Item $dir -ItemType Directory | Out-Null }

    $file = ($app.Url.Split('/')[-1])
    if ($file -notmatch "\.exe$") {
        $file = ($app.Name -replace '[^\w]', '') + ".exe"
    }

    if ($app.Type -eq "command") {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "irm $($app.Url) | iex"
        return
    }

    if ($app.Type -eq "cmd") {
        Start-Process -FilePath "cmd.exe" -ArgumentList "-NoExit""
        return
    }


    $path = Join-Path $dir $file

    if (!(Test-Path $path)) {
        Write-Host "Downloading $($app.Name)..."
        Start-BitsTransfer -Source $app.Url -Destination $path
    }

    if ($app.Name -match "Key|License") {
        Copy-Item $path $app.InstallPath -Force
        Write-Host "License applied." -ForegroundColor Green
        return
    }

    Write-Host "Installing $($app.Name)..."
    Start-Process $path $app.Args -Wait
}

# =========================
# Main loop
# =========================
do {
    Show-CategoryMenu
    $c = Read-Host "Select category"

    if ($c -eq '0') { break }

    if ($c -match '^\d+$' -and $c -le $Categories.Count) {
        $cat = $Categories[[int]$c - 1]
        if (-not (Check-CategoryAccess $cat)) { continue }

        do {
            Show-AppMenu $cat
            $a = Read-Host "Select app"

            if ($a -eq '0') { break }

            if ($a -match '^\d+$' -and $a -le $cat.Apps.Count) {
                Install-App $cat.Apps[[int]$a - 1]
                Write-Host "Press any key..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        } while ($true)
    }
} while ($true)
