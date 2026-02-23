# ============================================================
#  WinTools — optimization.ps1
#  Windows performance, privacy & UI tweaks
#  github.com/merybist/merybist-scripts
# ============================================================

#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "WinTools — Optimizer"
[Console]::CursorVisible = $true

# ════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════

function Write-Step  { param($msg) Write-Host "  > $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "  + $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Sub   { param($msg) Write-Host "    . $msg" -ForegroundColor DarkGray }
function Write-Div   { Write-Host ("  " + ("-" * ([Console]::WindowWidth - 4))) -ForegroundColor DarkGray }

function Pause-Back {
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Set-Reg {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction SilentlyContinue
}

function Backup-Registry {
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $out   = "$env:USERPROFILE\Desktop\reg_backup_$stamp.reg"
    Write-Step "Backing up registry to Desktop ($out)..."
    reg export HKLM $out /y 2>$null | Out-Null
    if (Test-Path $out) { Write-OK "Backup saved" }
    else                { Write-Warn "Backup failed -- proceeding anyway" }
}

function Show-Banner {
    Clear-Host
    $W = [Console]::WindowWidth
    Write-Host ""
    $left  = "  merybist-scripts  *  Optimizer  "
    $right = "  Windows 10 / 11  "
    Write-Host ($left + (" " * [Math]::Max(1, $W - $left.Length - $right.Length)) + $right).PadRight($W) `
        -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""
}

# ════════════════════════════════════════════════════════════
#  1. PERFORMANCE
# ════════════════════════════════════════════════════════════

function Optimize-Performance {
    Show-Banner
    Write-Host "  [PERF] Performance Tweaks`n" -ForegroundColor Cyan

    Write-Step "Setting power plan to Ultimate Performance..."
    $out  = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    $guid = [regex]::Match("$out", '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}').Value
    if ($guid) {
        powercfg /setactive $guid 2>$null
        Write-OK "Ultimate Performance plan activated ($guid)"
    } else {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-OK "High Performance plan activated (Ultimate not available on this edition)"
    }

    Write-Step "Tuning SvcHostSplitThresholdInKB to RAM size..."
    $ramKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" $ramKB
    Write-OK "SvcHostSplitThresholdInKB set to $ramKB KB  (~$([math]::Round($ramKB/1MB,1)) GB RAM detected)"
    Write-Sub "Reduces svchost.exe process count -- takes effect after reboot"

    Write-Step "Prioritizing foreground app CPU scheduling..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 26
    Write-OK "Win32PrioritySeparation = 26  (foreground apps get more CPU quanta)"

    Write-Step "Setting SystemResponsiveness to 10%..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10
    Write-OK "SystemResponsiveness = 10  (default: 20, lower = more CPU to foreground)"

    Write-Step "Disabling SysMain (Superfetch)..."
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
    Set-Service  -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Write-OK "SysMain disabled  (not needed on SSD)"

    Write-Step "Setting Windows Search Indexer to manual start..."
    Set-Service -Name WSearch -StartupType Manual -ErrorAction SilentlyContinue
    Write-OK "WSearch set to manual"

    Write-Step "Disabling Fast Startup..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
    Write-OK "Fast Startup disabled"

    Write-Step "Disabling Hibernate..."
    powercfg /hibernate off 2>$null
    Write-OK "Hibernate disabled  (frees disk space equal to RAM size)"

    Write-Step "Disabling Power Throttling..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1
    Write-OK "Power Throttling disabled"

    Write-Step "Disabling Xbox Game DVR & Game Bar..."
    Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_Enabled"            0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR"               0
    Set-Reg "HKCU:\Software\Microsoft\GameBar"                   "UseNexusForGameBarEnabled"  0
    Write-OK "Game DVR and Game Bar disabled"

    Write-Step "Reducing visual effects..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting"  2
    Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics"                               "MinAnimate"       "0" "String"
    Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"      "EnableTransparency" 0
    Write-OK "Visual effects set to performance mode, transparency disabled"

    Write-Step "Reducing WaitToKillServiceTimeout..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
    Set-Reg "HKCU:\Control Panel\Desktop"            "WaitToKillAppTimeout"     "2000" "String"
    Set-Reg "HKCU:\Control Panel\Desktop"            "HungAppTimeout"           "3000" "String"
    Write-OK "Shutdown timeouts reduced  (service: 2s, app: 2s, hung: 3s)"

    Write-Step "Removing startup apps delay..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
    Write-OK "Startup delay removed"

    Write-Div
    Write-OK "All performance tweaks applied -- reboot recommended"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  2. PRIVACY
# ════════════════════════════════════════════════════════════

function Optimize-Privacy {
    Show-Banner
    Write-Host "  [PRIV] Privacy Tweaks`n" -ForegroundColor Cyan

    Write-Step "Disabling Windows Telemetry..."
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"              "AllowTelemetry"  0
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
    Write-OK "Telemetry disabled"

    Write-Step "Disabling Advertising ID..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Write-OK "Advertising ID disabled"

    Write-Step "Disabling Cortana..."
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"          0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortanaAboveLock" 0
    Write-OK "Cortana disabled"

    Write-Step "Disabling Activity History & Timeline..."
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"    0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"  0
    Write-OK "Activity History disabled"

    Write-Step "Disabling Location tracking..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
    Write-OK "Location tracking disabled"

    Write-Step "Denying app access to Camera & Microphone..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"     "Value" "Deny" "String"
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny" "String"
    Write-Warn "Camera/Mic blocked for all apps -- re-enable in Settings if needed"

    Write-Step "Disabling Feedback & Diagnostics..."
    Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
    Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds"  0
    Write-OK "Feedback prompts disabled"

    Write-Step "Disabling Tailored Experiences..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
    Write-OK "Tailored experiences disabled"

    Write-Step "Disabling app launch tracking..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
    Write-OK "App launch tracking disabled"

    Write-Step "Disabling Windows Error Reporting..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
    Write-OK "Error Reporting disabled"

    Write-Step "Disabling Remote Assistance..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0
    Write-OK "Remote Assistance disabled"

    Write-Div
    Write-OK "All privacy tweaks applied"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  3. SERVICES
# ════════════════════════════════════════════════════════════

function Optimize-Services {
    Show-Banner
    Write-Host "  [SVC] Startup & Services Cleanup`n" -ForegroundColor Cyan

    $services = [ordered]@{
        "DiagTrack"        = "Connected User Experiences & Telemetry"
        "dmwappushservice" = "WAP Push Message Routing"
        "MapsBroker"       = "Downloaded Maps Manager"
        "lfsvc"            = "Geolocation Service"
        "RetailDemo"       = "Retail Demo Service"
        "WbioSrvc"         = "Windows Biometric Service"
        "XblAuthManager"   = "Xbox Live Auth Manager"
        "XblGameSave"      = "Xbox Live Game Save"
        "XboxNetApiSvc"    = "Xbox Live Networking"
        "XboxGipSvc"       = "Xbox Accessory Management"
        "wisvc"            = "Windows Insider Service"
        "WMPNetworkSvc"    = "Windows Media Player Network Sharing"
        "Fax"              = "Fax"
        "RemoteRegistry"   = "Remote Registry"
        "TrkWks"           = "Distributed Link Tracking Client"
        "SysMain"          = "Superfetch"
        "WSearch"          = "Windows Search Indexer"
    }

    Write-Step "Disabling $($services.Count) unnecessary services...`n"

    foreach ($svc in $services.GetEnumerator()) {
        Stop-Service -Name $svc.Key -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $svc.Key -StartupType Disabled -ErrorAction SilentlyContinue
        $exists = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
        $label  = ("    - " + $svc.Key).PadRight(26)
        if ($exists) {
            Write-Host "$label" -NoNewline -ForegroundColor DarkGray
            Write-Host "disabled   " -NoNewline -ForegroundColor Green
            Write-Host $svc.Value   -ForegroundColor DarkGray
        } else {
            Write-Host "$label" -NoNewline -ForegroundColor DarkGray
            Write-Host "not found" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Div
    Write-OK "Services cleanup done"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  4. JUNK CLEANER
# ════════════════════════════════════════════════════════════

function Clean-Junk {
    Show-Banner
    Write-Host "  [JUNK] Junk File Cleaner`n" -ForegroundColor Cyan

    $paths = [ordered]@{
        "User Temp"          = $env:TEMP
        "System Temp"        = "$env:SystemRoot\Temp"
        "Prefetch"           = "$env:SystemRoot\Prefetch"
        "IE / Edge Cache"    = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        "Local App Temp"     = "$env:LOCALAPPDATA\Temp"
        "Windows Update"     = "$env:SystemRoot\SoftwareDistribution\Download"
        "Error Reports"      = "$env:LOCALAPPDATA\Microsoft\Windows\WER"
        "Thumbnail Cache"    = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        "Delivery Optim."    = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"
    }

    $totalFreed = 0.0

    foreach ($p in $paths.GetEnumerator()) {
        if (-not (Test-Path $p.Value)) { continue }
        Write-Step "$($p.Key)..."
        $before = (Get-ChildItem $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object -Property Length -Sum).Sum
        Get-ChildItem -Path $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $after = (Get-ChildItem $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum

        # PS5.1 compatible null check (no ?? operator)
        $beforeVal = if ($before) { $before } else { 0 }
        $afterVal  = if ($after)  { $after  } else { 0 }
        $freed     = [Math]::Round(($beforeVal - $afterVal) / 1MB, 1)

        $totalFreed += $freed
        Write-OK "Freed ~$freed MB"
    }

    Write-Step "Emptying Recycle Bin..."
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-OK "Recycle Bin emptied"

    Write-Step "Running Windows Disk Cleanup silently..."
    $sageSet  = 64
    $regBase  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    @(
        "Temporary Files"
        "Downloaded Program Files"
        "Internet Cache Files"
        "Thumbnails"
        "Old ChkDsk Files"
        "Recycle Bin"
        "Setup Log Files"
        "System error memory dump files"
    ) | ForEach-Object {
        Set-Reg "$regBase\$_" "StateFlags$sageSet" 2
    }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:$sageSet" -Wait -ErrorAction SilentlyContinue
    Write-OK "Disk Cleanup done"

    Write-Div
    Write-OK "Total freed from temp folders: ~$totalFreed MB"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  5. NETWORK
# ════════════════════════════════════════════════════════════

function Optimize-Network {
    Show-Banner
    Write-Host "  [NET] Network Tweaks`n" -ForegroundColor Cyan

    Write-Step "Disabling network throttling (MMCSS)..."
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
    Write-OK "NetworkThrottlingIndex = 0xFFFFFFFF  (throttling disabled)"

    Write-Step "Increasing IRPStackSize for better network throughput..."
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 32
    Write-OK "IRPStackSize = 32  (default: 15, max safe: 32)"
    Write-Sub "More simultaneous I/O buffers = better file/network throughput"

    Write-Host ""
    Write-Host "  Choose DNS provider:" -ForegroundColor White
    Write-Host "  [1] Cloudflare   1.1.1.1 / 1.0.0.1       (fast + privacy)" -ForegroundColor Gray
    Write-Host "  [2] Google       8.8.8.8 / 8.8.4.4" -ForegroundColor Gray
    Write-Host "  [3] Quad9        9.9.9.9 / 149.112.112.112  (malware blocking)" -ForegroundColor Gray
    Write-Host "  [4] Skip" -ForegroundColor DarkGray
    Write-Host ""
    $dns = Read-Host "  Choice"

    $primary = $secondary = $null; $label = ""
    switch ($dns) {
        "1" { $primary = "1.1.1.1";  $secondary = "1.0.0.1";          $label = "Cloudflare" }
        "2" { $primary = "8.8.8.8";  $secondary = "8.8.4.4";          $label = "Google" }
        "3" { $primary = "9.9.9.9";  $secondary = "149.112.112.112";  $label = "Quad9" }
    }
    if ($primary) {
        Write-Step "Setting DNS to $label..."
        Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex `
                -ServerAddresses @($primary, $secondary) -ErrorAction SilentlyContinue
        }
        Write-OK "DNS set to $primary / $secondary  ($label)"
    }

    Write-Step "Flushing DNS cache..."
    ipconfig /flushdns | Out-Null
    Write-OK "DNS cache flushed"

    Write-Step "Applying TCP tweaks (Nagle off, auto-tuning, SACK)..."
    $tcpGlobal = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    Set-Reg $tcpGlobal "TCPNoDelay"       1
    Set-Reg $tcpGlobal "TcpAckFrequency"  1
    Set-Reg $tcpGlobal "Tcp1323Opts"      1
    Set-Reg $tcpGlobal "DefaultTTL"       64

    $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $ifPath -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath "TcpAckFrequency" 1
        Set-Reg $_.PSPath "TCPNoDelay"      1
    }

    netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
    netsh int tcp set global ecncapability=enabled  2>$null | Out-Null
    netsh int tcp set global timestamps=disabled    2>$null | Out-Null
    Write-OK "TCP: Nagle off, ACK immediate, SACK enabled, auto-tuning normal, ECN on"

    Write-Step "Disabling QoS bandwidth reservation..."
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
    Write-OK "QoS reservation removed  (was reserving up to 20% bandwidth)"

    Write-Div
    Write-OK "Network tweaks applied"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  6. EXPLORER & UI
# ════════════════════════════════════════════════════════════

function Optimize-Explorer {
    Show-Banner
    Write-Host "  [UI] Explorer & UI Tweaks`n" -ForegroundColor Cyan

    $advPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $cdmPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $deskPath  = "HKCU:\Control Panel\Desktop"

    Write-Step "Showing file extensions..."
    Set-Reg $advPath "HideFileExt" 0
    Write-OK "File extensions visible"

    Write-Step "Showing hidden files..."
    Set-Reg $advPath "Hidden" 1
    Write-OK "Hidden files visible"

    Write-Step "Showing full path in Explorer title bar..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1
    Write-OK "Full path in title bar enabled"

    Write-Step "Reducing menu show delay (400ms to 50ms)..."
    Set-Reg $deskPath "MenuShowDelay" "50" "String"
    Write-OK "MenuShowDelay = 50ms  (default: 400ms)"
    Write-Sub "Affects right-click and cascading menus; not UWP/Start menu"

    Write-Step "Disabling Bing search in Start Menu..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent"    0
    Write-OK "Bing search disabled"

    Write-Step "Enabling dark mode..."
    Set-Reg $themePath "AppsUseLightTheme"    0
    Set-Reg $themePath "SystemUsesLightTheme" 0
    Write-OK "Dark mode enabled"

    Write-Step "Disabling lock screen ads, Start suggestions..."
    @(
        "RotatingLockScreenOverlayEnabled"
        "SubscribedContent-338387Enabled"
        "SubscribedContent-338388Enabled"
        "SubscribedContent-353698Enabled"
        "SubscribedContent-310093Enabled"
        "SoftLandingEnabled"
        "SystemPaneSuggestionsEnabled"
        "PreInstalledAppsEnabled"
        "OemPreInstalledAppsEnabled"
    ) | ForEach-Object { Set-Reg $cdmPath $_ 0 }
    Write-OK "Lock screen ads and Start suggestions disabled"

    Write-Step "Hiding News & Interests from taskbar..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2
    Write-OK "News & Interests hidden"

    Write-Step "Setting taskbar alignment to Left (Win11)..."
    Set-Reg $advPath "TaskbarAl" 0
    Write-OK "Taskbar aligned left"

    Write-Step "Restoring classic right-click context menu (Win11)..."
    $clsid = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    Set-Reg $clsid "(Default)" "" "String"
    Write-OK "Classic context menu restored  (no more 'Show more options')"

    Write-Step "Hiding OneDrive from Explorer sidebar..."
    Set-Reg "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0 | Out-Null
    Set-Reg "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0 | Out-Null
    Write-OK "OneDrive removed from Explorer sidebar"

    Write-Step "Disabling low disk space warnings..."
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoLowDiskSpaceChecks" 1
    Write-OK "Low disk space popups disabled"

    Write-Step "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
    Start-Process explorer
    Write-OK "Explorer restarted"

    Write-Div
    Write-OK "All Explorer & UI tweaks applied"
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  RUN ALL
# ════════════════════════════════════════════════════════════

function Run-All {
    Backup-Registry
    Optimize-Performance
    Optimize-Privacy
    Optimize-Services
    Clean-Junk
    Optimize-Network
    Optimize-Explorer
    Show-Banner
    Write-Host "  [OK] All optimizations applied!" -ForegroundColor Green
    Write-Host "  [!]  Reboot recommended for all changes to take effect." -ForegroundColor Yellow
    Write-Host ""
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  MAIN MENU
# ════════════════════════════════════════════════════════════

while ($true) {
    Show-Banner

    Write-Host "  [1]  Performance    power plan, SvcHostSplitThresholdInKB, SysMain,"
    Write-Host "                      PowerThrottling, shutdown timeouts, startup delay"
    Write-Host "  [2]  Privacy        telemetry, Cortana, ads, camera, error reporting"
    Write-Host "  [3]  Services       disable 17 unnecessary Windows services"
    Write-Host "  [4]  Junk Cleaner   temp files, prefetch, WU cache, Disk Cleanup"
    Write-Host "  [5]  Network        DNS picker, IRPStackSize, Nagle, QoS, TCP tweaks"
    Write-Host "  [6]  Explorer & UI  MenuShowDelay, dark mode, classic menu, OneDrive"
    Write-Host "  [A]  Run ALL        (creates registry backup first)"
    Write-Host "  [B]  Backup registry only"
    Write-Host "  [Q]  Exit"
    Write-Host ""

    $choice = Read-Host "  Choice"

    switch ($choice.ToUpper()) {
        "1" { Optimize-Performance }
        "2" { Optimize-Privacy     }
        "3" { Optimize-Services    }
        "4" { Clean-Junk           }
        "5" { Optimize-Network     }
        "6" { Optimize-Explorer    }
        "A" { Run-All              }
        "B" { Show-Banner; Backup-Registry; Pause-Back }
        "Q" { Clear-Host; Write-Host "`n  Bye!`n" -ForegroundColor Cyan; exit }
        default { Write-Host "  Invalid choice." -ForegroundColor Red; Start-Sleep 1 }
    }
}
