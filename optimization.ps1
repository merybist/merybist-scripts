<# 
Ultimate Windows Optimization by merybist v3.0
- Windows PowerShell 5.1 compatible
- ASCII only output
- Aggressive performance oriented
- Auto mode asks y/n before each change
Run as Administrator recommended.
#>

$ErrorActionPreference = "SilentlyContinue"
$ConfirmPreference = "None"

$Root = "C:\merybist-opt"
$LogPath = Join-Path $Root "opt.log"
$SvcBackupPath = Join-Path $Root "services_backup.json"
New-Item -ItemType Directory -Path $Root -Force | Out-Null

function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "Gray"
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[" + $ts + "] " + $Message
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $line
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Prompt-YesNo {
    param(
        [string]$Question,
        [string]$Default = "N"  # Y or N
    )

    $d = $Default.ToUpper()
    $suffix = ""
    if ($d -eq "Y") { $suffix = "[Y/n]" } else { $suffix = "[y/N]" }

    while ($true) {
        $ans = Read-Host ($Question + " " + $suffix)
        if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $d }

        $ans = $ans.Trim().ToUpper()
        if ($ans -eq "Y") { return $true }
        if ($ans -eq "N") { return $false }
        Write-Host "Please type Y or N." -ForegroundColor Yellow
    }
}

function Ensure-RegKey {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Safe-SetReg {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    Ensure-RegKey $Path
    try {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    } catch {
        try { Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null } catch {}
    }
}

function Safe-DelRegValue {
    param(
        [string]$Path,
        [string]$Name
    )
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        }
    } catch {}
}

function Get-SystemProfile {
    $p = [ordered]@{
        OS          = "Unknown"
        Version     = ""
        Build       = ""
        IsWindows11 = $false
        Device      = "Desktop"
        Storage     = "Unknown"
        HasWinget   = $false
    }

    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $p.OS      = $os.Caption
        $p.Version = $os.Version
        $p.Build   = $os.BuildNumber
        if (($os.Caption -match "Windows 11") -or ([version]$os.Version -ge [version]"10.0.22000")) {
            $p.IsWindows11 = $true
        }
    } catch {}

    # Laptop detection (best-effort)
    try {
        $enc = Get-CimInstance Win32_SystemEnclosure
        $chassis = @()
        if ($enc -and $enc.ChassisTypes) { $chassis = $enc.ChassisTypes }
        # Common laptop chassis types: 8 (Portable), 9 (Laptop), 10 (Notebook), 14 (SubNotebook)
        $isLaptop = $false
        foreach ($t in $chassis) {
            if ($t -in @(8,9,10,14)) { $isLaptop = $true }
        }
        if ($isLaptop) { $p.Device = "Laptop" } else { $p.Device = "Desktop" }
    } catch {}

    # Storage detection (best-effort)
    try {
        $physical = Get-PhysicalDisk
        if ($physical) {
            $ssd = $physical | Where-Object { $_.MediaType -eq "SSD" }
            $hdd = $physical | Where-Object { $_.MediaType -eq "HDD" }
            if ($ssd.Count -gt 0 -and $hdd.Count -eq 0) { $p.Storage = "SSD" }
            elseif ($hdd.Count -gt 0 -and $ssd.Count -eq 0) { $p.Storage = "HDD" }
            elseif ($ssd.Count -gt 0 -and $hdd.Count -gt 0) { $p.Storage = "Mixed" }
        }
    } catch {}

    try {
        $w = Get-Command winget -ErrorAction SilentlyContinue
        if ($w) { $p.HasWinget = $true }
    } catch {}

    return $p
}

# -------------------------
# Services (Aggressive)
# -------------------------
$AggressiveServices = @(
    "DiagTrack",
    "dmwappushservice",
    "SysMain",
    "WSearch",
    "WerSvc",
    "WMPNetworkSvc",
    "workfolderssvc",
    "RemoteRegistry",
    "MapsBroker",
    "Fax",
    "RetailDemo",
    "WpnService",
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc",
    "XboxGipSvc"
)

