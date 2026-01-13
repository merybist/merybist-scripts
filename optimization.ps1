#requires -RunAsAdministrator
<#
merybist Optimizer PRO (Single performance profile, PS 5.1 compatible, ASCII-only)
- Interactive mode: asks Y/N before each change
- Aggressive services OFF (with warning) + Restore services
- Keeps your "Registry Tweaks (Basic)" exactly as you had (same keys/values)
- Rollback state JSON (registry + services). Use UNDO last run.
#>

param(
    [switch]$Auto,
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

function Line {
    param([int]$n = 62, [string]$ch = "=", [string]$color = "Cyan")
    Write-Host ($ch * $n) -ForegroundColor $color
}

Write-Log "=== merybist Optimizer PRO (PS 5.1, ASCII-only) ===" "Cyan"
if ($WhatIf) { Write-Log "WHATIF MODE: changes will be logged but not applied." "Yellow" }

# =========================
# State / Rollback
# =========================
$runId = (Get-Date -Format "yyyyMMdd_HHmmss")
$stateFile = Join-Path $stateDir ("state_$runId.json")

$global:State = [ordered]@{
    runId   = $runId
    created = (Get-Date).ToString("o")
    changes = @()
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
# Prompts
# =========================
function Ask-YesNo {
    param([string]$Question, [ValidateSet("Y","N")] [string]$Default = "Y")
    $suffix = "[Y/n]"
    if ($Default -ne "Y") { $suffix = "[y/N]" }

    while ($true) {
        $ans = Read-Host ("{0} {1}" -f $Question, $suffix)
        if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $Default }
        $ans = $ans.Trim().ToLower()
        if ($ans -eq "y" -or $ans -eq "yes") { return $true }
        if ($ans -eq "n" -or $ans -eq "no")  { return $false }
        Write-Host "Please type Y or N." -ForegroundColor Yellow
    }
}

function Confirm-Risky {
    param([string]$Title,[string]$Details)
    Write-Host ""
    Line 62 "!" "Red"
    Write-Host ("WARNING: {0}" -f $Title) -ForegroundColor Red
    if ($Details) { Write-Host $Details -ForegroundColor Red }
    Line 62 "!" "Red"
    Write-Host ""
    $ans = Read-Host "Type YES to continue"
    if ($ans -eq "YES") { return $true }
    return $false
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
        Write-Log ("Failed to disable ${Name}: {0}" -f $_.Exception.Message) "DarkYellow"
    }
}

function Svc-Enable {
    param([string]$Name,[ValidateSet("Automatic","Manual")] [string]$Startup="Automatic")
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Log "Service $Name not found, skipping." "DarkGray"; return }

    $before = [ordered]@{ status="$($svc.Status)"; startType="$($svc.StartType)" }
    Add-Change "service" $Name $before @{ action="Enable"; startup=$Startup } $null

    if ($WhatIf) { Write-Log ("WHATIF: would enable service {0} ({1})" -f $Name,$Startup) "DarkYellow"; return }

    try {
        Set-Service $Name -StartupType $Startup -ErrorAction SilentlyContinue
        Start-Service $Name -ErrorAction SilentlyContinue
        Write-Log ("Enabled service: {0} ({1})" -f $Name,$Startup) "Green"
    } catch {
        Write-Log ("Failed to enable ${Name}: {0}" -f $_.Exception.Message) "DarkYellow"
    }
}

# =========================
# Detect
# =========================
function Is-Laptop {
    try {
        $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($null -ne $b) { return $true }
    } catch {}
    return $false
}

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
    $p = [ordered]@{ Caption="Unknown"; Build=""; Device="Desktop"; Storage="Unknown" }
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $p.Caption = $os.Caption
        $p.Build   = $os.BuildNumber
    } catch {}
    if (Is-Laptop) { $p.Device = "Laptop" } else { $p.Device = "Desktop" }
    $p.Storage = Get-StorageProfile
    return $p
}

# =========================
# Actions
# =========================
function Act-RestorePoint {
    Write-Log "Creating restore point..." "Yellow"
    if ($WhatIf) { Write-Log "WHATIF: would create restore point" "DarkYellow"; return }
    try {
        Checkpoint-Computer -Description "merybist optimizer restore point" -RestorePointType "Modify_Settings"
        Write-Log "Restore point created." "Green"
    } catch {
        Write-Log ("Restore point failed: {0}" -f $_.Exception.Message) "DarkYellow"
    }
}

# Keep your пункт 6 exactly:
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

function Act-GameDVR-Off {
    Write-Log "Disabling Game DVR and Captures..." "Yellow"
    Reg-Set "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Reg-Set "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Reg-Set "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Reg-Set "HKCU:\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    Write-Log "Game DVR disabled." "Green"
}

