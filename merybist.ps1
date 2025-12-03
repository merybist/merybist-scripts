# Interactive Windows fast-setup installer by merybist

$apps = @(
    @{ 
        Name = "Chrome"
        Url = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/ChromeSetup.exe"
        Args = ""
        InstallPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    },
    @{ 
        Name = "WinRAR"
        Url = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/winrar.exe"
        Args = "/S"
        InstallPath = "C:\Program Files\WinRAR\WinRAR.exe"
    },
    @{ 
        Name = "Telegram | DirectLink"
        Url = "https://td.telegram.org/tx64/tsetup-x64.6.3.4.exe"
        Args = ""
        InstallPath = "$env:USERPROFILE\AppData\Roaming\Telegram Desktop\Telegram.exe"
    },
    @{ 
        Name = "Dolphin Emulator | DirectLink"
        Url = "https://dolphin-anty-cdn.com/anty-app/dolphin-anty-win-latest.exe"
        Args = "/S"
        InstallPath = "C:\Program Files\Dolphin\Dolphin.exe"
    },
    @{ 
        Name = "Visual Studio Code | DirectLink"
        Url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        Args = "--silent"
        InstallPath = "$env:USERPROFILE\AppData\Local\Programs\Microsoft VS Code\Code.exe"
    },
    @{ 
        Name = "Spotify"
        Url = "https://github.com/merybist/merybist-scripts/raw/refs/heads/main/Soft/SpotifySetup.exe"
        Args = "/silent"
        InstallPath = "$env:USERPROFILE\AppData\Roaming\Spotify\Spotify.exe"
    }
)

function Show-Menu {
    Clear-Host
    Write-Host "=== merybist Windows Fast Installer ===`n"
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $app = $apps[$i]
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

    if (!(Test-Path $targetPath)) {
        Write-Host "Downloading $($app.Name)..."
        try {
            Start-BitsTransfer -Source $app.Url -Destination $targetPath
        }
        catch {
            Write-Host "ERROR downloading $($app.Name): $_" -ForegroundColor Red
            return
        }
    } else {
        Write-Host "$($app.Name) already cached, skipping download." -ForegroundColor Yellow
    }

    Write-Host "Installing $($app.Name)..."
    if ($app.Args -ne "") {
        Start-Process -FilePath $targetPath -ArgumentList $app.Args -Wait
    }
    else {
        Start-Process -FilePath $targetPath -Wait
    }
    Write-Host "$($app.Name) install finished.`n" -ForegroundColor Cyan
}

do {
    Show-Menu
    $input = Read-Host "Enter your choice"
    if ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le $apps.Count) {
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
