# ============================================================
#  WinTools — optimization.ps1
#  Windows performance, privacy & UI tweaks
#  github.com/merybist/WinTools
# ============================================================

#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "merybist - EasyInstaller"
[Console]::CursorVisible = $true

# ════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════

function Write-Step { param($msg) Write-Host "  > $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  + $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Skip { param($msg) Write-Host "  - $msg" -ForegroundColor DarkGray }
function Write-Sub  { param($msg) Write-Host "    . $msg" -ForegroundColor DarkGray }
function Write-Div  { Write-Host ("  " + ("-" * ([Console]::WindowWidth - 4))) -ForegroundColor DarkGray }

# $AUTO = $true means silent mode (no prompts, apply everything)
$AUTO = $false

# Ask user Y/N — always returns $true in auto mode
function Confirm-Step {
    param([string]$prompt)
    if ($AUTO) { return $true }
    $ans = Read-Host "  $prompt [Y/n]"
    return ($ans -eq "" -or $ans -match '^[Yy]')
}

# Ask user to pick from a list — always returns default in auto mode
function Select-Option {
    param(
        [string]$prompt,
        [string[]]$options,   # display labels
        [string[]]$values,    # return values matching labels
        [string]$default      # value to return in auto mode
    )
    if ($AUTO) { return $default }
    Write-Host ""
    Write-Host "  $prompt" -ForegroundColor White
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "  [$($i+1)] $($options[$i])" -ForegroundColor Gray
    }
    Write-Host "  [0] Skip" -ForegroundColor DarkGray
    Write-Host ""
    $ans = Read-Host "  Choice"
    if ($ans -eq "0" -or $ans -eq "") { return $null }
    $idx = [int]$ans - 1
    if ($idx -ge 0 -and $idx -lt $values.Count) { return $values[$idx] }
    return $null
}

function Pause-Back {
    if ($AUTO) { return }
    Write-Host ""
    Write-Host "  Press any key to return..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction SilentlyContinue
}

function Backup-Registry {
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $out   = "$env:USERPROFILE\Desktop\reg_backup_$stamp.reg"
    Write-Step "Backing up registry to Desktop..."
    reg export HKLM $out /y 2>$null | Out-Null
    if (Test-Path $out) { Write-OK "Backup saved: $out" }
    else                { Write-Warn "Backup failed — proceeding anyway" }
}

function Show-Banner {
    Clear-Host
    $W    = [Console]::WindowWidth
    $left = "  merybist-scripts  *  Optimizer  "
    $mode = if ($AUTO) { "  [AUTO MODE]  " } else { "  Windows 10 / 11  " }
    Write-Host ""
    Write-Host ($left + (" " * [Math]::Max(1,$W-$left.Length-$mode.Length)) + $mode).PadRight($W) `
        -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""
}

# ════════════════════════════════════════════════════════════
#  AUTO PROGRESS BAR (used only in auto mode)
# ════════════════════════════════════════════════════════════

$AUTO_STEPS_TOTAL = 0
$AUTO_STEPS_DONE  = 0

function Auto-Progress {
    param([string]$label)
    $AUTO_STEPS_DONE++
    $pct    = if ($AUTO_STEPS_TOTAL -gt 0) { [int](($AUTO_STEPS_DONE / $AUTO_STEPS_TOTAL) * 100) } else { 0 }
    $filled = [int]($pct / 2)
    $bar    = ("=" * $filled).PadRight(50, "-")
    $line   = "  [$bar] $pct%  $label"
    Write-Host "`r$($line.PadRight([Console]::WindowWidth - 1))" -NoNewline -ForegroundColor Cyan
}

# ════════════════════════════════════════════════════════════
#  1. PERFORMANCE
# ════════════════════════════════════════════════════════════