function Get-ServiceStartType {
    param([string]$Name)
    try {
        $svc = Get-CimInstance Win32_Service -Filter ("Name='" + $Name + "'")
        if ($svc) { return $svc.StartMode } # Auto, Manual, Disabled
    } catch {}
    return $null
}

function Set-ServiceStartType {
    param(
        [string]$Name,
        [string]$Mode # Automatic, Manual, Disabled
    )
    try {
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (-not $svc) { return $false }
        if ($Mode -eq "Disabled") {
            try { Stop-Service -Name $Name -Force | Out-Null } catch {}
            Set-Service -Name $Name -StartupType Disabled | Out-Null
            return $true
        }
        if ($Mode -eq "Manual") {
            Set-Service -Name $Name -StartupType Manual | Out-Null
            return $true
        }
        if ($Mode -eq "Automatic") {
            Set-Service -Name $Name -StartupType Automatic | Out-Null
            try { Start-Service -Name $Name | Out-Null } catch {}
            return $true
        }
    } catch {}
    return $false
}

function Action-DisableAggressiveServices {
    Write-Log "Aggressive services disable selected." "Yellow"
    Write-Log "WARNING: Disabling services can break Windows features (search, updates behavior, Xbox features, notifications). Use at your own risk." "Red"

    $backup = @()
    foreach ($s in $AggressiveServices) {
        $start = Get-ServiceStartType -Name $s
        if ($start) {
            $backup += [pscustomobject]@{ Name = $s; StartMode = $start }
        }
    }

    try {
        $backup | ConvertTo-Json -Depth 4 | Set-Content -Path $SvcBackupPath -Encoding UTF8
        Write-Log "Saved services backup to: $SvcBackupPath" "Green"
    } catch {
        Write-Log "Failed to save services backup. Restore may not work." "DarkYellow"
    }

    foreach ($s in $AggressiveServices) {
        $ok = Set-ServiceStartType -Name $s -Mode "Disabled"
        if ($ok) { Write-Log ("Disabled service: " + $s) "Green" }
        else { Write-Log ("Skip/Failed: " + $s) "DarkYellow" }
    }
}

function Action-RestoreAggressiveServices {
    Write-Log "Restoring services from backup..." "Yellow"
    if (-not (Test-Path $SvcBackupPath)) {
        Write-Log "Backup not found: $SvcBackupPath" "Red"
        return
    }

    $data = $null
    try { $data = Get-Content $SvcBackupPath -Raw | ConvertFrom-Json } catch {}
    if (-not $data) {
        Write-Log "Backup file is invalid." "Red"
        return
    }

    foreach ($item in $data) {
        $name = $item.Name
        $mode = $item.StartMode
        if (-not $name -or -not $mode) { continue }

        # Map Win32 startmodes
        $target = "Manual"
        if ($mode -eq "Auto") { $target = "Automatic" }
        elseif ($mode -eq "Manual") { $target = "Manual" }
        elseif ($mode -eq "Disabled") { $target = "Disabled" }

        $ok = Set-ServiceStartType -Name $name -Mode $target
        if ($ok) { Write-Log ("Restored service: " + $name + " -> " + $target) "Green" }
        else { Write-Log ("Failed restore: " + $name) "DarkYellow" }
    }
}

# -------------------------
# Defender / SmartScreen / UAC
# -------------------------
function Action-DisableDefender {
    Write-Log "Disabling Windows Defender (policy + services)..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 1

    foreach ($s in @("WinDefend","WdNisSvc","SecurityHealthService","wscsvc")) {
        $ok = Set-ServiceStartType -Name $s -Mode "Disabled"
        if ($ok) { Write-Log ("Disabled service: " + $s) "Green" }
    }
    Write-Log "Defender disable requested. Some Windows builds may ignore parts of this." "DarkYellow"
}

