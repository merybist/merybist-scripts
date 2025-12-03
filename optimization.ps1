<# 
Ultimate Windows Optimization by merybist
- Interactive numeric menu
- Fixed previous issues (confirm prompts, registry creation, service checks)
- Logging to C:\merybist-opt\opt.log
- Run as Administrator
#>

# ===== Setup & safety =====
$ConfirmPreference = 'None'  # Suppress confirmation prompts
$ErrorActionPreference = 'Continue'

$root = "C:\merybist-opt"
$log  = Join-Path $root "opt.log"
New-Item -ItemType Directory -Path $root -ErrorAction SilentlyContinue | Out-Null

function Write-Log {
    param([string]$msg, [string]$color = "Gray")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $log -Value $line
}

Write-Log "=== Ultimate Windows Optimization by merybist ===" "Cyan"

# ===== Helpers =====
function Ensure-RegKey {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Safe-SetReg {
    param([string]$Path,[string]$Name,[Object]$Value)
    Ensure-RegKey $Path
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
}

function Disable-ServiceSafe {
    param([string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Stop-Service $Name -Force -ErrorAction SilentlyContinue
            Set-Service $Name -StartupType Disabled
            Write-Log "Disabled service: $Name" "Green"
        } catch {
            Write-Log "Failed to disable ${Name}: $($_.Exception.Message)" "DarkYellow"
        }
    } else {
        Write-Log "Service $Name not found, skipping." "DarkGray"
    }
}

# ===== Actions =====
function Action-UltimatePlan {
    Write-Log "Enabling Ultimate Performance power plan (if supported)..." "Yellow"
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    try {
        powercfg -duplicatescheme $guid 2>$null | Out-Null
        powercfg -setactive $guid 2>$null     | Out-Null
        Write-Log "Ultimate Performance plan set (or already active)." "Green"
    } catch {
        Write-Log "Ultimate Performance plan not supported on this edition." "DarkYellow"
    }
}

function Action-DisableServicesBasic {
    Write-Log "Disabling non-essential services..." "Yellow"
    $services = @(
        "Fax",                # Fax
        "DiagTrack",          # Telemetry
        "SysMain",            # Superfetch
        "XblGameSave",        # Xbox Game Save
        "XboxNetApiSvc",      # Xbox Networking
        "XboxGipSvc",         # Xbox Accessory
        "MapsBroker",         # Offline Maps
        "RemoteRegistry",     # Remote Registry
        "WerSvc",             # Windows Error Reporting
        "dmwappushservice",   # Device Management WAP (may not exist)
        "RetailDemo"          # Retail Demo
    )
    foreach ($s in $services) { Disable-ServiceSafe $s }
}

function Action-DisableServicesConditional {
    Write-Log "Disabling conditional services (only if you don't use them)..." "Yellow"
    $services = @(
        "SharedAccess",       # Internet Connection Sharing
        "WSearch"             # Windows Search
    )
    foreach ($s in $services) { Disable-ServiceSafe $s }
}

function Action-BackgroundAppsAndGame {
    Write-Log "Disabling background apps & Game Bar/DVR..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Safe-SetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 0
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    Write-Log "Background apps and Game features disabled." "Green"
}

function Action-VisualEffectsPerformance {
    Write-Log "Setting visual effects for performance..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Write-Log "Visual effects tuned." "Green"
}

function Action-RegistryPerformanceTweaks {
    Write-Log "Applying registry performance tweaks..." "Yellow"
    # Tips & suggestions off
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    # Cortana off (policy)
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    # Telemetry off (policy)
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    # Delivery Optimization off
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0
    # Driver auto-update off
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0
    Write-Log "Registry tweaks applied." "Green"
}

function Action-NetworkTweaksBasic {
    Write-Log "Applying basic network tweaks..." "Yellow"
    # TCPA off
    Safe-SetReg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableTCPA" 0
    Write-Log "Basic network tweaks applied." "Green"
}

function Action-NetworkTweaksAggressive {
    Write-Log "Applying aggressive netsh TCP tuning..." "Yellow"
    try {
        netsh int tcp set global autotuninglevel=disabled  | Out-Null
        netsh int tcp set global rss=enabled               | Out-Null
        netsh int tcp set global ecncapability=disabled    | Out-Null
        netsh int tcp set global chimney=disabled          | Out-Null
        netsh int tcp set global dca=disabled              | Out-Null
        Write-Log "Aggressive network tuning applied." "Green"
    } catch {
        Write-Log "Failed netsh tuning: $($_.Exception.Message)" "DarkYellow"
    }
}

function Action-CleanupSafe {
    Write-Log "Running safe cleanup (Temp, Update cache, Prefetch, Logs, browser cache)..." "Yellow"
    # Temp folders
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Windows Update cache
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    # Prefetch
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Logs (fully recursive)
    Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    # Browser caches
    $user = $env:USERPROFILE
    Remove-Item "$user\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Safe cleanup completed." "Green"
}

function Action-CleanupAggressive {
    Write-Log "Running aggressive cleanup (WinSxS, shadows, icon/font caches)..." "Yellow"
    try {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    } catch {
        Write-Log "DISM cleanup failed or requires elevated context." "DarkYellow"
    }
    try {
        vssadmin delete shadows /all /quiet | Out-Null
    } catch {
        Write-Log "VSS shadow deletion skipped or unsupported." "DarkYellow"
    }
    # Icon cache
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    # Font cache (may rebuild on reboot)
    $fontCache = "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache"
    Remove-Item "$fontCache\*.dat" -Force -ErrorAction SilentlyContinue
    Write-Log "Aggressive cleanup completed." "Green"
}

function Action-CreateRestorePoint {
    Write-Log "Creating system restore point (Pre-Optimization)..." "Yellow"
    try {
        Checkpoint-Computer -Description "merybist optimization restore point" -RestorePointType "Modify_Settings"
        Write-Log "Restore point created." "Green"
    } catch {
        Write-Log "Restore point failed or unsupported: $($_.Exception.Message)" "DarkYellow"
    }
}

function Action-StatusSummary {
    Write-Log "Status summary:" "Cyan"
    # Power plan
    try {
        $activeGuid = (powercfg /getactivescheme) 2>$null
        Write-Log ("Active power plan: " + $activeGuid) "Gray"
    } catch { Write-Log "Cannot query power plan." "DarkYellow" }
    # Key services status
    $checkSvcs = @("SysMain","WSearch","DiagTrack","Fax","WerSvc","RemoteRegistry")
    foreach ($s in $checkSvcs) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) { Write-Log ("Service {0}: {1}" -f $s, $svc.Status) "Gray" } else { Write-Log "Service ${s}: not present" "DarkGray" }
    }
    Write-Log "Registry tweaks applied to ContentDeliveryManager, DataCollection, Windows Search, DeliveryOptimization." "Gray"
    Write-Log "Cleanup paths processed: Temp, SoftwareDistribution\Download, Prefetch, Logs, Browser caches." "Gray"
}

