# Interactive Windows fast-setup installer by merybist

$apps = @(
    @{ 
        Name = "Chrome"
        Url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        Args = "/silent /install"
        InstallPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    },
    @{ 
        Name = "WinRAR"
        Url = "https://www.rarlab.com/rar/winrar-x64-713uk.exe"
        Args = "/S"
        InstallPath = "C:\Program Files\WinRAR\WinRAR.exe"
    },
    @{ 
        Name = "Telegram"
        Url = "https://telegram.org/dl/desktop/win"
        Args = ""
        InstallPath = "$env:USERPROFILE\AppData\Roaming\Telegram Desktop\Telegram.exe"
    },
    @{ 
        Name = "Dolphin Emulator"
        Url = "https://app.dolphin-anti-mirror3.net/anty-app/dolphin-anty-win-latest.exe?t=1764717643528"
        Args = "/S"
        InstallPath = "C:\Program Files\Dolphin\Dolphin.exe"
    },
    @{ 
        Name = "Visual Studio Code"
        Url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        Args = "/silent"
        InstallPath = "$env:USERPROFILE\AppData\Local\Programs\Microsoft VS Code\Code.exe"
    },
    @{ 
        Name = "Spotify"
        Url = "https://download.scdn.co/SpotifySetup.exe"
        Args = "/silent"
        InstallPath = "$env:USERPROFILE\AppData\Roaming\Spotify\Spotify.exe"
    }
)

function Show-Menu {
    Clear-Host
    Write-Host "=== merybist Windows Fast Installer ===`n"
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $app = $apps[$i]
        # Check if installed
        if (Test-Path $app.InstallPath) {
            Write-Host "$($i+1). $($app.Name) [INSTALLED]" -ForegroundColor Green
        }
        else {
            Write-Host "$($i+1). $($app.Name)" -ForegroundColor Yellow
        }
    }
    Write-Host "0. Exit`n"
    Write-Host "Select a program number to install:"
}

function Install-App {
    param($app)
    if (Test-Path $app.InstallPath) {
        Write-Host "$($app.Name) is already installed. Skipping." -ForegroundColor Green
        return
    }
    $downloadDir = "$env:TEMP\merybist-installer"
    if (!(Test-Path $downloadDir)) { New-Item -Path $downloadDir -ItemType Directory | Out-Null }
    $fileName = $app.Url.Split('/')[-1]
    $targetPath = Join-Path $downloadDir $fileName
    Write-Host "Downloading $($app.Name)..."
    try {
        Invoke-WebRequest $app.Url -OutFile $targetPath
        Write-Host "Installing $($app.Name)..."
        if ($app.Args -ne "") {
            Start-Process -FilePath $targetPath -ArgumentList $app.Args -Wait
        }
        else {
            Start-Process -FilePath $targetPath -Wait
        }
        Write-Host "$($app.Name) install finished.`n" -ForegroundColor Cyan
    }
    catch {
        Write-Host "ERROR installing $($app.Name): $_" -ForegroundColor Red
    }
}

do {
    Show-Menu
    $input = Read-Host "Enter your choice"
    if ($input -match '^(\d+)$' -and [int]$input -ge 1 -and [int]$input -le $apps.Count) {
        Install-App $apps[[int]$input-1]
        Write-Host "`nPress any key to return to menu..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    elseif ($input -eq '0') {
        Write-Host "Exiting installer. Bye!"
        break
    }
    else {
        Write-Host "Invalid selection. Try again."
        Start-Sleep -Seconds 2
    }
} while ($true)