#requires -RunAsAdministrator
<#
merybist Optimizer v4 PRO (Rebuilt Structure, ASCII only)
- Interactive Auto mode: asks Y/N before every action
- Rollback JSON: registry/service/netadapter changes -> -Undo
- Aggressive services kept + warning + restore
- Keeps your "Registry Tweaks (Basic)" exactly (the пункт 6 keys)

Examples:
  .\opt.ps1
  .\opt.ps1 -Auto -Preset Balanced
  .\opt.ps1 -Auto -Preset Aggressive
  .\opt.ps1 -Undo
  .\opt.ps1 -WhatIf -Auto -Preset Aggressive
#>

param(
    [switch]$Auto,
    [ValidateSet("Safe","Balanced","Aggressive")] [string]$Preset = "Balanced",
    [switch]$Undo,
    [switch]$WhatIf
)

# =========================
# Setup
# =========================
$ConfirmPreference = 'None'
$ErrorActionPreference = 'Continue'

$root = "C:\merybist-opt"
$log  = Join-Path $root "opt.log"
$stateDir = Join-Path $root "state"
New-Item -ItemType Directory -Path $root -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $stateDir -ErrorAction SilentlyContinue | Out-Null

function Write-Log {
    param([string]$msg, [string]$color = "Gray")
    $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $log -Value $line
}

function Line { param([int]$n = 62, [string]$ch = "=",[string]$color="Cyan") Write-Host ($ch * $n) -ForegroundColor $color }

Write-Log "=== merybist Optimizer v4 PRO (ASCII only) ===" "Cyan"
if ($WhatIf) { Write-Log "WHATIF MODE: changes will be logged but not applied." "Yellow" }

# =========================
# State / Rollback
# =========================
$runId = (Get-Date -Format "yyyyMMdd_HHmmss")
$stateFile = Join-Path $stateDir ("state_$runId.json")

$global:State = [ordered]@{
    runId    = $runId
    created  = (Get-Date).ToString("o")
    changes  = @()   # objects: type, target, before, after, meta
}

function Save-State {
    try { ($global:State | ConvertTo-Json -Depth 8) | Set-Content -Path $stateFile -Encoding UTF8 } catch {}
}

function Add-Change {
    param([string]$Type,[string]$Target,$Before,$After,$Meta=$null)
    $global:State.changes += [ordered]@{ type=$Type; target=$Target; before=$Before; after=$After; meta=$Meta }
    Save-State
}

function Get-LastStateFile {
    Get-ChildItem $stateDir -Filter "state_*.json" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
}

# =========================
# Prompt helpers
# =========================
function Ask-YesNo {
    param([string]$Question, [ValidateSet("Y","N")] [string]$Default = "Y")
    $suffix = ($Default -eq "Y") ? "[Y/n]" : "[y/N]"
    while ($true) {
        $ans = Read-Host "$Question $suffix"
        if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $Default }
        $ans = $ans.Trim().ToLower()
        if ($ans -in @("y","yes")) { return $true }
        if ($ans -in @("n","no"))  { return $false }
        Write-Host "Please type Y or N." -ForegroundColor Yellow
    }
}

function Confirm-RiskyAction {
    param([string]$Title,[string]$Details)
    Line 62 "!" "Red"
    Write-Host "WARNING: $Title" -ForegroundColor Red
    if ($Details) { Write-Host $Details -ForegroundColor Red }
    Line 62 "!" "Red"
    $ans = Read-Host "Type YES to continue"
    return ($ans -eq "YES")
}

# =========================
# Registry helpers
# =========================
function Ensure-RegKey {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        if (-not $WhatIf) { New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null }
    }
}

function Get-RegValue {
    param([string]$Path,[string]$Name)
    try {
        if (Test-Path $Path) {
            $p = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            if ($null -ne $p -and ($p.PSObject.Properties.Name -contains $Name)) { return $p.$Name }
        }
    } catch {}
    return $null
}

