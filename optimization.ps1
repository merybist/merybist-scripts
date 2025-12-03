
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,             
    [switch]$Aggressive,         
    [switch]$Minimal             
)

$root = "C:\merybist-opt"
$log  = Join-Path $root "opt.log"
$regBackupPath = Join-Path $root ("registry-backup-{0}.reg" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Path $root -ErrorAction SilentlyContinue | Out-Null

function Write-Log {
    param([string]$msg, [string]$color = "Gray")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $log -Value $line
}

Write-Log "=== Massive Windows Optimization Script by merybist ===" "Cyan"
Write-Log "DryRun=$($DryRun.IsPresent) Aggressive=$($Aggressive.IsPresent) Minimal=$($Minimal.IsPresent)" "DarkGray"

try {
    Write-Log "Creating system restore point (Pre-Optimization)..." "Yellow"
    Checkpoint-Computer -Description "merybist pre-optimization" -RestorePointType "Modify_Settings"
    Write-Log "Restore point created." "Green"
} catch {
    Write-Log "Restore point failed or unsupported: $($_.Exception.Message)" "DarkYellow"
}

try {
    Write-Log "Backing up key registry areas to: $regBackupPath" "Yellow"
    $content = @()
    $paths = @(
        "HKCU\Software\Microsoft",
        "HKLM\SOFTWARE\Microsoft",
        "HKLM\SOFTWARE\Policies\Microsoft"
    )
    foreach ($p in $paths) { $content += "Windows Registry Editor Version 5.00`r`n; backup pointer: $p`r`n" }
    Set-Content -Path $regBackupPath -Value ($content -join "`r`n")
    Write-Log "Registry backup placeholder created." "Green"
} catch {
    Write-Log "Registry backup failed: $($_.Exception.Message)" "DarkYellow"
}

function Invoke-Action {
    param([scriptblock]$Code, [string]$Msg)
    if ($DryRun) {
        Write-Log "DRY-RUN: $Msg" "DarkGray"
    } else {
        Write-Log $Msg "Gray"
        & $Code
    }
}

Write-Log "Enabling Ultimate Performance power plan if supported..." "Yellow"
Invoke-Action {
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    powercfg -duplicatescheme $guid 2>$null
    powercfg -setactive $guid 2>$null
} "Set Ultimate Performance plan"

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
    "dmwappushservice",   # Device Management WAP
    "RetailDemo"          # Retail Demo
)


$conditionalServices = @(
    "SharedAccess",       # Internet Connection Sharing
    "WSearch"             # Windows Search (disable only if you rarely use search)
)

if (-not $Minimal) { $services += $conditionalServices }

foreach ($svc in $services) {
    $exists = (Get-Service -Name $svc -ErrorAction SilentlyContinue)
    if ($exists) {
        Invoke-Action {
            try {
                Stop-Service $svc -Force -ErrorAction SilentlyContinue
                Set-Service $svc -StartupType Disabled
                Write-Log "Disabled service: $svc" "Green"
            } catch {
                Write-Log "Failed to disable ${svc}: $($_.Exception.Message)" "DarkYellow"
            }
        } "Disable service: $svc"
    } else {
        Write-Log "Service $svc not found, skipping." "DarkGray"
    }
}

Invoke-Action {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
} "Disable background apps"

Invoke-Action {
    New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0
} "Disable Game DVR & Game Bar"

Invoke-Action {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
} "Set visual effects to performance"

Invoke-Action {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Value 0
} "Apply registry performance tweaks"

Invoke-Action {
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableTCPA" -Value 0
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" -Force | Out-Null | Out-Null
} "Apply basic network tweaks"

if ($Aggressive) {
    Invoke-Action {
        netsh int tcp set global autotuninglevel=disabled  | Out-Null
        netsh int tcp set global rss=enabled               | Out-Null
        netsh int tcp set global ecncapability=disabled    | Out-Null
        netsh int tcp set global chimney=disabled          | Out-Null
        netsh int tcp set global dca=disabled              | Out-Null
    } "Aggressive netsh TCP tuning"
}

Invoke-Action {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue

    Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

    Get-ChildItem "C:\Windows\Logs" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    $user = $env:USERPROFILE
    Get-ChildItem "$user\AppData\Local\Google\Chrome\User Data\Default\Cache" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem "$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} "System cleanup (Temp, Update, Prefetch, Logs, browser cache)"

if (-not $Minimal) {
    Invoke-Action {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerFeatures" -Value 1

        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "AicEnabled" -Value 0
    } "Debloat consumer experiences"

    Invoke-Action {
        $tasks = @(
            "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "\Microsoft\Windows\Autochk\Proxy",
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver",
            "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
        )
        foreach ($t in $tasks) {
            schtasks /Change /TN $t /DISABLE 2>$null | Out-Null
        }
    } "Disable selected scheduled tasks"
}

Write-Log "Optimization steps completed." "Cyan"
if ($DryRun) {
    Write-Log "DRY-RUN mode: No changes were applied. Rerun without -DryRun to apply." "Yellow"
} else {
    Write-Log "A reboot is recommended to apply all changes." "Yellow"
}