function Action-EnableDefender {
    Write-Log "Enabling Windows Defender (policy + services)..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 0

    foreach ($s in @("WinDefend","WdNisSvc","SecurityHealthService","wscsvc")) {
        $ok = Set-ServiceStartType -Name $s -Mode "Automatic"
        if ($ok) { Write-Log ("Enabled service: " + $s) "Green" }
    }
}

function Action-DisableSmartScreen {
    Write-Log "Disabling SmartScreen..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "ShellSmartScreenLevel" "Off" ([Microsoft.Win32.RegistryValueKind]::String)
    Write-Log "SmartScreen disabled." "Green"
}

function Action-EnableSmartScreen {
    Write-Log "Enabling SmartScreen..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "ShellSmartScreenLevel" "Warn" ([Microsoft.Win32.RegistryValueKind]::String)
    Write-Log "SmartScreen enabled." "Green"
}

function Action-DisableUAC {
    Write-Log "Disabling UAC (reboot required)..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0
    Write-Log "UAC disabled (reboot required)." "Green"
}

function Action-EnableUAC {
    Write-Log "Enabling UAC (reboot required)..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
    Write-Log "UAC enabled (reboot required)." "Green"
}

# -------------------------
# Keep your Basic Registry Tweaks (Menu 6)
# -------------------------
function Action-RegistryPerformanceTweaks {
    Write-Log "Applying registry performance tweaks (basic)..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0
    Write-Log "Basic registry tweaks applied." "Green"
}

function Action-RegistryRestoreDefaults {
    Write-Log "Restoring registry defaults (basic)..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 1
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 3
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 3
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 1
    Write-Log "Basic registry defaults restored." "Green"
}

# -------------------------
# Sparkle-based Tweaks (Apply/Unapply)
# -------------------------

function Tweak-SetWin32PrioritySeparation {
    param([string]$Mode) # Apply / Unapply
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type DWord -Value 36
        Write-Log "Win32PrioritySeparation set to 36." "Green"   # Sparkle apply :contentReference[oaicite:12]{index=12}
    } else {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Type DWord -Value 2
        Write-Log "Win32PrioritySeparation restored to 2." "Green" # Sparkle unapply :contentReference[oaicite:13]{index=13}
    }
}

function Tweak-MenuShowDelayZero {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
        Write-Log "MenuShowDelay set to 0." "Green"  # :contentReference[oaicite:14]{index=14}
    } else {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "400"
        Write-Log "MenuShowDelay restored to 400." "Green"
    }
}

function Tweak-DisableBackgroundStoreApps {
    param([string]$Mode)
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Type DWord -Value 1
        Write-Log "Background MS Store apps disabled." "Green"   # :contentReference[oaicite:15]{index=15}
    } else {
        Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Type DWord -Value 0
        Write-Log "Background MS Store apps restored." "Green"   # :contentReference[oaicite:16]{index=16}
    }
}

function Tweak-EnableGameMode {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
        Write-Log "Game Mode enabled." "Green" # :contentReference[oaicite:17]{index=17}
    } else {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0
        Write-Log "Game Mode disabled." "Green" # :contentReference[oaicite:18]{index=18}
    }
}

function Tweak-EnableHAGS {
    param([string]$Mode)
    $regPath = "HKLM:\System\CurrentControlSet\Control\GraphicsDrivers"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path $regPath -Name "HwSchMode" -Value 2 -Type DWord
        Write-Log "HAGS enabled (HwSchMode=2). Reboot may be required." "Green" # :contentReference[oaicite:19]{index=19}
    } else {
        Set-ItemProperty -Path $regPath -Name "HwSchMode" -Value 1 -Type DWord
        Write-Log "HAGS disabled (HwSchMode=1). Reboot may be required." "Green" # :contentReference[oaicite:20]{index=20}
    }
}

<<<<<<< HEAD
function Tweak-EnableWindowedGamesOptimization {
    param([string]$Mode)
    $regPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path $regPath -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;"
        Write-Log "Optimization for windowed games enabled." "Green" # :contentReference[oaicite:21]{index=21}
    } else {
        Safe-DelRegValue -Path $regPath -Name "DirectXUserGlobalSettings"
        Write-Log "Optimization for windowed games removed." "Green" # :contentReference[oaicite:22]{index=22}
    }
}