function Act-BackgroundApps-Off {
    Write-Log "Disabling background apps..." "Yellow"
    Reg-Set "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    Write-Log "Background apps disabled." "Green"
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

function Act-HAGS-Ask {
    if (-not (Ask-YesNo "Enable HAGS (Hardware GPU Scheduling)? (can help or hurt)" "N")) { return }
    $mode = Read-Host "Type: Default / On / Off"
    if ($mode -ne "Default" -and $mode -ne "On" -and $mode -ne "Off") { $mode = "Default" }

    Write-Log ("HAGS mode: {0}" -f $mode) "Yellow"
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if ($mode -eq "Default") {
        Reg-Remove $path "HwSchMode"
        Write-Log "HAGS set to Default." "Green"
        return
    }
    $val = 1
    if ($mode -eq "On") { $val = 2 }
    if ($mode -eq "Off") { $val = 1 }
    Reg-Set $path "HwSchMode" $val
    Write-Log ("HAGS applied (HwSchMode={0}). Reboot recommended." -f $val) "Green"
}

function Act-PowerPlan-Perf {
    $p = Get-SystemProfile
    if ($p.Device -eq "Laptop") {
        Write-Log "Laptop -> High performance power scheme." "Yellow"
        if ($WhatIf) { Write-Log "WHATIF: would set SCHEME_MIN" "DarkYellow"; return }
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
        if ($newGuid) { powercfg -setactive $newGuid | Out-Null; Write-Log ("Ultimate active: {0}" -f $newGuid) "Green" }
        else { powercfg -setactive SCHEME_MIN | Out-Null; Write-Log "Ultimate not created -> High performance set." "DarkYellow" }
    } catch {
        Write-Log ("Power plan failed: {0}" -f $_.Exception.Message) "DarkYellow"
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
    Write-Log "Defender disable applied. Reboot recommended." "Green"
}

function Act-UAC-Off {
    Write-Log "Disabling UAC..." "Yellow"
    Reg-Set "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 0
    Write-Log "UAC disabled (reboot required)." "Green"
}

# =========================
# Performance Services (disable "unneeded")
# =========================
$SERVICES_PERF_DISABLE = @(
    "DiagTrack","dmwappushservice","SysMain","WSearch",
    "XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc",
    "WMPNetworkSvc","MapsBroker","RemoteRegistry","WerSvc","Fax",
    "WpnService","WwanSvc","workfolderssvc","WebClient","Wecsvc",
    "WFDSConMgrSvc","WPDBusEnum","WiaRpc","ssh-agent"
)

# Aggressive extras (danger zone)
$SERVICES_AGGRESSIVE_EXTRA = @(
    "SecurityHealthService","wscsvc","Spooler","TermService","Themes"
)

function Act-Services-PerformanceOff {
    Write-Log "Disabling performance services set..." "Yellow"
    foreach ($s in $SERVICES_PERF_DISABLE) { Svc-Disable $s }
    Write-Log "Performance services disabled." "Green"
}

function Act-Services-AggressiveOff {
    $ok = Confirm-Risky "AGGRESSIVE SERVICES" "May break Store/Updates/Security Center/Printing/RDP/UI themes."
    if (-not $ok) { Write-Log "Aggressive services canceled." "DarkYellow"; return }

    Write-Log "Disabling aggressive extra services..." "Yellow"
    foreach ($s in $SERVICES_AGGRESSIVE_EXTRA) { Svc-Disable $s }
    Write-Log "Aggressive services disabled." "Green"
}

function Act-Services-Restore {
    Write-Log "Restoring services (best-effort)..." "Yellow"

    # restore to Manual first
    foreach ($s in ($SERVICES_PERF_DISABLE + $SERVICES_AGGRESSIVE_EXTRA | Select-Object -Unique)) {
        Svc-Enable $s "Manual"
    }

    # typical autos
    Svc-Enable "WSearch" "Automatic"
    Svc-Enable "SysMain" "Automatic"
    Svc-Enable "Spooler" "Automatic"
    Svc-Enable "Themes" "Automatic"
    Svc-Enable "wscsvc" "Automatic"
    Svc-Enable "SecurityHealthService" "Automatic"
    Svc-Enable "TermService" "Manual"

    Write-Log "Services restore done (best-effort). Reboot recommended." "Green"
}

# =========================
# Auto optimize (single profile, interactive Y/N each step)
# =========================
function Auto-Optimize {
    Write-Log "AUTO optimize: PERFORMANCE profile (interactive Y/N)" "Cyan"
    $p = Get-SystemProfile
    Write-Log ("Detected: {0} | Build {1} | Device={2} | Storage={3}" -f $p.Caption, $p.Build, $p.Device, $p.Storage) "Gray"

    if (Ask-YesNo "Create restore point before changes?" "Y") { Act-RestorePoint }

    if (Ask-YesNo "Apply Registry Tweaks (Basic)?" "Y") { Act-RegistryBasic-Apply }

    if (Ask-YesNo "Disable GameDVR/Captures?" "Y") { Act-GameDVR-Off }

    if (Ask-YesNo "Disable background apps?" "Y") { Act-BackgroundApps-Off }

    if (Ask-YesNo "Mouse acceleration OFF (FPS)?" "Y") { Act-MouseAccel-Off }

    if (Ask-YesNo "Set Visual Effects to Performance?" "Y") { Act-Visual-Performance }

    if (Ask-YesNo "Set performance power plan?" "Y") { Act-PowerPlan-Perf }

    if (Ask-YesNo "Disable 'unneeded' services for performance?" "Y") { Act-Services-PerformanceOff }

    if (Ask-YesNo "Apply AGGRESSIVE services too? (danger)" "N") { Act-Services-AggressiveOff }

    # HAGS as optional
    Act-HAGS-Ask

    Write-Log "AUTO optimize complete. Reboot recommended." "Green"
    Write-Log ("State saved: {0}" -f $stateFile) "Gray"
}

# =========================
# Undo last run
# =========================
function Undo-Last {
    $f = Get-LastStateFile
    if (-not $f) { Write-Log "No state file found to undo." "DarkYellow"; return }
    Write-Log ("UNDO using: {0}" -f $f.FullName) "Yellow"

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
            $psPath = $path

            if ($null -eq $c.before) {
                if ($WhatIf) { Write-Log ("WHATIF undo: remove {0}\{1}" -f $psPath,$name) "DarkYellow" }
                else { Reg-Remove $psPath $name }
            } else {
                $kind = $c.meta.kind
                $rk = [Microsoft.Win32.RegistryValueKind]::$kind
                if ($WhatIf) { Write-Log ("WHATIF undo: set {0}\{1}={2}" -f $psPath,$name,$c.before) "DarkYellow" }
                else { Reg-Set $psPath $name $c.before $rk }
            }
        }
        elseif ($c.type -eq "registry_remove") {
            $parts = $c.target -split "\\"
            $name = $parts[-1]
            $path = ($parts[0..($parts.Length-2)] -join "\")
            $psPath = $path
            if ($null -ne $c.before) {
                if ($WhatIf) { Write-Log ("WHATIF undo: set {0}\{1}={2}" -f $psPath,$name,$c.before) "DarkYellow" }
                else { Reg-Set $psPath $name $c.before ([Microsoft.Win32.RegistryValueKind]::DWord) }
            }
        }
        elseif ($c.type -eq "service") {
            $svcName = $c.target
            $startType = $c.before.startType
            $startup = "Manual"
            if ($startType -match "Automatic") { $startup = "Automatic" }
            if ($WhatIf) { Write-Log ("WHATIF undo: restore service {0} startup={1}" -f $svcName,$startup) "DarkYellow" }
            else { Svc-Enable $svcName $startup }
        }
    }

    Write-Log "UNDO complete (best-effort). Reboot recommended." "Green"
}

# =========================
# Menu
# =========================
function Pause-Key {
    Write-Host ""
    Write-Host "Press any key..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Status {
    $p = Get-SystemProfile
    Write-Log "Status:" "Cyan"
    Write-Log ("OS: {0} | Build {1} | Device={2} | Storage={3}" -f $p.Caption,$p.Build,$p.Device,$p.Storage) "Gray"
    Write-Log ("State file current run: {0}" -f $stateFile) "DarkGray"
}

function Menu {
    while ($true) {
        Clear-Host
        Line
        Write-Host "merybist Optimizer PRO (single performance profile)" -ForegroundColor Cyan
        Line
        Write-Host ""
        Write-Host " 1. Status"
        Write-Host " 2. AUTO Optimize (asks Y/N per step)"
        Write-Host " 3. Apply Registry Tweaks (Basic)"
        Write-Host " 4. Disable GameDVR/Captures"
        Write-Host " 5. Disable background apps"
        Write-Host " 6. Mouse acceleration OFF"
        Write-Host " 7. Visual effects Performance"
        Write-Host " 8. Set performance power plan"
        Write-Host " 9. Disable services (performance set)"
        Write-Host " 10. Disable services (AGGRESSIVE extra - dangerous)"
        Write-Host " 11. Restore services (best-effort)"
        Write-Host " 12. Disable Defender"
        Write-Host " 13. Disable UAC"
        Write-Host " 14. HAGS (ask mode)"
        Write-Host " 15. Create restore point"
        Write-Host " 16. UNDO last run (rollback)"
        Write-Host " 0. Exit"
        Write-Host ""

        $x = Read-Host "Select"
        switch ($x) {
            '1'  { Status; Pause-Key }
            '2'  { Auto-Optimize; Pause-Key }
            '3'  { Act-RegistryBasic-Apply; Pause-Key }
            '4'  { Act-GameDVR-Off; Pause-Key }
            '5'  { Act-BackgroundApps-Off; Pause-Key }
            '6'  { Act-MouseAccel-Off; Pause-Key }
            '7'  { Act-Visual-Performance; Pause-Key }
            '8'  { Act-PowerPlan-Perf; Pause-Key }
            '9'  { Act-Services-PerformanceOff; Pause-Key }
            '10' { Act-Services-AggressiveOff; Pause-Key }
            '11' { Act-Services-Restore; Pause-Key }
            '12' { Act-Defender-Off; Pause-Key }
            '13' { Act-UAC-Off; Pause-Key }
            '14' { Act-HAGS-Ask; Pause-Key }
            '15' { Act-RestorePoint; Pause-Key }
            '16' { Undo-Last; Pause-Key }
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