function Optimize-Performance {
    if (-not $AUTO) { Show-Banner; Write-Host "  [PERF] Performance Tweaks`n" -ForegroundColor Cyan }

    # Power plan
    if (Confirm-Step "Set power plan to Ultimate/High Performance?") {
        if (-not $AUTO) { Write-Step "Setting power plan..." }
        else            { Auto-Progress "Power plan" }
        $out  = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        $guid = [regex]::Match("$out",'[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}').Value
        if ($guid) { powercfg /setactive $guid 2>$null; if (-not $AUTO) { Write-OK "Ultimate Performance activated" } }
        else       { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null; if (-not $AUTO) { Write-OK "High Performance activated" } }
    } else { if (-not $AUTO) { Write-Skip "Power plan skipped" } }

    # SvcHostSplitThreshold
    if (Confirm-Step "Tune SvcHostSplitThresholdInKB to reduce svchost processes?") {
        if (-not $AUTO) { Write-Step "Tuning SvcHostSplitThresholdInKB..." }
        else            { Auto-Progress "SvcHost threshold" }
        $ramKB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" $ramKB
        if (-not $AUTO) { Write-OK "Set to $ramKB KB  (~$([math]::Round($ramKB/1MB,1)) GB RAM)" }
    } else { if (-not $AUTO) { Write-Skip "SvcHost threshold skipped" } }

    # CPU priority
    if (Confirm-Step "Prioritize foreground app CPU scheduling?") {
        if (-not $AUTO) { Write-Step "Setting Win32PrioritySeparation..." }
        else            { Auto-Progress "CPU priority" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 26
        if (-not $AUTO) { Write-OK "Win32PrioritySeparation = 26" }
    } else { if (-not $AUTO) { Write-Skip "CPU priority skipped" } }

    # SystemResponsiveness
    if (Confirm-Step "Set SystemResponsiveness to 10% (more CPU to foreground)?") {
        if (-not $AUTO) { Write-Step "Setting SystemResponsiveness..." }
        else            { Auto-Progress "SystemResponsiveness" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10
        if (-not $AUTO) { Write-OK "SystemResponsiveness = 10  (default: 20)" }
    } else { if (-not $AUTO) { Write-Skip "SystemResponsiveness skipped" } }

    # SysMain
    if (Confirm-Step "Disable SysMain (Superfetch)? Recommended for SSDs") {
        if (-not $AUTO) { Write-Step "Disabling SysMain..." }
        else            { Auto-Progress "SysMain" }
        Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
        Set-Service  -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
        if (-not $AUTO) { Write-OK "SysMain disabled" }
    } else { if (-not $AUTO) { Write-Skip "SysMain skipped" } }

    # WSearch
    if (Confirm-Step "Set Windows Search Indexer to manual start?") {
        if (-not $AUTO) { Write-Step "Setting WSearch to manual..." }
        else            { Auto-Progress "WSearch" }
        Set-Service -Name WSearch -StartupType Manual -ErrorAction SilentlyContinue
        if (-not $AUTO) { Write-OK "WSearch set to manual" }
    } else { if (-not $AUTO) { Write-Skip "WSearch skipped" } }

    # Fast Startup
    if (Confirm-Step "Disable Fast Startup?") {
        if (-not $AUTO) { Write-Step "Disabling Fast Startup..." }
        else            { Auto-Progress "Fast Startup" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
        if (-not $AUTO) { Write-OK "Fast Startup disabled" }
    } else { if (-not $AUTO) { Write-Skip "Fast Startup skipped" } }

    # Hibernate
    if (Confirm-Step "Disable Hibernate? (frees disk space = RAM size)") {
        if (-not $AUTO) { Write-Step "Disabling Hibernate..." }
        else            { Auto-Progress "Hibernate" }
        powercfg /hibernate off 2>$null
        if (-not $AUTO) { Write-OK "Hibernate disabled" }
    } else { if (-not $AUTO) { Write-Skip "Hibernate skipped" } }

    # Power Throttling
    if (Confirm-Step "Disable Power Throttling for consistent CPU performance?") {
        if (-not $AUTO) { Write-Step "Disabling Power Throttling..." }
        else            { Auto-Progress "Power Throttling" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1
        if (-not $AUTO) { Write-OK "Power Throttling disabled" }
    } else { if (-not $AUTO) { Write-Skip "Power Throttling skipped" } }

    # Game DVR
    if (Confirm-Step "Disable Xbox Game DVR and Game Bar?") {
        if (-not $AUTO) { Write-Step "Disabling Game DVR..." }
        else            { Auto-Progress "Game DVR" }
        Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_Enabled"           0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR"              0
        Set-Reg "HKCU:\Software\Microsoft\GameBar"                   "UseNexusForGameBarEnabled" 0
        if (-not $AUTO) { Write-OK "Game DVR and Game Bar disabled" }
    } else { if (-not $AUTO) { Write-Skip "Game DVR skipped" } }

    # Visual effects
    if (Confirm-Step "Reduce visual effects and disable transparency?") {
        if (-not $AUTO) { Write-Step "Reducing visual effects..." }
        else            { Auto-Progress "Visual effects" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting"     2
        Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics"                               "MinAnimate"          "0" "String"
        Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"      "EnableTransparency"  0
        if (-not $AUTO) { Write-OK "Visual effects reduced, transparency off" }
    } else { if (-not $AUTO) { Write-Skip "Visual effects skipped" } }

    # Shutdown timeouts
    if (Confirm-Step "Reduce shutdown/kill timeouts for faster shutdown?") {
        if (-not $AUTO) { Write-Step "Reducing shutdown timeouts..." }
        else            { Auto-Progress "Shutdown timeouts" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
        Set-Reg "HKCU:\Control Panel\Desktop"            "WaitToKillAppTimeout"     "2000" "String"
        Set-Reg "HKCU:\Control Panel\Desktop"            "HungAppTimeout"           "3000" "String"
        if (-not $AUTO) { Write-OK "Timeouts reduced (service: 2s, app: 2s, hung: 3s)" }
    } else { if (-not $AUTO) { Write-Skip "Shutdown timeouts skipped" } }

    # Startup delay
    if (Confirm-Step "Remove startup apps delay?") {
        if (-not $AUTO) { Write-Step "Removing startup delay..." }
        else            { Auto-Progress "Startup delay" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
        if (-not $AUTO) { Write-OK "Startup delay removed" }
    } else { if (-not $AUTO) { Write-Skip "Startup delay skipped" } }

    if (-not $AUTO) { Write-Div; Write-OK "Performance tweaks done — reboot recommended"; Pause-Back }
}

# ════════════════════════════════════════════════════════════
#  2. PRIVACY
# ════════════════════════════════════════════════════════════

function Optimize-Privacy {
    if (-not $AUTO) { Show-Banner; Write-Host "  [PRIV] Privacy Tweaks`n" -ForegroundColor Cyan }

    if (Confirm-Step "Disable Windows Telemetry?") {
        if (-not $AUTO) { Write-Step "Disabling Telemetry..." }
        else            { Auto-Progress "Telemetry" }
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"               "AllowTelemetry" 0
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
        if (-not $AUTO) { Write-OK "Telemetry disabled" }
    } else { if (-not $AUTO) { Write-Skip "Telemetry skipped" } }

    if (Confirm-Step "Disable Advertising ID?") {
        if (-not $AUTO) { Write-Step "Disabling Advertising ID..." }
        else            { Auto-Progress "Advertising ID" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
        if (-not $AUTO) { Write-OK "Advertising ID disabled" }
    } else { if (-not $AUTO) { Write-Skip "Advertising ID skipped" } }

    if (Confirm-Step "Disable Cortana?") {
        if (-not $AUTO) { Write-Step "Disabling Cortana..." }
        else            { Auto-Progress "Cortana" }
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"          0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortanaAboveLock" 0
        if (-not $AUTO) { Write-OK "Cortana disabled" }
    } else { if (-not $AUTO) { Write-Skip "Cortana skipped" } }

    if (Confirm-Step "Disable Activity History and Timeline?") {
        if (-not $AUTO) { Write-Step "Disabling Activity History..." }
        else            { Auto-Progress "Activity History" }
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"    0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"  0
        if (-not $AUTO) { Write-OK "Activity History disabled" }
    } else { if (-not $AUTO) { Write-Skip "Activity History skipped" } }

    if (Confirm-Step "Disable Location tracking?") {
        if (-not $AUTO) { Write-Step "Disabling Location..." }
        else            { Auto-Progress "Location" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
        if (-not $AUTO) { Write-OK "Location tracking disabled" }
    } else { if (-not $AUTO) { Write-Skip "Location skipped" } }

    if (Confirm-Step "Block all apps from accessing Camera and Microphone?") {
        if (-not $AUTO) { Write-Step "Blocking Camera/Mic..." }
        else            { Auto-Progress "Camera/Mic" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"     "Value" "Deny" "String"
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny" "String"
        if (-not $AUTO) { Write-Warn "Camera/Mic blocked — re-enable in Settings if needed" }
    } else { if (-not $AUTO) { Write-Skip "Camera/Mic skipped" } }

    if (Confirm-Step "Disable Feedback and Diagnostics prompts?") {
        if (-not $AUTO) { Write-Step "Disabling Feedback..." }
        else            { Auto-Progress "Feedback" }
        Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
        Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds"  0
        if (-not $AUTO) { Write-OK "Feedback disabled" }
    } else { if (-not $AUTO) { Write-Skip "Feedback skipped" } }

    if (Confirm-Step "Disable Tailored Experiences?") {
        if (-not $AUTO) { Write-Step "Disabling Tailored Experiences..." }
        else            { Auto-Progress "Tailored Experiences" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
        if (-not $AUTO) { Write-OK "Tailored Experiences disabled" }
    } else { if (-not $AUTO) { Write-Skip "Tailored Experiences skipped" } }

    if (Confirm-Step "Disable app launch tracking?") {
        if (-not $AUTO) { Write-Step "Disabling launch tracking..." }
        else            { Auto-Progress "Launch tracking" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
        if (-not $AUTO) { Write-OK "Launch tracking disabled" }
    } else { if (-not $AUTO) { Write-Skip "Launch tracking skipped" } }

    if (Confirm-Step "Disable Windows Error Reporting?") {
        if (-not $AUTO) { Write-Step "Disabling Error Reporting..." }
        else            { Auto-Progress "Error Reporting" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
        if (-not $AUTO) { Write-OK "Error Reporting disabled" }
    } else { if (-not $AUTO) { Write-Skip "Error Reporting skipped" } }

    if (Confirm-Step "Disable Remote Assistance?") {
        if (-not $AUTO) { Write-Step "Disabling Remote Assistance..." }
        else            { Auto-Progress "Remote Assistance" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0
        if (-not $AUTO) { Write-OK "Remote Assistance disabled" }
    } else { if (-not $AUTO) { Write-Skip "Remote Assistance skipped" } }

    if (-not $AUTO) { Write-Div; Write-OK "Privacy tweaks done"; Pause-Back }
}

# ════════════════════════════════════════════════════════════
#  3. SERVICES
# ════════════════════════════════════════════════════════════

function Optimize-Services {
    if (-not $AUTO) { Show-Banner; Write-Host "  [SVC] Services Cleanup`n" -ForegroundColor Cyan }

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

    if ($AUTO) {
        foreach ($svc in $services.GetEnumerator()) {
            Auto-Progress "Service: $($svc.Key)"
            Stop-Service -Name $svc.Key -Force -ErrorAction SilentlyContinue
            Set-Service  -Name $svc.Key -StartupType Disabled -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  Disable individual services? (Y=disable, N=keep, Enter=skip all)`n" -ForegroundColor White
        foreach ($svc in $services.GetEnumerator()) {
            $ans = Read-Host "  [$($svc.Key.PadRight(20))] $($svc.Value) — disable? [y/N]"
            if ($ans -match '^[Yy]') {
                Stop-Service -Name $svc.Key -Force -ErrorAction SilentlyContinue
                Set-Service  -Name $svc.Key -StartupType Disabled -ErrorAction SilentlyContinue
                Write-OK "Disabled: $($svc.Key)"
            } else {
                Write-Skip "Kept: $($svc.Key)"
            }
        }
        Write-Div; Write-OK "Services done"; Pause-Back
    }
}

# ════════════════════════════════════════════════════════════
#  4. JUNK CLEANER
# ════════════════════════════════════════════════════════════

function Clean-Junk {
    if (-not $AUTO) { Show-Banner; Write-Host "  [JUNK] Junk File Cleaner`n" -ForegroundColor Cyan }

    $paths = [ordered]@{
        "User Temp"        = $env:TEMP
        "System Temp"      = "$env:SystemRoot\Temp"
        "Prefetch"         = "$env:SystemRoot\Prefetch"
        "IE / Edge Cache"  = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        "Local App Temp"   = "$env:LOCALAPPDATA\Temp"
        "Windows Update"   = "$env:SystemRoot\SoftwareDistribution\Download"
        "Error Reports"    = "$env:LOCALAPPDATA\Microsoft\Windows\WER"
        "Thumbnail Cache"  = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        "Delivery Optim."  = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"
    }

    $totalFreed = 0.0

    foreach ($p in $paths.GetEnumerator()) {
        if (-not (Test-Path $p.Value)) { continue }

        $doClean = if ($AUTO) { $true } else { Confirm-Step "Clean $($p.Key)?" }

        if ($doClean) {
            if (-not $AUTO) { Write-Step "Cleaning $($p.Key)..." }
            else            { Auto-Progress "Junk: $($p.Key)" }

            $before = (Get-ChildItem $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
                       Measure-Object -Property Length -Sum).Sum
            Get-ChildItem -Path $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $after = (Get-ChildItem $p.Value -Recurse -Force -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum).Sum

            $beforeVal  = if ($before) { $before } else { 0 }
            $afterVal   = if ($after)  { $after  } else { 0 }
            $freed      = [Math]::Round(($beforeVal - $afterVal) / 1MB, 1)
            $totalFreed += $freed
            if (-not $AUTO) { Write-OK "Freed ~$freed MB" }
        } else {
            if (-not $AUTO) { Write-Skip "$($p.Key) skipped" }
        }
    }

    # Recycle Bin
    if (Confirm-Step "Empty Recycle Bin?") {
        if (-not $AUTO) { Write-Step "Emptying Recycle Bin..." }
        else            { Auto-Progress "Recycle Bin" }
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        if (-not $AUTO) { Write-OK "Recycle Bin emptied" }
    }

    # Disk Cleanup
    if (Confirm-Step "Run Windows Disk Cleanup (silent)?") {
        if (-not $AUTO) { Write-Step "Running Disk Cleanup..." }
        else            { Auto-Progress "Disk Cleanup" }
        $sageSet = 64
        $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        @("Temporary Files","Downloaded Program Files","Internet Cache Files","Thumbnails",
          "Old ChkDsk Files","Recycle Bin","Setup Log Files","System error memory dump files") | ForEach-Object {
            Set-Reg "$regBase\$_" "StateFlags$sageSet" 2
        }
        Start-Process cleanmgr.exe -ArgumentList "/sagerun:$sageSet" -Wait -ErrorAction SilentlyContinue
        if (-not $AUTO) { Write-OK "Disk Cleanup done" }
    }

    if (-not $AUTO) { Write-Div; Write-OK "Total freed: ~$totalFreed MB"; Pause-Back }
}

# ════════════════════════════════════════════════════════════
#  5. NETWORK
# ════════════════════════════════════════════════════════════

function Optimize-Network {
    if (-not $AUTO) { Show-Banner; Write-Host "  [NET] Network Tweaks`n" -ForegroundColor Cyan }

    if (Confirm-Step "Disable MMCSS network throttling?") {
        if (-not $AUTO) { Write-Step "Disabling network throttling..." }
        else            { Auto-Progress "Network throttling" }
        Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
        if (-not $AUTO) { Write-OK "NetworkThrottlingIndex = 0xFFFFFFFF" }
    } else { if (-not $AUTO) { Write-Skip "Network throttling skipped" } }

    if (Confirm-Step "Increase IRPStackSize for better throughput?") {
        if (-not $AUTO) { Write-Step "Setting IRPStackSize..." }
        else            { Auto-Progress "IRPStackSize" }
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 32
        if (-not $AUTO) { Write-OK "IRPStackSize = 32  (default: 15)" }
    } else { if (-not $AUTO) { Write-Skip "IRPStackSize skipped" } }

    # DNS — auto uses Cloudflare, interactive asks
    if ($AUTO) {
        Auto-Progress "DNS (Cloudflare)"
        Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex -ServerAddresses @("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        }
    } else {
        $dnsVal = Select-Option "Choose DNS provider:" `
            @("Cloudflare  1.1.1.1 / 1.0.0.1  (fast + privacy)",
              "Google      8.8.8.8 / 8.8.4.4",
              "Quad9       9.9.9.9 / 149.112.112.112  (malware blocking)") `
            @("cloudflare","google","quad9") `
            "cloudflare"

        if ($dnsVal) {
            $map = @{
                cloudflare = @("1.1.1.1","1.0.0.1")
                google     = @("8.8.8.8","8.8.4.4")
                quad9      = @("9.9.9.9","149.112.112.112")
            }
            Write-Step "Setting DNS to $dnsVal..."
            Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex -ServerAddresses $map[$dnsVal] -ErrorAction SilentlyContinue
            }
            Write-OK "DNS set to $($map[$dnsVal] -join ' / ')  ($dnsVal)"
        } else { Write-Skip "DNS skipped" }
    }

    if (Confirm-Step "Flush DNS cache?") {
        if (-not $AUTO) { Write-Step "Flushing DNS..." }
        else            { Auto-Progress "DNS flush" }
        ipconfig /flushdns | Out-Null
        if (-not $AUTO) { Write-OK "DNS flushed" }
    }

    if (Confirm-Step "Apply TCP tweaks (Nagle off, SACK, auto-tuning, ECN)?") {
        if (-not $AUTO) { Write-Step "Applying TCP tweaks..." }
        else            { Auto-Progress "TCP tweaks" }
        $tcpGlobal = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-Reg $tcpGlobal "TCPNoDelay"      1
        Set-Reg $tcpGlobal "TcpAckFrequency" 1
        Set-Reg $tcpGlobal "Tcp1323Opts"     1
        Set-Reg $tcpGlobal "DefaultTTL"      64
        $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        Get-ChildItem $ifPath -ErrorAction SilentlyContinue | ForEach-Object {
            Set-Reg $_.PSPath "TcpAckFrequency" 1
            Set-Reg $_.PSPath "TCPNoDelay"      1
        }
        netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
        netsh int tcp set global ecncapability=enabled  2>$null | Out-Null
        netsh int tcp set global timestamps=disabled    2>$null | Out-Null
        if (-not $AUTO) { Write-OK "TCP tweaks applied" }
    } else { if (-not $AUTO) { Write-Skip "TCP tweaks skipped" } }

    if (Confirm-Step "Disable QoS bandwidth reservation (removes 20% cap)?") {
        if (-not $AUTO) { Write-Step "Disabling QoS reservation..." }
        else            { Auto-Progress "QoS" }
        Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
        if (-not $AUTO) { Write-OK "QoS reservation removed" }
    } else { if (-not $AUTO) { Write-Skip "QoS skipped" } }

    if (-not $AUTO) { Write-Div; Write-OK "Network tweaks done"; Pause-Back }
}

# ════════════════════════════════════════════════════════════
#  6. EXPLORER & UI
# ════════════════════════════════════════════════════════════

function Optimize-Explorer {
    if (-not $AUTO) { Show-Banner; Write-Host "  [UI] Explorer & UI Tweaks`n" -ForegroundColor Cyan }

    $advPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $cdmPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $deskPath  = "HKCU:\Control Panel\Desktop"

    if (Confirm-Step "Show file extensions?") {
        if (-not $AUTO) { Write-Step "Showing file extensions..." }
        else            { Auto-Progress "File extensions" }
        Set-Reg $advPath "HideFileExt" 0
        if (-not $AUTO) { Write-OK "File extensions visible" }
    } else { if (-not $AUTO) { Write-Skip "File extensions skipped" } }

    if (Confirm-Step "Show hidden files?") {
        if (-not $AUTO) { Write-Step "Showing hidden files..." }
        else            { Auto-Progress "Hidden files" }
        Set-Reg $advPath "Hidden" 1
        if (-not $AUTO) { Write-OK "Hidden files visible" }
    } else { if (-not $AUTO) { Write-Skip "Hidden files skipped" } }

    if (Confirm-Step "Show full path in Explorer title bar?") {
        if (-not $AUTO) { Write-Step "Enabling full path..." }
        else            { Auto-Progress "Full path" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1
        if (-not $AUTO) { Write-OK "Full path in title bar enabled" }
    } else { if (-not $AUTO) { Write-Skip "Full path skipped" } }

    if (Confirm-Step "Reduce menu show delay (400ms to 50ms)?") {
        if (-not $AUTO) { Write-Step "Reducing MenuShowDelay..." }
        else            { Auto-Progress "MenuShowDelay" }
        Set-Reg $deskPath "MenuShowDelay" "50" "String"
        if (-not $AUTO) { Write-OK "MenuShowDelay = 50ms" }
    } else { if (-not $AUTO) { Write-Skip "MenuShowDelay skipped" } }

    if (Confirm-Step "Disable Bing search in Start Menu?") {
        if (-not $AUTO) { Write-Step "Disabling Bing in Start..." }
        else            { Auto-Progress "Bing in Start" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent"    0
        if (-not $AUTO) { Write-OK "Bing search disabled" }
    } else { if (-not $AUTO) { Write-Skip "Bing search skipped" } }

    if (Confirm-Step "Enable dark mode?") {
        if (-not $AUTO) { Write-Step "Enabling dark mode..." }
        else            { Auto-Progress "Dark mode" }
        Set-Reg $themePath "AppsUseLightTheme"    0
        Set-Reg $themePath "SystemUsesLightTheme" 0
        if (-not $AUTO) { Write-OK "Dark mode enabled" }
    } else { if (-not $AUTO) { Write-Skip "Dark mode skipped" } }

    if (Confirm-Step "Disable lock screen ads and Start suggestions?") {
        if (-not $AUTO) { Write-Step "Disabling ads and suggestions..." }
        else            { Auto-Progress "Ads/Suggestions" }
        @("RotatingLockScreenOverlayEnabled","SubscribedContent-338387Enabled",
          "SubscribedContent-338388Enabled","SubscribedContent-353698Enabled",
          "SubscribedContent-310093Enabled","SoftLandingEnabled",
          "SystemPaneSuggestionsEnabled","PreInstalledAppsEnabled",
          "OemPreInstalledAppsEnabled") | ForEach-Object { Set-Reg $cdmPath $_ 0 }
        if (-not $AUTO) { Write-OK "Ads and suggestions disabled" }
    } else { if (-not $AUTO) { Write-Skip "Ads/Suggestions skipped" } }

    if (Confirm-Step "Hide News and Interests from taskbar?") {
        if (-not $AUTO) { Write-Step "Hiding News & Interests..." }
        else            { Auto-Progress "News & Interests" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2
        if (-not $AUTO) { Write-OK "News & Interests hidden" }
    } else { if (-not $AUTO) { Write-Skip "News & Interests skipped" } }

    if (Confirm-Step "Align taskbar to Left (Windows 11)?") {
        if (-not $AUTO) { Write-Step "Aligning taskbar left..." }
        else            { Auto-Progress "Taskbar alignment" }
        Set-Reg $advPath "TaskbarAl" 0
        if (-not $AUTO) { Write-OK "Taskbar aligned left" }
    } else { if (-not $AUTO) { Write-Skip "Taskbar alignment skipped" } }

    if (Confirm-Step "Restore classic right-click context menu (Windows 11)?") {
        if (-not $AUTO) { Write-Step "Restoring classic context menu..." }
        else            { Auto-Progress "Classic context menu" }
        Set-Reg "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(Default)" "" "String"
        if (-not $AUTO) { Write-OK "Classic context menu restored" }
    } else { if (-not $AUTO) { Write-Skip "Context menu skipped" } }

    if (Confirm-Step "Hide OneDrive from Explorer sidebar?") {
        if (-not $AUTO) { Write-Step "Hiding OneDrive..." }
        else            { Auto-Progress "OneDrive sidebar" }
        Set-Reg "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0 | Out-Null
        Set-Reg "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0 | Out-Null
        if (-not $AUTO) { Write-OK "OneDrive removed from sidebar" }
    } else { if (-not $AUTO) { Write-Skip "OneDrive skipped" } }

    if (Confirm-Step "Disable low disk space warnings?") {
        if (-not $AUTO) { Write-Step "Disabling disk space warnings..." }
        else            { Auto-Progress "Disk space warnings" }
        Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoLowDiskSpaceChecks" 1
        if (-not $AUTO) { Write-OK "Disk space warnings disabled" }
    } else { if (-not $AUTO) { Write-Skip "Disk space warnings skipped" } }

    # Restart Explorer
    if (Confirm-Step "Restart Explorer to apply UI changes now?") {
        if (-not $AUTO) { Write-Step "Restarting Explorer..." }
        else            { Auto-Progress "Restart Explorer" }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800
        Start-Process explorer
        if (-not $AUTO) { Write-OK "Explorer restarted" }
    }

    if (-not $AUTO) { Write-Div; Write-OK "Explorer & UI tweaks done"; Pause-Back }
}

# ════════════════════════════════════════════════════════════
#  AUTO MODE — count steps then run all silently
# ════════════════════════════════════════════════════════════

function Run-Auto {
    $script:AUTO = $true

    # Count total steps for the progress bar
    # Performance: 13, Privacy: 11, Services: 17, Junk: 11, Network: 6, Explorer: 13
    $script:AUTO_STEPS_TOTAL = 71
    $script:AUTO_STEPS_DONE  = 0

    Show-Banner
    Write-Host "  Running full auto-optimization...`n" -ForegroundColor Cyan
    Write-Host "  All tweaks will be applied silently. This may take a minute.`n" -ForegroundColor DarkGray

    Backup-Registry
    Write-Host ""

    Optimize-Performance
    Optimize-Privacy
    Optimize-Services
    Clean-Junk
    Optimize-Network
    Optimize-Explorer

    # Final newline after progress bar
    Write-Host ""
    Write-Host ""

    $script:AUTO = $false

    Show-Banner
    Write-Host "  [OK] Auto-optimization complete!" -ForegroundColor Green
    Write-Host "  [!]  Reboot recommended for all changes to take effect.`n" -ForegroundColor Yellow
    Pause-Back
}

# ════════════════════════════════════════════════════════════
#  MAIN MENU
# ════════════════════════════════════════════════════════════

while ($true) {
    Show-Banner

    Write-Host "  [A]  AUTO         Apply everything silently (recommended for fresh setup)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [1]  Performance  Choose: power plan, SysMain, throttling, timeouts..." -ForegroundColor Gray
    Write-Host "  [2]  Privacy      Choose: telemetry, Cortana, camera, ads..."           -ForegroundColor Gray
    Write-Host "  [3]  Services     Choose: disable services one by one"                   -ForegroundColor Gray
    Write-Host "  [4]  Junk         Choose: which temp folders to clean"                   -ForegroundColor Gray
    Write-Host "  [5]  Network      Choose: DNS provider, TCP tweaks, QoS..."              -ForegroundColor Gray
    Write-Host "  [6]  Explorer/UI  Choose: dark mode, menus, taskbar, OneDrive..."        -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [B]  Backup registry only"                                               -ForegroundColor DarkGray
    Write-Host "  [Q]  Exit"                                                               -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "  Choice"

    switch ($choice.ToUpper()) {
        "A" { Run-Auto             }
        "1" { Optimize-Performance }
        "2" { Optimize-Privacy     }
        "3" { Optimize-Services    }
        "4" { Clean-Junk           }
        "5" { Optimize-Network     }
        "6" { Optimize-Explorer    }
        "B" { Show-Banner; Backup-Registry; Pause-Back }
        "Q" { Clear-Host; Write-Host "`n  Bye!`n" -ForegroundColor Cyan; exit }
        default { Write-Host "  Invalid choice." -ForegroundColor Red; Start-Sleep 1 }
    }
}