function Tweak-DisableFastStartup {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0
        Write-Log "Fast Startup disabled (HiberbootEnabled=0)." "Green" # :contentReference[oaicite:23]{index=23}
    } else {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1
        Write-Log "Fast Startup restored (HiberbootEnabled=1)." "Green"
    }
}

function Tweak-DisableMouseAcceleration {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
        Write-Log "Mouse acceleration disabled." "Green" # :contentReference[oaicite:24]{index=24}
    } else {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10"
        Write-Log "Mouse acceleration restored." "Green" # :contentReference[oaicite:25]{index=25}
    }
}

function Tweak-DisableWifiSense {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Ensure-RegKey "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        Ensure-RegKey "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
        Write-Log "Wi-Fi Sense disabled." "Green" # :contentReference[oaicite:26]{index=26}
    } else {
        Ensure-RegKey "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        Ensure-RegKey "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 1
        Write-Log "Wi-Fi Sense restored." "Green" # :contentReference[oaicite:27]{index=27}
    }
}

function Tweak-DisableDynamicTick {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        bcdedit /set disabledynamictick yes | Out-Null
        Write-Log "Dynamic Ticking disabled. Reboot recommended." "Green" # :contentReference[oaicite:28]{index=28}
    } else {
        bcdedit /set disabledynamictick no | Out-Null
        Write-Log "Dynamic Ticking restored. Reboot recommended." "Green" # :contentReference[oaicite:29]{index=29}
    }
}

function Tweak-DisableGamebarOverlay {
    param([string]$Mode)
    $p = Get-SystemProfile
    if (-not $p.HasWinget) {
        Write-Log "winget not found. Cannot reliably apply/unapply this tweak." "DarkYellow"
        return
    }

    if ($Mode -eq "Apply") {
        # Sparkle warns X3D users; we cannot detect X3D reliably -> warn always.
        Write-Log "WARNING: If you have an AMD X3D CPU, disabling Gamebar can hurt performance in some cases." "Red" # :contentReference[oaicite:30]{index=30}
        try {
            winget uninstall 9nzkpstsnw4p --silent --accept-source-agreements | Out-Null
        } catch {}
        try {
            Get-AppxPackage Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction Stop | Out-Null
            Write-Log "XboxGamingOverlay removed." "Green" # :contentReference[oaicite:31]{index=31}
        } catch {
            Write-Log "Appx removal failed; winget may still have removed it." "DarkYellow"
        }
    } else {
        try {
            winget install 9NZKPSTSNW4P --source msstore --accept-source-agreements --accept-package-agreements | Out-Null
            Write-Log "XboxGamingOverlay installed back." "Green" # :contentReference[oaicite:32]{index=32}
        } catch {
            Write-Log "Failed to reinstall XboxGamingOverlay via winget." "DarkYellow"
        }
    }
}

function Tweak-RemoveBingIntegration {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Get-AppxPackage *BingNews* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        Get-AppxPackage *BingWeather* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        Get-AppxPackage *BingFinance* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        Get-AppxPackage *BingMaps* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        Get-AppxPackage *BingSports* | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        # Disable web results in Windows Search (common approach)
        Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
        Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
        Write-Log "Bing apps removed and Bing web search disabled in Search." "Green" # :contentReference[oaicite:33]{index=33}
    } else {
        # Unapply is not perfect without Store re-install; restore toggles
        Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 1
        Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 1
        Write-Log "Search toggles restored. Bing apps reinstall may require Microsoft Store." "DarkYellow" # :contentReference[oaicite:34]{index=34}
    }
}