# ===== Interactive menu =====
function Show-Menu {
    Clear-Host
    Write-Host "=== merybist Optimization Menu ===`n" -ForegroundColor Cyan
    Write-Host "1. Enable Ultimate Performance power plan"
    Write-Host "2. Disable non-essential services (basic)"
    Write-Host "3. Disable conditional services (ICS, Search)"
    Write-Host "4. Disable background apps & Game DVR/Game Bar"
    Write-Host "5. Set visual effects to performance"
    Write-Host "6. Apply registry performance tweaks"
    Write-Host "7. Apply basic network tweaks)"
    Write-Host "8. Apply aggressive network tweaks (netsh"
    Write-Host "9. Run safe cleanup"
    Write-Host "10. Run aggressive cleanup"
    Write-Host "11. Create system restore point"
    Write-Host "12. Show status summary"
    Write-Host "0. Exit"
}

do {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-12)"
    switch ($choice) {
        '1'  { Action-UltimatePlan }
        '2'  { Action-DisableServicesBasic }
        '3'  { Action-DisableServicesConditional }
        '4'  { Action-BackgroundAppsAndGame }
        '5'  { Action-VisualEffectsPerformance }
        '6'  { Action-RegistryPerformanceTweaks }
        '7'  { Action-NetworkTweaksBasic }
        '8'  { Action-NetworkTweaksAggressive }
        '9'  { Action-CleanupSafe }
        '10' { Action-CleanupAggressive }
        '11' { Action-CreateRestorePoint }
        '12' { Action-StatusSummary }
        '0'  { Write-Log "Exiting optimization menu." "Cyan"; break }
        default { Write-Host "Invalid selection. Try again." -ForegroundColor Yellow }
    }
    if ($choice -ne '0') {
        Write-Host "`nPress any key to return to menu..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
} while ($true)
