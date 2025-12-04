<# 
Ultimate Windows Optimization by merybist
Refactored: nested menus, per-action control, logging, enable/disable pairs
Run as Administrator
#>

# ===== Setup & safety =====
$ConfirmPreference = 'None'
$ErrorActionPreference = 'Continue'

$root = "C:\merybist-opt"
$log  = Join-Path $root "opt.log"
New-Item -ItemType Directory -Path $root -ErrorAction SilentlyContinue | Out-Null

function Write-Log {
    param([string]$msg, [string]$color = "Gray")
    $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $log -Value $line
}

Write-Log "=== Ultimate Windows Optimization by merybist (refactored) ===" "Cyan"

# ===== Helpers =====
function Ensure-RegKey {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Safe-SetReg {
    param(
        [string]$Path,
        [string]$Name,
        [Object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    Ensure-RegKey $Path
    try {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue
    }
}

function Disable-ServiceSafe {
    param([string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Stop-Service $Name -Force -ErrorAction SilentlyContinue
            Set-Service $Name -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "Disabled service: $Name" "Green"
        } catch {
            Write-Log "Failed to disable ${Name}: $($_.Exception.Message)" "DarkYellow"
        }
    } else {
        Write-Log "Service $Name not found, skipping." "DarkGray"
    }
}

function Enable-ServiceSafe {
    param([string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Set-Service $Name -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service $Name -ErrorAction SilentlyContinue
            Write-Log "Enabled service: $Name" "Green"
        } catch {
            Write-Log "Failed to enable ${Name}: $($_.Exception.Message)" "DarkYellow"
        }
    } else {
        Write-Log "Service $Name not found, skipping." "DarkGray"
    }
}

# ===== Defender / SmartScreen / UAC =====
function Action-DisableDefender {
    Write-Log "Disabling Windows Defender..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 1
    $defenderServices = @("WinDefend","WdNisSvc","SecurityHealthService","wscsvc")
    foreach ($s in $defenderServices) { Disable-ServiceSafe $s }
    Write-Log "Windows Defender disabled (policy + services)." "Green"
}

function Action-EnableDefender {
    Write-Log "Enabling Windows Defender..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 0
    $defenderServices = @("WinDefend","WdNisSvc","SecurityHealthService","wscsvc")
    foreach ($s in $defenderServices) { Enable-ServiceSafe $s }
    Write-Log "Windows Defender enabled (policy + services)." "Green"
}

function Action-DisableSmartScreen {
    Write-Log "Disabling SmartScreen..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "ShellSmartScreenLevel" "Off" ([Microsoft.Win32.RegistryValueKind]::String)
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SmartScreenEnabled" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SmartScreenPuaEnabled" 0
    Write-Log "SmartScreen disabled." "Green"
}

function Action-EnableSmartScreen {
    Write-Log "Enabling SmartScreen..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "ShellSmartScreenLevel" "Warn" ([Microsoft.Win32.RegistryValueKind]::String)
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SmartScreenEnabled" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "SmartScreenPuaEnabled" 1
    Write-Log "SmartScreen enabled." "Green"
}

function Action-DisableUAC {
    Write-Log "Disabling UAC..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0
    Write-Log "UAC disabled (reboot required)." "Green"
}

function Action-EnableUAC {
    Write-Log "Enabling UAC..." "Yellow"
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
    Write-Log "UAC enabled (reboot required)." "Green"
}

# ===== Services =====
function Action-DisableServicesBasic {
    Write-Log "Disabling non-essential services (basic)..." "Yellow"
    $services = @(
        "Fax",
        "DiagTrack",
        "SysMain",
        "XblGameSave",
        "XboxNetApiSvc",
        "XboxGipSvc",
        "MapsBroker",
        "RemoteRegistry",
        "WerSvc",
        "dmwappushservice",
        "RetailDemo",
        "SensrSvc",
        "SessionEnv",
        "SharedAccess",
        "shpamsvc",
        "SNMPTRAP",
        "Spooler",
        "ssh-agent",
        "TermService",
        "TroubleshootingSvc",
        "UevAgentService",
        "uhssvc",
        "UmRdpService",
        "vmicguestinterface",
        "vmicheartbeat",
        "vmickvpexchange",
        "vmicrdv",
        "vmicshutdown",
        "vmictimesync",
        "vmicvmsession",
        "vmicvss",
        "WarpJITSvc",
        "WbioSrvc",
        "WdiServiceHost",
        "WdiSystemHost",
        "WdNisSvc",
        "WMPNetworkSvc",
        "workfolderssvc",
        "WpnService",
        "WwanSvc",
        "XblAuthManager"
    )
    foreach ($s in $services) { Disable-ServiceSafe $s }
    Write-Log "Basic services disabled." "Green"
}

function Action-DisableServicesConditional {
    Write-Log "Disabling conditional services (if unused)..." "Yellow"
    $services = @(
        "SharedAccess",
        "WSearch",
        "WebClient",
        "Wecsvc",
        "WiaRpc",
        "WPDBusEnum",
        "wlpasvc",
        "wmiApSrv",
        "WFDSConMgrSvc"
    )
    foreach ($s in $services) { Disable-ServiceSafe $s }
    Write-Log "Conditional services disabled." "Green"
}

function Action-DisableServicesAggressive {
    Write-Log "Disabling aggressive service set..." "Yellow"
    $services = @(
        "SecurityHealthService",
        "wscsvc",
        "Themes",
        "WpnService",
        "WerSvc",
        "WdiServiceHost",
        "WdiSystemHost",
        "WMPNetworkSvc",
        "workfolderssvc"
    )
    foreach ($s in $services) { Disable-ServiceSafe $s }
    Write-Log "Aggressive services set disabled." "Green"
}

function Action-EnableAllServices {
    Write-Log "Enabling services from all optimization groups..." "Yellow"
    $all = @(
        "Fax","DiagTrack","SysMain","XblGameSave","XboxNetApiSvc","XboxGipSvc","MapsBroker","RemoteRegistry",
        "WerSvc","dmwappushservice","RetailDemo","SensrSvc","SessionEnv","SharedAccess","shpamsvc","SNMPTRAP",
        "Spooler","ssh-agent","TermService","TroubleshootingSvc","UevAgentService","uhssvc","UmRdpService",
        "vmicguestinterface","vmicheartbeat","vmickvpexchange","vmicrdv","vmicshutdown","vmictimesync",
        "vmicvmsession","vmicvss","WarpJITSvc","WbioSrvc","WdiServiceHost","WdiSystemHost","WdNisSvc",
        "WebClient","Wecsvc","WiaRpc","wlpasvc","wmiApSrv","WMPNetworkSvc","workfolderssvc","WPDBusEnum",
        "WpnService","wscsvc","WSearch","WwanSvc","XblAuthManager"
    )
    foreach ($s in $all) { Enable-ServiceSafe $s }
    Write-Log "All services in lists set to Automatic and started where possible." "Green"
}

# ===== Background Apps & GameDVR =====
function Action-DisableBackgroundApps {
    Write-Log "Disabling background apps..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Write-Log "Background apps disabled." "Green"
}

function Action-EnableBackgroundApps {
    Write-Log "Enabling background apps..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 0
    Write-Log "Background apps enabled." "Green"
}

function Action-DisableGameDVR {
    Write-Log "Disabling Game DVR & Game Bar..." "Yellow"
    Safe-SetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 0
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    Write-Log "Game DVR & Game Bar disabled." "Green"
}

function Action-EnableGameDVR {
    Write-Log "Enabling Game DVR & Game Bar..." "Yellow"
    Safe-SetReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 1
    Safe-SetReg "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 1
    Write-Log "Game DVR & Game Bar enabled." "Green"
}

# ===== Visual Effects =====
function Action-VisualEffectsPerformance {
    Write-Log "Setting visual effects to performance..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Write-Log "Visual effects set to performance." "Green"
}

function Action-VisualEffectsDefault {
    Write-Log "Restoring default visual effects..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 1
    Write-Log "Visual effects restored to default." "Green"
}

# ===== Registry Tweaks =====
function Action-RegistryPerformanceTweaks {
    Write-Log "Applying registry performance tweaks..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0
    Write-Log "Registry performance tweaks applied." "Green"
}

function Action-RegistryRestoreDefaults {
    Write-Log "Restoring registry defaults for performance-related keys..." "Yellow"
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 1
    Safe-SetReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 1
    Safe-SetReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 3
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 3
    Safe-SetReg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 1
    Write-Log "Registry defaults restored (approximate)." "Green"
}

# ===== Network Tweaks =====
function Action-NetworkTweaksBasic {
    Write-Log "Applying basic network tweaks..." "Yellow"
    Safe-SetReg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableTCPA" 0
    Write-Log "Basic network tweaks applied." "Green"
}

function Action-NetworkTweaksAggressive {
    Write-Log "Applying aggressive network tweaks (netsh)..." "Yellow"
    try {
        netsh int tcp set global autotuninglevel=disabled  | Out-Null
        netsh int tcp set global rss=enabled               | Out-Null
        netsh int tcp set global ecncapability=disabled    | Out-Null
        netsh int tcp set global chimney=disabled          | Out-Null
        netsh int tcp set global dca=disabled              | Out-Null
        Write-Log "Aggressive netsh tuning applied." "Green"
    } catch {
        Write-Log "Netsh tuning failed: $($_.Exception.Message)" "DarkYellow"
    }
}

function Action-NetworkRestoreDefaults {
    Write-Log "Restoring default network settings (netsh)..." "Yellow"
    try {
        netsh int tcp set global autotuninglevel=normal    | Out-Null
        netsh int tcp set global rss=default               | Out-Null
        netsh int tcp set global ecncapability=default     | Out-Null
        netsh int tcp set global chimney=default           | Out-Null
        netsh int tcp set global dca=default               | Out-Null
        Write-Log "Network settings restored to defaults." "Green"
    } catch {
        Write-Log "Failed to restore netsh defaults: $($_.Exception.Message)" "DarkYellow"
    }
}

# ===== Cleanup =====
function Action-CleanupSafe {
    Write-Log "Running safe cleanup..." "Yellow"
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    $user = $env:USERPROFILE
    Remove-Item "$user\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Safe cleanup completed." "Green"
}

function Action-CleanupAggressive {
    Write-Log "Running aggressive cleanup..." "Yellow"
    try {
        Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
    } catch {
        Write-Log "DISM cleanup failed or requires elevation." "DarkYellow"
    }
    try {
        vssadmin delete shadows /all /quiet | Out-Null
    } catch {
        Write-Log "VSS shadows deletion skipped or unsupported." "DarkYellow"
    }
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
    $fontCache = "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache"
    Remove-Item "$fontCache\*.dat" -Force -ErrorAction SilentlyContinue
    Write-Log "Aggressive cleanup completed." "Green"
}

# ===== Power plan & restore point & status =====
function Action-UltimatePlan {
    Write-Log "Enabling Ultimate Performance power plan..." "Yellow"
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    try {
        powercfg -duplicatescheme $guid 2>$null | Out-Null
        powercfg -setactive $guid 2>$null       | Out-Null
        Write-Log "Ultimate Performance plan active." "Green"
    } catch {
        Write-Log "Ultimate Performance plan not supported on this edition." "DarkYellow"
    }
}

function Action-CreateRestorePoint {
    Write-Log "Creating system restore point..." "Yellow"
    try {
        Checkpoint-Computer -Description "merybist optimization restore point" -RestorePointType "Modify_Settings"
        Write-Log "Restore point created." "Green"
    } catch {
        Write-Log "Restore point failed or unsupported: $($_.Exception.Message)" "DarkYellow"
    }
}

function Action-StatusSummary {
    Write-Log "Status summary:" "Cyan"
    try {
        $activeGuid = (powercfg /getactivescheme) 2>$null
        Write-Log ("Active power plan: " + $activeGuid) "Gray"
    } catch {
        Write-Log "Cannot query power plan." "DarkYellow"
    }
    $checkSvcs = @("SysMain","WSearch","DiagTrack","Fax","WerSvc","RemoteRegistry")
    foreach ($s in $checkSvcs) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Log ("Service {0}: {1}" -f $s, $svc.Status) "Gray"
        } else {
            Write-Log "Service ${s}: not present" "DarkGray"
        }
    }
    Write-Log "Registry tweaks: ContentDeliveryManager, DataCollection, Windows Search, DeliveryOptimization, DriverSearching." "Gray"
    Write-Log "Cleanup paths: Temp, SoftwareDistribution\Download, Prefetch, Logs, Browser caches." "Gray"
}

# ===== Menus (NO nested input inside main loop) =====

function Show-Separator { }

function Show-MainMenu {
    Clear-Host
    Write-Host "   merybist Optimization Menu" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " 1. Windows Defender | UAC"
    Write-Host " 2. Services Optimization"
    Write-Host " 3. Background Apps & GameDVR"
    Write-Host " 4. Visual Effects"
    Write-Host " 5. Registry Tweaks"
    Write-Host " 6. Network Tweaks"
    Write-Host " 7. Cleanup"
    Write-Host " 8. Power Plan"
    Write-Host " 9. Restore Point"
    Write-Host "10. Status Summary"
    Write-Host " 0. Exit"
    Write-Host ""
}

function Show-DefenderMenu {
    while ($true) {
        Clear-Host
        Write-Host "Windows Defender | SmartScreen | UAC" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Disable Windows Defender"
        Write-Host " 2. Enable Windows Defender"
        Write-Host " 3. Disable SmartScreen"
        Write-Host " 4. Enable SmartScreen"
        Write-Host " 5. Disable UAC"
        Write-Host " 6. Enable UAC"
        Write-Host " 0. Back"
        Write-Host ""

        $d = Read-Host "Select option"

        switch ($d) {
            '1' { Action-DisableDefender }
            '2' { Action-EnableDefender }
            '3' { Action-DisableSmartScreen }
            '4' { Action-EnableSmartScreen }
            '5' { Action-DisableUAC }
            '6' { Action-EnableUAC }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-ServicesMenu {
    while ($true) {
        Clear-Host
        Write-Host "Services Optimization" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Disable Basic Services"
        Write-Host " 2. Disable Conditional Services"
        Write-Host " 3. Disable Aggressive Services"
        Write-Host " 4. Enable All Services"
        Write-Host " 0. Back"
        Write-Host ""

        $s = Read-Host "Select option"

        switch ($s) {
            '1' { Action-DisableServicesBasic }
            '2' { Action-DisableServicesConditional }
            '3' { Action-DisableServicesAggressive }
            '4' { Action-EnableAllServices }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-BackgroundMenu {
    while ($true) {
        Clear-Host
        Write-Host "Background Apps & GameDVR" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Disable Background Apps"
        Write-Host " 2. Enable Background Apps"
        Write-Host " 3. Disable GameDVR"
        Write-Host " 4. Enable GameDVR"
        Write-Host " 0. Back"
        Write-Host ""

        $b = Read-Host "Select option"

        switch ($b) {
            '1' { Action-DisableBackgroundApps }
            '2' { Action-EnableBackgroundApps }
            '3' { Action-DisableGameDVR }
            '4' { Action-EnableGameDVR }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-VisualMenu {
    while ($true) {
        Clear-Host
        Write-Host "Visual Effects" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Performance Mode"
        Write-Host " 2. Default Mode"
        Write-Host " 0. Back"
        Write-Host ""

        $v = Read-Host "Select option"

        switch ($v) {
            '1' { Action-VisualEffectsPerformance }
            '2' { Action-VisualEffectsDefault }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-RegistryMenu {
    while ($true) {
        Clear-Host
        Write-Host "Registry Tweaks" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Apply Performance Tweaks"
        Write-Host " 2. Restore Defaults"
        Write-Host " 0. Back"
        Write-Host ""

        $r = Read-Host "Select option"

        switch ($r) {
            '1' { Action-RegistryPerformanceTweaks }
            '2' { Action-RegistryRestoreDefaults }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-NetworkMenu {
    while ($true) {
        Clear-Host
        Write-Host "Network Tweaks" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Basic Tweaks"
        Write-Host " 2. Aggressive Tweaks"
        Write-Host " 3. Restore Defaults"
        Write-Host " 0. Back"
        Write-Host ""

        $n = Read-Host "Select option"

        switch ($n) {
            '1' { Action-NetworkTweaksBasic }
            '2' { Action-NetworkTweaksAggressive }
            '3' { Action-NetworkRestoreDefaults }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-CleanupMenu {
    while ($true) {
        Clear-Host
        Write-Host "Cleanup" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Safe Cleanup"
        Write-Host " 2. Aggressive Cleanup"
        Write-Host " 0. Back"
        Write-Host ""

        $c = Read-Host "Select option"

        switch ($c) {
            '1' { Action-CleanupSafe }
            '2' { Action-CleanupAggressive }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-PowerPlanMenu {
    while ($true) {
        Clear-Host
        Write-Host "Power Plan" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Enable Ultimate Performance"
        Write-Host " 0. Back"
        Write-Host ""

        $p = Read-Host "Select option"

        switch ($p) {
            '1' { Action-UltimatePlan }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-RestoreMenu {
    while ($true) {
        Clear-Host
        Write-Host "Restore Point" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Create Restore Point"
        Write-Host " 0. Back"
        Write-Host ""

        $rp = Read-Host "Select option"

        switch ($rp) {
            '1' { Action-CreateRestorePoint }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Show-StatusMenu {
    while ($true) {
        Clear-Host
        Write-Host "Status Summary" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Show Status Summary"
        Write-Host " 0. Back"
        Write-Host ""

        $ss = Read-Host "Select option"

        switch ($ss) {
            '1' { Action-StatusSummary }
            '0' { return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow }
        }

        Write-Host "`nPress any key to return..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

# ===== Main Loop (no nested sub-inputs) =====
do {
    Show-MainMenu
    $main = Read-Host "Select option"

    switch ($main) {
        '1' { Show-DefenderMenu }
        '2' { Show-ServicesMenu }
        '3' { Show-BackgroundMenu }
        '4' { Show-VisualMenu }
        '5' { Show-RegistryMenu }
        '6' { Show-NetworkMenu }
        '7' { Show-CleanupMenu }
        '8' { Show-PowerPlanMenu }
        '9' { Show-RestoreMenu }
        '10' { Show-StatusMenu }
        '0' {
            Write-Log "Exiting optimization menu." "Cyan"
            break
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Yellow
            Write-Host "`nPress any key to return..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    }

} while ($true)