function Tweak-OptimizeNetworkSettings {
    param([string]$Mode)
    if ($Mode -eq "Apply") {
        Write-Log "Applying network tweaks (netsh)..." "Yellow"  # Sparkle list :contentReference[oaicite:35]{index=35}
        try { netsh int tcp set heuristics disabled | Out-Null } catch {}
        try { netsh int tcp set supplemental template=internet congestionprovider=ctcp | Out-Null } catch {}
        try { netsh int tcp set global rss=enabled | Out-Null } catch {}
        try { netsh int tcp set global ecncapability=enabled | Out-Null } catch {}
        try { netsh int tcp set global timestamps=disabled | Out-Null } catch {}
        try { netsh int tcp set global fastopen=enabled | Out-Null } catch {}
        try { netsh int tcp set global fastopenfallback=enabled | Out-Null } catch {}
        try { netsh int tcp set supplemental template=custom icw=10 | Out-Null } catch {}

        # MTU set - only if interface exists
        $ifaces = @()
        try { $ifaces = (Get-NetIPInterface | Select-Object -ExpandProperty InterfaceAlias -Unique) } catch {}
        foreach ($name in @("Wi-Fi","Ethernet")) {
            if ($ifaces -contains $name) {
                try { netsh interface ipv4 set subinterface "$name" mtu=1500 store=persistent | Out-Null } catch {}
            }
        }

        Write-Log "Network tweaks applied." "Green"
    } else {
        Write-Log "Restoring network defaults (partial)..." "Yellow"
        try { netsh int tcp set heuristics enabled | Out-Null } catch {}
        try { netsh int tcp set global rss=default | Out-Null } catch {}
        try { netsh int tcp set global ecncapability=default | Out-Null } catch {}
        try { netsh int tcp set global timestamps=default | Out-Null } catch {}
        try { netsh int tcp set global fastopen=default | Out-Null } catch {}
        Write-Log "Network defaults restored (partial)." "Green"
    }
}

# -------------------------
# Auto Optimize (asks y/n before every action)
# -------------------------
function Action-AutoOptimize {
    $p = Get-SystemProfile
    Write-Log ("Auto Optimize profile: " + $p.OS + " Build=" + $p.Build + " Device=" + $p.Device + " Storage=" + $p.Storage) "Cyan"

    if (-not (Test-IsAdmin)) {
        Write-Log "WARNING: Not running as Admin. Some tweaks will fail." "DarkYellow"
    }

    if (Prompt-YesNo -Question "Apply basic registry performance tweaks (Menu 6)?" -Default "Y") {
        Action-RegistryPerformanceTweaks
    }

    if (Prompt-YesNo -Question "Set Win32PrioritySeparation for foreground performance?" -Default "Y") {
        Tweak-SetWin32PrioritySeparation -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Set MenuShowDelay to 0 (snappier UI)?" -Default "Y") {
        Tweak-MenuShowDelayZero -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable background activity for Microsoft Store apps?" -Default "Y") {
        Tweak-DisableBackgroundStoreApps -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Enable Game Mode? (Test if better for your games)" -Default "Y") {
        Tweak-EnableGameMode -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Enable HAGS (Hardware Accelerated GPU Scheduling)?" -Default "Y") {
        Tweak-EnableHAGS -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Enable Optimization for Windowed Games?" -Default "Y") {
        Tweak-EnableWindowedGamesOptimization -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable mouse acceleration (recommended for FPS)?" -Default "Y") {
        Tweak-DisableMouseAcceleration -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable Wi-Fi Sense?" -Default "Y") {
        Tweak-DisableWifiSense -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable Dynamic Ticking (can improve latency, uses more power)?" -Default "N") {
        Tweak-DisableDynamicTick -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable Fast Startup (stability / clean boots)?" -Default "Y") {
        Tweak-DisableFastStartup -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Apply network tweaks (netsh)?" -Default "N") {
        Tweak-OptimizeNetworkSettings -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable Gamebar by removing XboxGamingOverlay? (WARNING for AMD X3D users)" -Default "N") {
        Tweak-DisableGamebarOverlay -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Remove Bing apps and Bing web results from Search? (may require Store to restore apps)" -Default "N") {
        Tweak-RemoveBingIntegration -Mode "Apply"
    }

    if (Prompt-YesNo -Question "Disable aggressive services set? (WARNING: can break features)" -Default "N") {
        Action-DisableAggressiveServices
    }

    Write-Log "Auto Optimize complete. Reboot recommended." "Green"
}