function Reg-Set {
    param(
        [string]$Path,[string]$Name,[Object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    Ensure-RegKey $Path
    $before = Get-RegValue $Path $Name
    Add-Change "registry_set" "$Path\$Name" $before $Value @{ kind="$Type" }

    if ($WhatIf) { return }

    try {
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {
        try { Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction SilentlyContinue } catch {}
    }
}

function Reg-Remove {
    param([string]$Path,[string]$Name)
    $before = Get-RegValue $Path $Name
    Add-Change "registry_remove" "$Path\$Name" $before $null $null

    if ($WhatIf) { return }

    try {
        if (Test-Path $Path) {
            $p = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            if ($null -ne $p -and ($p.PSObject.Properties.Name -contains $Name)) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

# =========================
# Service helpers
# =========================
function Svc-Disable {
    param([string]$Name)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Log "Service $Name not found, skipping." "DarkGray"; return }

    $before = [ordered]@{ status="$($svc.Status)"; startType="$($svc.StartType)" }
    Add-Change "service" $Name $before @{ action="Disable" } $null

    if ($WhatIf) { Write-Log "WHATIF: would disable service $Name" "DarkYellow"; return }

    try {
        Stop-Service $Name -Force -ErrorAction SilentlyContinue
        Set-Service $Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Log "Disabled service: $Name" "Green"
    } catch {
        Write-Log "Failed to disable $Name: $($_.Exception.Message)" "DarkYellow"
    }
}

function Svc-Enable {
    param([string]$Name, [ValidateSet("Automatic","Manual")] [string]$Startup="Automatic")
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Log "Service $Name not found, skipping." "DarkGray"; return }

    $before = [ordered]@{ status="$($svc.Status)"; startType="$($svc.StartType)" }
    Add-Change "service" $Name $before @{ action="Enable"; startup=$Startup } $null

    if ($WhatIf) { Write-Log "WHATIF: would enable service $Name ($Startup)" "DarkYellow"; return }

    try {
        Set-Service $Name -StartupType $Startup -ErrorAction SilentlyContinue
        Start-Service $Name -ErrorAction SilentlyContinue
        Write-Log "Enabled service: $Name ($Startup)" "Green"
    } catch {
        Write-Log "Failed to enable $Name: $($_.Exception.Message)" "DarkYellow"
    }
}

# =========================
# System detect
# =========================
function Is-Laptop { try { return ($null -ne (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)) } catch { return $false } }

function Get-StorageProfile {
    try {
        $physical = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($physical) {
            $ssd = @($physical | Where-Object MediaType -eq "SSD")
            $hdd = @($physical | Where-Object MediaType -eq "HDD")
            if ($ssd.Count -gt 0 -and $hdd.Count -eq 0) { return "SSD" }
            if ($hdd.Count -gt 0 -and $ssd.Count -eq 0) { return "HDD" }
            if ($ssd.Count -gt 0 -and $hdd.Count -gt 0) { return "Mixed" }
        }
    } catch {}
    return "Unknown"
}

function Get-SystemProfile {
    $p = [ordered]@{ Caption="Unknown"; Version=""; Build=""; IsWindows11=$false; Device="Desktop"; Storage="Unknown" }
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $p.Caption = $os.Caption
        $p.Version = $os.Version
        $p.Build   = $os.BuildNumber
        if (($os.Caption -match "Windows 11") -or ([version]$os.Version -ge [version]"10.0.22000")) { $p.IsWindows11 = $true }
    } catch {}
    $p.Device  = (Is-Laptop) ? "Laptop" : "Desktop"
    $p.Storage = Get-StorageProfile
    return $p
}

# =========================
# Core actions (handlers)
# =========================
function Act-RestorePoint {
    Write-Log "Creating restore point..." "Yellow"
    if ($WhatIf) { Write-Log "WHATIF: would create restore point" "DarkYellow"; return }
    try {
        Checkpoint-Computer -Description "merybist optimizer v4 PRO restore point" -RestorePointType "Modify_Settings"
        Write-Log "Restore point created." "Green"
    } catch {
        Write-Log "Restore point failed or unsupported: $($_.Exception.Message)" "DarkYellow"
    }
}

function Act-Defender-Off {
    Write-Log "Disabling Windows Defender (policy + services best-effort)..." "Yellow"
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 1
    foreach ($s in @("WinDefend","WdNisSvc")) { Svc-Disable $s }
    Write-Log "Note: Security Center services are handled in Aggressive Services, not here." "DarkYellow"
    Write-Log "Defender disable applied. Reboot recommended." "Green"
}

function Act-Defender-On {
    Write-Log "Enabling Windows Defender (policy + services)..." "Yellow"
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableRoutinelyTakingAction" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableBehaviorMonitoring" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 0
    foreach ($s in @("WinDefend","WdNisSvc")) { Svc-Enable $s "Automatic" }
    Write-Log "Defender enable applied. Reboot recommended." "Green"
}

function Act-UAC-Off {
    Write-Log "Disabling UAC..." "Yellow"
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0
    Write-Log "UAC disabled (reboot required)." "Green"
}

function Act-UAC-On {
    Write-Log "Enabling UAC..." "Yellow"
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1
    Write-Log "UAC enabled (reboot required)." "Green"
}

function Act-GameDVR-Off {
    Write-Log "Disabling Game DVR and Captures..." "Yellow"
    Reg-Set "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Reg-Set "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Reg-Set "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    Write-Log "Game DVR disabled." "Green"
}

function Act-GameDVR-On {
    Write-Log "Enabling Game DVR..." "Yellow"
    Reg-Set "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1
    Reg-Set "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 1
    Reg-Remove "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR"
    Write-Log "Game DVR enabled (policy removed)." "Green"
}

function Act-MouseAccel-Off {
    Write-Log "Mouse acceleration OFF..." "Yellow"
    Reg-Set "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" ([Microsoft.Win32.RegistryValueKind]::String)
    Reg-Set "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" ([Microsoft.Win32.RegistryValueKind]::String)
    Reg-Set "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" ([Microsoft.Win32.RegistryValueKind]::String)
    Write-Log "Mouse acceleration OFF applied." "Green"
}

function Act-Visual-Performance {
    Write-Log "Visual effects -> Performance..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Write-Log "Visual effects set to performance." "Green"
}

function Act-Visual-Default {
    Write-Log "Visual effects -> Default..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 1
    Write-Log "Visual effects restored to default." "Green"
}

function Act-BackgroundApps-Off {
    Write-Log "Disabling background apps..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Write-Log "Background apps disabled." "Green"
}

function Act-HAGS {
    param([ValidateSet("Default","On","Off")] [string]$Mode="Default")
    Write-Log "HAGS mode: $Mode" "Yellow"
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if ($Mode -eq "Default") { Reg-Remove $path "HwSchMode"; Write-Log "HAGS set to Default." "Green"; return }
    $val = ($Mode -eq "On") ? 2 : 1
    Reg-Set $path "HwSchMode" $val
    Write-Log "HAGS applied (HwSchMode=$val). Reboot recommended." "Green"
}

function Act-PowerPlan-Smart {
    $p = Get-SystemProfile
    if ($p.Device -eq "Laptop") {
        Write-Log "Laptop -> High performance power scheme." "Yellow"
        if ($WhatIf) { Write-Log "WHATIF: would set power scheme SCHEME_MIN" "DarkYellow"; return }
        try { powercfg -setactive SCHEME_MIN | Out-Null } catch {}
        return
    }

    Write-Log "Desktop -> Ultimate performance power scheme." "Yellow"
    $ultimate = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    if ($WhatIf) { Write-Log "WHATIF: would set Ultimate performance" "DarkYellow"; return }

    try {
        $out = (powercfg -duplicatescheme $ultimate 2>$null)
        $newGuid = $null
        if ($out) {
            $m = ($out | Out-String) -match "([0-9a-fA-F-]{36})"
            if ($m) { $newGuid = $Matches[1] }
        }
        if ($newGuid) { powercfg -setactive $newGuid | Out-Null; Write-Log "Ultimate active: $newGuid" "Green" }
        else { powercfg -setactive SCHEME_MIN | Out-Null; Write-Log "Ultimate not created -> High performance set." "DarkYellow" }
    } catch {
        Write-Log "Power plan failed: $($_.Exception.Message)" "DarkYellow"
    }
}

function Act-Cleanup-Safe {
    Write-Log "Running safe cleanup..." "Yellow"
    if ($WhatIf) { Write-Log "WHATIF: would cleanup temp + SoftwareDistribution download" "DarkYellow"; return }

    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    try {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    } catch {}
    try { Start-Service wuauserv -ErrorAction SilentlyContinue } catch {}
    Write-Log "Cleanup done." "Green"
}

# =========================
# KEEP YOUR пункт 6 EXACTLY (same keys/values)
# =========================
function Act-RegistryBasic-Apply {
    Write-Log "Applying registry performance tweaks (Basic)..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 0
    Write-Log "Registry performance tweaks applied." "Green"
}

function Act-RegistryBasic-Restore {
    Write-Log "Restoring registry defaults (Basic)..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 1
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 1
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 3
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 3
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" "SearchOrderConfig" 1
    Write-Log "Registry defaults restored." "Green"
}

# =========================
# Services: SAFE / AGGRESSIVE / RESTORE
# =========================
$SAFE_SERVICES = @("Fax","DiagTrack","dmwappushservice","MapsBroker","RemoteRegistry","WMPNetworkSvc")

# aggressive list: based on your previous list + extras you had
$AGGRESSIVE_SERVICES = @(
    "Fax","DiagTrack","SysMain","XblGameSave","XboxNetApiSvc","XboxGipSvc","MapsBroker","RemoteRegistry",
    "WerSvc","dmwappushservice","RetailDemo","SensrSvc","SessionEnv","SharedAccess","shpamsvc","SNMPTRAP",
    "Spooler","ssh-agent","TermService","TroubleshootingSvc","UevAgentService","uhssvc","UmRdpService",
    "vmicguestinterface","vmicheartbeat","vmickvpexchange","vmicrdv","vmicshutdown","vmictimesync",
    "vmicvmsession","vmicvss","WarpJITSvc","WbioSrvc","WdiServiceHost","WdiSystemHost","WdNisSvc",
    "WMPNetworkSvc","workfolderssvc","WpnService","WwanSvc","XblAuthManager",
    "SecurityHealthService","wscsvc","Themes","WSearch","WebClient","Wecsvc","WiaRpc","wlpasvc","wmiApSrv","WFDSConMgrSvc","WPDBusEnum"
)

# restore targets: best-effort
$RESTORE_SERVICES = @(
    "Fax","DiagTrack","SysMain","XblGameSave","XboxNetApiSvc","XboxGipSvc","MapsBroker","RemoteRegistry",
    "WerSvc","dmwappushservice","RetailDemo","SensrSvc","SessionEnv","SharedAccess","shpamsvc","SNMPTRAP",
    "Spooler","ssh-agent","TermService","TroubleshootingSvc","UevAgentService","uhssvc","UmRdpService",
    "vmicguestinterface","vmicheartbeat","vmickvpexchange","vmicrdv","vmicshutdown","vmictimesync",
    "vmicvmsession","vmicvss","WarpJITSvc","WbioSrvc","WdiServiceHost","WdiSystemHost","WdNisSvc",
    "WebClient","Wecsvc","WiaRpc","wlpasvc","wmiApSrv","WMPNetworkSvc","workfolderssvc","WPDBusEnum",
    "WpnService","wscsvc","WSearch","WwanSvc","XblAuthManager","SecurityHealthService","Themes","WFDSConMgrSvc"
)

function Act-Services-SafeOff {
    Write-Log "Disabling SAFE services..." "Yellow"
    foreach ($s in $SAFE_SERVICES) { Svc-Disable $s }
    Write-Log "SAFE services disabled." "Green"
}

function Act-Services-AggressiveOff {
    $ok = Confirm-RiskyAction "AGGRESSIVE SERVICES" "This may break Store, notifications, printing, RDP, updates, Security Center, etc."
    if (-not $ok) { Write-Log "Aggressive services canceled." "DarkYellow"; return }

    Write-Log "Disabling AGGRESSIVE services set..." "Yellow"
    foreach ($s in $AGGRESSIVE_SERVICES) { Svc-Disable $s }
    Write-Log "Aggressive services disabled." "Green"
}

function Act-Services-Restore {
    Write-Log "Restoring services (best-effort)..." "Yellow"
    foreach ($s in $RESTORE_SERVICES) { Svc-Enable $s "Manual" }

    # typical autos:
    Svc-Enable "SysMain" "Automatic"
    Svc-Enable "WSearch" "Automatic"
    Svc-Enable "wscsvc" "Automatic"
    Svc-Enable "SecurityHealthService" "Automatic"
    Svc-Enable "Spooler" "Automatic"
    Svc-Enable "Themes" "Automatic"

    Write-Log "Services restored (best-effort). Reboot recommended." "Green"
}

# =========================
# Optional: NIC tweaks (best-effort)
# =========================
function Act-NIC-Optional {
    Write-Log "Network adapter tweaks (OPTIONAL, best-effort)..." "Yellow"
    try {
        $adapters = Get-NetAdapter | Where-Object Status -eq "Up"
        foreach ($a in $adapters) {
            Write-Log "Adapter: $($a.Name) ($($a.InterfaceDescription))" "Gray"
            $props = Get-NetAdapterAdvancedProperty -Name $a.Name -ErrorAction SilentlyContinue
            if (-not $props) { continue }

            function Set-AdvIfExists($nameLike,$desired) {
                $p = $props | Where-Object { $_.DisplayName -like $nameLike -or $_.RegistryKeyword -like $nameLike } | Select-Object -First 1
                if ($p) {
                    Add-Change "netadapter" "$($a.Name):$($p.DisplayName)" $p.DisplayValue $desired $p.RegistryKeyword
                    if ($WhatIf) { Write-Log "WHATIF: would set '$($p.DisplayName)' to '$desired' on $($a.Name)" "DarkYellow"; return }
                    try {
                        Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $p.DisplayName -DisplayValue $desired -NoRestart -ErrorAction SilentlyContinue
                        Write-Log "Set $($p.DisplayName) -> $desired" "Green"
                    } catch {}
                }
            }

            Set-AdvIfExists "*Interrupt Moderation*" "Disabled"
            Set-AdvIfExists "*Energy Efficient Ethernet*" "Disabled"
            Set-AdvIfExists "*Green Ethernet*" "Disabled"
            Set-AdvIfExists "*Power Saving*" "Disabled"
            Set-AdvIfExists "*Receive Side Scaling*" "Enabled"
        }
        Write-Log "NIC tweaks applied (best-effort). Reboot may be required." "Green"
    } catch {
        Write-Log "NIC tweaks failed: $($_.Exception.Message)" "DarkYellow"
    }
}

# =========================
# Action registry (data-driven)
# =========================
$ACTIONS = @(
    @{ id="rp";        title="Create restore point";        risk="safe";      run={ Act-RestorePoint } },
    @{ id="reg_basic"; title="Registry Tweaks (Basic) apply";risk="safe";      run={ Act-RegistryBasic-Apply } },
    @{ id="gamedvr";   title="Disable GameDVR/Captures";     risk="safe";      run={ Act-GameDVR-Off } },
    @{ id="bgapps";    title="Disable background apps";      risk="safe";      run={ Act-BackgroundApps-Off } },
    @{ id="mouse";     title="Mouse acceleration OFF";       risk="safe";      run={ Act-MouseAccel-Off } },
    @{ id="visual";    title="Visual effects Performance";   risk="safe";      run={ Act-Visual-Performance } },
    @{ id="power";     title="Smart power plan";             risk="safe";      run={ Act-PowerPlan-Smart } },
    @{ id="hags";      title="HAGS set (ask mode)";          risk="optional";  run={
            $mode = Read-Host "HAGS mode (Default/On/Off)"
            if ($mode -notin @("Default","On","Off")) { $mode = "Default" }
            Act-HAGS $mode
        }
    },
    @{ id="svc_safe";  title="Disable SAFE services";        risk="medium";    run={ Act-Services-SafeOff } },
    @{ id="svc_aggr";  title="Disable AGGRESSIVE services";  risk="high";      run={ Act-Services-AggressiveOff } },
    @{ id="svc_rest";  title="Restore services";             risk="safe";      run={ Act-Services-Restore } },
    @{ id="nic";       title="NIC optional tweaks";          risk="optional";  run={ Act-NIC-Optional } },
    @{ id="clean";     title="Cleanup (safe)";               risk="optional";  run={ Act-Cleanup-Safe } },
    @{ id="def_off";   title="Disable Defender";             risk="high";      run={ Act-Defender-Off } },
    @{ id="def_on";    title="Enable Defender";              risk="safe";      run={ Act-Defender-On } },
    @{ id="uac_off";   title="Disable UAC";                  risk="high";      run={ Act-UAC-Off } },
    @{ id="uac_on";    title="Enable UAC";                   risk="safe";      run={ Act-UAC-On } },
    @{ id="reg_rest";  title="Registry Tweaks (Basic) restore"; risk="safe";   run={ Act-RegistryBasic-Restore } },
    @{ id="gamedvr_on";title="Enable GameDVR/Captures";      risk="safe";      run={ Act-GameDVR-On } },
    @{ id="visual_def";title="Visual effects Default";       risk="safe";      run={ Act-Visual-Default } }
)

function Get-ActionById($id) {
    $ACTIONS | Where-Object { $_.id -eq $id } | Select-Object -First 1
}

function Run-ActionInteractive {
    param([string]$ActionId, [string]$Default="Y")
    $a = Get-ActionById $ActionId
    if (-not $a) { Write-Log "Action not found: $ActionId" "DarkYellow"; return }
    $q = "Run: $($a.title)?"
    $do = Ask-YesNo $q $Default
    if (-not $do) { Write-Log "Skipped: $($a.title)" "DarkGray"; return }
    & $a.run
}

# =========================
# Auto Optimize (interactive Y/N for every step)
# =========================
function Auto-Optimize {
    Write-Log "AUTO optimize (interactive) preset=$Preset" "Cyan"
    $p = Get-SystemProfile
    Write-Log ("Detected: {0} | Build {1} | Device={2} | Storage={3}" -f $p.Caption, $p.Build, $p.Device, $p.Storage) "Gray"

    Run-ActionInteractive "rp" "Y"
    Run-ActionInteractive "reg_basic" "Y"
    Run-ActionInteractive "gamedvr" "Y"
    Run-ActionInteractive "bgapps" "Y"
    Run-ActionInteractive "mouse" "Y"
    Run-ActionInteractive "visual" "Y"
    Run-ActionInteractive "power" "Y"

    # HAGS: default NO
    Run-ActionInteractive "hags" "N"

    # Services by preset (still asks Y/N before applying)
    if ($Preset -eq "Safe") {
        Run-ActionInteractive "svc_safe" "Y"
    }
    elseif ($Preset -eq "Balanced") {
        Run-ActionInteractive "svc_safe" "Y"
        if ($p.Storage -eq "HDD") {
            Write-Log "HDD detected -> SysMain/WSearch are often useful. No forced changes here." "Yellow"
        }
    }
    elseif ($Preset -eq "Aggressive") {
        Run-ActionInteractive "svc_safe" "Y"
        Run-ActionInteractive "svc_aggr" "N"
    }

    # Optional extras
    Run-ActionInteractive "nic" "N"
    Run-ActionInteractive "clean" "N"

    Write-Log "AUTO optimize finished. Reboot recommended." "Green"
    Write-Log "State saved: $stateFile" "Gray"
}

# =========================
# Undo (rollback last run)
# =========================
function Undo-Last {
    $f = Get-LastStateFile
    if (-not $f) { Write-Log "No state file found to undo." "DarkYellow"; return }
    Write-Log "UNDO using: $($f.FullName)" "Yellow"

    $json = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $json) { Write-Log "Cannot read state file." "DarkYellow"; return }
    $st = $json | ConvertFrom-Json

    $arr = @($st.changes)
    for ($i = $arr.Count - 1; $i -ge 0; $i--) {
        $c = $arr[$i]

        if ($c.type -eq "registry_set") {
            $parts = $c.target -split "\\"
            $name = $parts[-1]
            $path = ($parts[0..($parts.Length-2)] -join "\")
            $psPath = $path.Replace("HKLM\","HKLM:\").Replace("HKCU\","HKCU:\")

            if ($null -eq $c.before) {
                if ($WhatIf) { Write-Log "WHATIF undo: remove $psPath\$name" "DarkYellow" }
                else { Reg-Remove $psPath $name }
            } else {
                $kind = $c.meta.kind
                $rk = [Microsoft.Win32.RegistryValueKind]::$kind
                if ($WhatIf) { Write-Log "WHATIF undo: set $psPath\$name=$($c.before)" "DarkYellow" }
                else { Reg-Set $psPath $name $c.before $rk }
            }
        }
        elseif ($c.type -eq "registry_remove") {
            $parts = $c.target -split "\\"
            $name = $parts[-1]
            $path = ($parts[0..($parts.Length-2)] -join "\")
            $psPath = $path.Replace("HKLM\","HKLM:\").Replace("HKCU\","HKCU:\")

            if ($null -ne $c.before) {
                if ($WhatIf) { Write-Log "WHATIF undo: set $psPath\$name=$($c.before)" "DarkYellow" }
                else { Reg-Set $psPath $name $c.before ([Microsoft.Win32.RegistryValueKind]::DWord) }
            }
        }
        elseif ($c.type -eq "service") {
            $svcName = $c.target
            $startType = $c.before.startType
            $startup = "Manual"
            if ($startType -match "Automatic") { $startup = "Automatic" }
            if ($WhatIf) { Write-Log "WHATIF undo: restore service $svcName startup=$startup" "DarkYellow" }
            else { Svc-Enable $svcName $startup }
        }
        elseif ($c.type -eq "netadapter") {
            # best-effort rollback is hard due to driver differences; we only log it.
            Write-Log "Note: netadapter rollback is not fully automated (driver-dependent): $($c.target)" "DarkYellow"
        }
    }

    Write-Log "UNDO complete (best-effort). Reboot recommended." "Green"
}

# =========================
# Status
# =========================
function Status {
    $p = Get-SystemProfile
    Write-Log "Status summary:" "Cyan"
    Write-Log ("OS: {0} | Build {1} | Device={2} | Storage={3}" -f $p.Caption, $p.Build, $p.Device, $p.Storage) "Gray"
    try { Write-Log ("Power: " + (powercfg /getactivescheme)) "Gray" } catch {}
    foreach ($s in @("SysMain","WSearch","DiagTrack","WinDefend","WdNisSvc","wscsvc","SecurityHealthService")) {
        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
        if ($svc) { Write-Log ("{0}: {1} ({2})" -f $s, $svc.Status, $svc.StartType) "Gray" }
    }
    $hags = $null
    try { $hags = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -ErrorAction SilentlyContinue).HwSchMode } catch {}
    if ($null -ne $hags) { Write-Log "HAGS HwSchMode=$hags (2=ON,1=OFF)" "Gray" } else { Write-Log "HAGS Default" "Gray" }
    Write-Log "State file current run: $stateFile" "DarkGray"
}

# =========================
# Menu
# =========================
function Pause-Key { Write-Host ""; Write-Host "Press any key..." -ForegroundColor DarkGray; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }

function Menu {
    while ($true) {
        Clear-Host
        Line
        Write-Host "merybist Optimizer v4 PRO (ASCII only)" -ForegroundColor Cyan
        Line
        Write-Host ""
        Write-Host " 1. Status"
        Write-Host " 2. Auto Optimize (interactive)"
        Write-Host " 3. Registry Tweaks (Basic) apply"
        Write-Host " 4. Registry Tweaks (Basic) restore"
        Write-Host " 5. Gaming: Disable GameDVR"
        Write-Host " 6. Gaming: Enable GameDVR"
        Write-Host " 7. Gaming: Mouse accel OFF"
        Write-Host " 8. Visual: Performance"
        Write-Host " 9. Visual: Default"
        Write-Host " 10. Power plan (smart)"
        Write-Host " 11. Services: SAFE disable"
        Write-Host " 12. Services: AGGRESSIVE disable (dangerous)"
        Write-Host " 13. Services: Restore (best-effort)"
        Write-Host " 14. Security: Disable Defender"
        Write-Host " 15. Security: Enable Defender"
        Write-Host " 16. Security: Disable UAC"
        Write-Host " 17. Security: Enable UAC"
        Write-Host " 18. Optional: NIC tweaks"
        Write-Host " 19. Cleanup (safe)"
        Write-Host " 20. Create restore point"
        Write-Host " 21. UNDO last run (rollback)"
        Write-Host " 0. Exit"
        Write-Host ""

        $x = Read-Host "Select"
        switch ($x) {
            '1'  { Status; Pause-Key }
            '2'  { Auto-Optimize; Pause-Key }
            '3'  { Act-RegistryBasic-Apply; Pause-Key }
            '4'  { Act-RegistryBasic-Restore; Pause-Key }
            '5'  { Act-GameDVR-Off; Pause-Key }
            '6'  { Act-GameDVR-On; Pause-Key }
            '7'  { Act-MouseAccel-Off; Pause-Key }
            '8'  { Act-Visual-Performance; Pause-Key }
            '9'  { Act-Visual-Default; Pause-Key }
            '10' { Act-PowerPlan-Smart; Pause-Key }
            '11' { Act-Services-SafeOff; Pause-Key }
            '12' { Act-Services-AggressiveOff; Pause-Key }
            '13' { Act-Services-Restore; Pause-Key }
            '14' { Act-Defender-Off; Pause-Key }
            '15' { Act-Defender-On; Pause-Key }
            '16' { Act-UAC-Off; Pause-Key }
            '17' { Act-UAC-On; Pause-Key }
            '18' { Act-NIC-Optional; Pause-Key }
            '19' { Act-Cleanup-Safe; Pause-Key }
            '20' { Act-RestorePoint; Pause-Key }
            '21' { Undo-Last; Pause-Key }
            '0'  { Write-Log "Exit." "Cyan"; return }
            default { Write-Host "Invalid selection." -ForegroundColor Yellow; Start-Sleep 1 }
        }
    }
}

# =========================
# Entrypoints
# =========================
if ($Undo) { Undo-Last; exit }
if ($Auto) { Auto-Optimize; exit }

Menu