# -------------------------
# Menus
# -------------------------
function Pause-AnyKey {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Action-ShowSystemInfo {
    $p = Get-SystemProfile
    Write-Log "System Information:" "Cyan"
    Write-Log ("OS: " + $p.OS) "White"
    Write-Log ("Version: " + $p.Version + " Build: " + $p.Build) "White"
    Write-Log ("Device: " + $p.Device + " Storage: " + $p.Storage) "White"
    try {
        $cpu = Get-CimInstance Win32_Processor
        Write-Log ("CPU: " + $cpu.Name) "White"
        Write-Log ("Cores: " + $cpu.NumberOfCores + " Logical: " + $cpu.NumberOfLogicalProcessors) "White"
    } catch {}
    try {
        $mem = Get-CimInstance Win32_ComputerSystem
        $ram = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2)
        Write-Log ("RAM: " + $ram + " GB") "White"
    } catch {}
}
=======
# ===== Menus =====
>>>>>>> parent of 29b559b (Add system-aware auto-optimization, FPS boost, and dynamic tweaks for Win10/11 + HDD/SSD)

function Show-MainMenu {
    Clear-Host
    Write-Host "-----------------------------------------------" -ForegroundColor Cyan
    Write-Host " merybist Optimization Menu v3.0 (ASCII only)  " -ForegroundColor Cyan
    Write-Host "-----------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
<<<<<<< HEAD
    Write-Host " 1. System Information" -ForegroundColor White
    Write-Host " 2. Defender / SmartScreen / UAC" -ForegroundColor Yellow
    Write-Host " 3. Aggressive Services (Disable/Restore)" -ForegroundColor Red
    Write-Host " 4. Registry Tweaks (Basic - keep)" -ForegroundColor Yellow
    Write-Host " 5. Sparkle Tweaks (Apply/Unapply)" -ForegroundColor Magenta
    Write-Host " 6. Auto Optimize (asks y/n for every change)" -ForegroundColor Green
    Write-Host " 0. Exit" -ForegroundColor DarkRed
=======
    Write-Host " 1.  System Information" -ForegroundColor White
    Write-Host " 2.  Windows Defender | UAC" -ForegroundColor Yellow
    Write-Host " 3.  Services Optimization" -ForegroundColor Yellow
    Write-Host " 4.  Background Apps & GameDVR" -ForegroundColor Yellow
    Write-Host " 5.  Visual Effects" -ForegroundColor Yellow
    Write-Host " 6.  Registry Tweaks (Basic)" -ForegroundColor Yellow
    Write-Host " 7.  Advanced Registry Tweaks" -ForegroundColor Magenta
    Write-Host " 8.  Network Tweaks" -ForegroundColor Yellow
    Write-Host " 9.  Cleanup" -ForegroundColor Yellow
    Write-Host " 10. Power Plan" -ForegroundColor Yellow
    Write-Host " 11. Restore Point" -ForegroundColor Yellow
    Write-Host " 12. Status Summary" -ForegroundColor Yellow
    Write-Host " 0.  Exit" -ForegroundColor Red
>>>>>>> parent of 29b559b (Add system-aware auto-optimization, FPS boost, and dynamic tweaks for Win10/11 + HDD/SSD)
    Write-Host ""
}

function Show-SecurityMenu {
    while ($true) {
        Clear-Host
        Write-Host "Defender / SmartScreen / UAC" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Disable Defender"
        Write-Host " 2. Enable Defender"
        Write-Host " 3. Disable SmartScreen"
        Write-Host " 4. Enable SmartScreen"
        Write-Host " 5. Disable UAC (reboot)"
        Write-Host " 6. Enable UAC (reboot)"
        Write-Host " 0. Back"
        Write-Host ""
        $c = Read-Host "Select"
        switch ($c) {
            "1" { Action-DisableDefender; Pause-AnyKey }
            "2" { Action-EnableDefender; Pause-AnyKey }
            "3" { Action-DisableSmartScreen; Pause-AnyKey }
            "4" { Action-EnableSmartScreen; Pause-AnyKey }
            "5" { Action-DisableUAC; Pause-AnyKey }
            "6" { Action-EnableUAC; Pause-AnyKey }
            "0" { return }
        }
    }
}

function Show-ServicesMenu {
    while ($true) {
        Clear-Host
        Write-Host "Aggressive Services" -ForegroundColor Red
        Write-Host ""
        Write-Host "WARNING: This can break Windows features. Use Restore if something breaks."
        Write-Host ""
        Write-Host " 1. Disable aggressive services (and create backup)"
        Write-Host " 2. Restore services from backup"
        Write-Host " 0. Back"
        Write-Host ""
        $c = Read-Host "Select"
        switch ($c) {
            "1" { Action-DisableAggressiveServices; Pause-AnyKey }
            "2" { Action-RestoreAggressiveServices; Pause-AnyKey }
            "0" { return }
        }
    }
}

function Show-BasicRegistryMenu {
    while ($true) {
        Clear-Host
        Write-Host "Registry Tweaks (Basic - keep)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Apply basic performance tweaks"
        Write-Host " 2. Restore defaults"
        Write-Host " 0. Back"
        Write-Host ""
        $c = Read-Host "Select"
        switch ($c) {
            "1" { Action-RegistryPerformanceTweaks; Pause-AnyKey }
            "2" { Action-RegistryRestoreDefaults; Pause-AnyKey }
            "0" { return }
        }
    }
}

function Show-SparkleTweaksMenu {
    while ($true) {
        Clear-Host
        Write-Host "Sparkle Tweaks (Apply/Unapply)" -ForegroundColor Magenta
        Write-Host ""
        Write-Host " 1. Win32PrioritySeparation (Apply)"
        Write-Host " 2. Win32PrioritySeparation (Unapply)"
        Write-Host " 3. MenuShowDelay Zero (Apply)"
        Write-Host " 4. MenuShowDelay (Unapply -> 400)"
        Write-Host " 5. Disable background Store apps (Apply)"
        Write-Host " 6. Disable background Store apps (Unapply)"
        Write-Host " 7. Enable Game Mode (Apply)"
        Write-Host " 8. Enable Game Mode (Unapply)"
        Write-Host " 9. Enable HAGS (Apply)"
        Write-Host "10. Enable HAGS (Unapply)"
        Write-Host "11. Windowed Games Optimization (Apply)"
        Write-Host "12. Windowed Games Optimization (Unapply)"
        Write-Host "13. Disable Mouse Acceleration (Apply)"
        Write-Host "14. Disable Mouse Acceleration (Unapply)"
        Write-Host "15. Disable Wi-Fi Sense (Apply)"
        Write-Host "16. Disable Wi-Fi Sense (Unapply)"
        Write-Host "17. Disable Dynamic Ticking (Apply)"
        Write-Host "18. Disable Dynamic Ticking (Unapply)"
        Write-Host "19. Disable Fast Startup (Apply)"
        Write-Host "20. Disable Fast Startup (Unapply)"
        Write-Host "21. Optimize Network (Apply)"
        Write-Host "22. Optimize Network (Unapply)"
        Write-Host "23. Disable Gamebar Overlay (Apply) - needs winget, X3D warning"
        Write-Host "24. Disable Gamebar Overlay (Unapply)"
        Write-Host "25. Remove Bing Integration (Apply)"
        Write-Host "26. Remove Bing Integration (Unapply)"
        Write-Host " 0. Back"
        Write-Host ""
        $c = Read-Host "Select"
        switch ($c) {
            "1" { Tweak-SetWin32PrioritySeparation Apply; Pause-AnyKey }
            "2" { Tweak-SetWin32PrioritySeparation Unapply; Pause-AnyKey }
            "3" { Tweak-MenuShowDelayZero Apply; Pause-AnyKey }
            "4" { Tweak-MenuShowDelayZero Unapply; Pause-AnyKey }
            "5" { Tweak-DisableBackgroundStoreApps Apply; Pause-AnyKey }
            "6" { Tweak-DisableBackgroundStoreApps Unapply; Pause-AnyKey }
            "7" { Tweak-EnableGameMode Apply; Pause-AnyKey }
            "8" { Tweak-EnableGameMode Unapply; Pause-AnyKey }
            "9" { Tweak-EnableHAGS Apply; Pause-AnyKey }
            "10" { Tweak-EnableHAGS Unapply; Pause-AnyKey }
            "11" { Tweak-EnableWindowedGamesOptimization Apply; Pause-AnyKey }
            "12" { Tweak-EnableWindowedGamesOptimization Unapply; Pause-AnyKey }
            "13" { Tweak-DisableMouseAcceleration Apply; Pause-AnyKey }
            "14" { Tweak-DisableMouseAcceleration Unapply; Pause-AnyKey }
            "15" { Tweak-DisableWifiSense Apply; Pause-AnyKey }
            "16" { Tweak-DisableWifiSense Unapply; Pause-AnyKey }
            "17" { Tweak-DisableDynamicTick Apply; Pause-AnyKey }
            "18" { Tweak-DisableDynamicTick Unapply; Pause-AnyKey }
            "19" { Tweak-DisableFastStartup Apply; Pause-AnyKey }
            "20" { Tweak-DisableFastStartup Unapply; Pause-AnyKey }
            "21" { Tweak-OptimizeNetworkSettings Apply; Pause-AnyKey }
            "22" { Tweak-OptimizeNetworkSettings Unapply; Pause-AnyKey }
            "23" { Tweak-DisableGamebarOverlay Apply; Pause-AnyKey }
            "24" { Tweak-DisableGamebarOverlay Unapply; Pause-AnyKey }
            "25" { Tweak-RemoveBingIntegration Apply; Pause-AnyKey }
            "26" { Tweak-RemoveBingIntegration Unapply; Pause-AnyKey }
            "0" { return }
        }
    }
}

# -------------------------
# Start
# -------------------------
Write-Log "=== Ultimate Windows Optimization by merybist v3.0 ===" "Cyan"
if (-not (Test-IsAdmin)) {
    Write-Log "NOTE: Run as Administrator for full effect." "DarkYellow"
}

while ($true) {
    Show-MainMenu
<<<<<<< HEAD
    $m = Read-Host "Select"
    switch ($m) {
        "1" { Action-ShowSystemInfo; Pause-AnyKey }
        "2" { Show-SecurityMenu }
        "3" { Show-ServicesMenu }
        "4" { Show-BasicRegistryMenu }
        "5" { Show-SparkleTweaksMenu }
        "6" { Action-AutoOptimize; Pause-AnyKey }
        "0" { Write-Log "Exit." "Cyan"; break }
=======
    $main = Read-Host "Select option"

    switch ($main) {
        '1' { Show-SystemInfoMenu }
        '2' { Show-DefenderMenu }
        '3' { Show-ServicesMenu }
        '4' { Show-BackgroundMenu }
        '5' { Show-VisualMenu }
        '6' { Show-RegistryMenu }
        '7' { Show-AdvancedTweaksMenu }
        '8' { Show-NetworkMenu }
        '9' { Show-CleanupMenu }
        '10' { Show-PowerPlanMenu }
        '11' { Show-RestoreMenu }
        '12' { Show-StatusMenu }
        '0' {
            Write-Log "Exiting optimization menu. Thank you for using merybist optimizer v2.0!" "Cyan"
            break
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Yellow
            Write-Host "`nPress any key to return..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
>>>>>>> parent of 29b559b (Add system-aware auto-optimization, FPS boost, and dynamic tweaks for Win10/11 + HDD/SSD)
    }
}
