# ============================================================
#  WinTools — optimization.ps1  v2.0
#  Windows 10 / 11 — Performance, Gaming, Privacy & UI
#  github.com/merybist/WinTools
#
#  SAFE: every dangerous tweak has a warning + is opt-in
#  GAMING: input lag, MMCSS, VBS, timer, GPU priority
#  RESTORE: auto registry backup before any changes
# ============================================================

#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "WinTools  *  Optimizer  v2.0"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ════════════════════════════════════════════════════════════
#  ANSI
# ════════════════════════════════════════════════════════════
$ESC   = [char]27
$RESET = "$ESC[0m"
$FG = @{
    Black=      "$ESC[30m"; DarkRed=  "$ESC[31m"; DarkGreen="$ESC[32m"
    DarkYellow= "$ESC[33m"; DarkBlue= "$ESC[34m"; DarkMagenta="$ESC[35m"
    DarkCyan=   "$ESC[36m"; Gray=     "$ESC[37m"; DarkGray="$ESC[90m"
    Red=        "$ESC[91m"; Green=    "$ESC[92m"; Yellow=  "$ESC[93m"
    Blue=       "$ESC[94m"; Magenta=  "$ESC[95m"; Cyan=    "$ESC[96m"
    White=      "$ESC[97m"
}
$BG = @{
    Cyan="$ESC[46m"; DarkBlue="$ESC[44m"; DarkGray="$ESC[100m"
    Red= "$ESC[41m"; Green=   "$ESC[42m"
}

# ════════════════════════════════════════════════════════════
#  PRINT HELPERS
# ════════════════════════════════════════════════════════════
function p-ok   { param($m) [Console]::WriteLine("  $($FG.Green)[+]$RESET $m") }
function p-warn { param($m) [Console]::WriteLine("  $($FG.Yellow)[!]$RESET $m") }
function p-skip { param($m) [Console]::WriteLine("  $($FG.DarkGray)[-]$RESET $m") }
function p-step { param($m) [Console]::WriteLine("  $($FG.Cyan)[>]$RESET $m") }
function p-err  { param($m) [Console]::WriteLine("  $($FG.Red)[x]$RESET $m") }
function p-div  {
    $W = [Console]::WindowWidth
    [Console]::WriteLine("  $($FG.DarkGray)$('─' * ($W - 4))$RESET")
}
function p-head { param($m)
    $W = [Console]::WindowWidth
    [Console]::WriteLine("")
    [Console]::WriteLine("  $($BG.DarkBlue)$($FG.White) $($m.PadRight($W - 4)) $RESET")
    [Console]::WriteLine("")
}

# ════════════════════════════════════════════════════════════
#  REGISTRY HELPER
# ════════════════════════════════════════════════════════════
function Set-Reg {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
    } catch {
        p-err "Registry write failed: $Path\$Name  ($_)"
    }
}

function Remove-Reg {
    param([string]$Path, [string]$Name)
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        }
    } catch {}
}

# ════════════════════════════════════════════════════════════
#  RESTORE POINT + REGISTRY BACKUP
# ════════════════════════════════════════════════════════════
function New-BackupPoint {
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"

    # Restore Point
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WinTools_Optimizer_$stamp" `
            -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        p-ok "System Restore Point created: WinTools_Optimizer_$stamp"
    } catch {
        p-warn "Restore Point failed (may already exist within 24h): $_"
    }

    # Registry export to Desktop
    $out = "$env:USERPROFILE\Desktop\WinTools_RegBackup_$stamp.reg"
    p-step "Exporting HKLM registry to Desktop (this may take 30-60s)..."
    $result = Start-Process "reg.exe" -ArgumentList "export HKLM `"$out`" /y" `
        -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\reg_export.log" 2>$null
    if (Test-Path $out) { p-ok "Registry backup: $out" }
    else                { p-warn "Registry export may have failed — check Desktop" }
}

# ════════════════════════════════════════════════════════════
#  DETECT SYSTEM INFO
# ════════════════════════════════════════════════════════════
$script:SysInfo = $null
function Get-SysInfo {
    if ($script:SysInfo) { return $script:SysInfo }
    $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
    $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

    # Check if SSD on system drive
    $diskType = "Unknown"
    try {
        $sysVol   = (Get-WmiObject Win32_Volume -Filter "DriveLetter='$env:SystemDrive'" -ErrorAction SilentlyContinue)
        $diskPart = $sysVol | ForEach-Object { Get-WmiObject -Query "ASSOCIATORS OF {$($_.Path)} WHERE ResultClass = Win32_DiskDriveToDiskPartition" -ErrorAction SilentlyContinue }
        # Simpler method:
        $pdisk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq "0" } | Select-Object -First 1
        if ($pdisk) { $diskType = $pdisk.MediaType }
    } catch {}

    # Check VBS status
    $vbsStatus = "Unknown"
    try {
        $msinfo = & msinfo32.exe /report "$env:TEMP\msinfo_tmp.txt" /categories "SystemSummary" 2>$null
        Start-Sleep 3
        $content = Get-Content "$env:TEMP\msinfo_tmp.txt" -ErrorAction SilentlyContinue
        if ($content -match "Virtualization-based security.*Running") { $vbsStatus = "Running" }
        elseif ($content -match "Virtualization-based security.*Not Enabled") { $vbsStatus = "Disabled" }
        Remove-Item "$env:TEMP\msinfo_tmp.txt" -Force -ErrorAction SilentlyContinue
    } catch {}
    # Faster VBS check via registry
    try {
        $vbsReg = Get-ItemPropertyValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue
        if ($null -ne $vbsReg) { $vbsStatus = if ($vbsReg -eq 1) { "Enabled (reg)" } else { "Disabled (reg)" } }
    } catch {}

    # Check GPU vendor
    $gpuName   = if ($gpu)  { $gpu.Name }  else { "Unknown" }
    $isNvidia  = $gpuName -match "NVIDIA|GeForce"
    $isAMD     = $gpuName -match "AMD|Radeon"

    # Win version
    $winBuild = if ($os) { [int]$os.BuildNumber } else { 0 }
    $isWin11  = $winBuild -ge 22000

    $script:SysInfo = [pscustomobject]@{
        OS        = if ($os) { "$($os.Caption) ($($os.BuildNumber))" } else { "Unknown" }
        CPU       = if ($cpu) { $cpu.Name } else { "Unknown" }
        GPU       = $gpuName
        RAM_GB    = $ram
        DiskType  = $diskType
        VBS       = $vbsStatus
        IsNvidia  = $isNvidia
        IsAMD     = $isAMD
        IsWin11   = $isWin11
        WinBuild  = $winBuild
        RAM_KB    = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)
    }
    return $script:SysInfo
}

# ════════════════════════════════════════════════════════════
#  BANNER
# ════════════════════════════════════════════════════════════
function Show-Banner {
    param([string]$subtitle = "")
    [Console]::CursorVisible = $false
    Clear-Host
    $W = [Console]::WindowWidth
    $L = "  WinTools  *  Optimizer v2.0  "
    $R = "  github.com/merybist/WinTools  "
    $gap = [Math]::Max(1, $W - $L.Length - $R.Length)
    [Console]::WriteLine("$($BG.Cyan)$($FG.Black)$(($L + (' ' * $gap) + $R).PadRight($W))$RESET")
    if ($subtitle) {
        [Console]::WriteLine("  $($FG.DarkGray)$subtitle$RESET")
    }
    [Console]::WriteLine("")
}

# ════════════════════════════════════════════════════════════
#  TUI CHECKLIST ENGINE
#  Renders a navigable checklist of items.
#  Returns array of selected indices.
# ════════════════════════════════════════════════════════════
function Show-Checklist {
    param(
        [string]$Title,
        [string]$Subtitle = "",
        [object[]]$Items,         # each: {Label, Desc, Default, Risk}
        [switch]$SelectAll
    )

    $n       = $Items.Count
    $sel     = New-Object bool[] $n
    $cursor  = 0

    # Default selections
    for ($i = 0; $i -lt $n; $i++) {
        $sel[$i] = if ($SelectAll) { $true } elseif ($Items[$i].PSObject.Properties['Default']) { [bool]$Items[$i].Default } else { $false }
    }

    $W      = [Console]::WindowWidth
    $H      = [Console]::WindowHeight
    $listH  = $H - 9
    if ($listH -lt 3) { $listH = 3 }

    [Console]::CursorVisible = $false

    $RISK_COLOR = @{
        safe   = $FG.Green
        mild   = $FG.Yellow
        strong = $FG.Red
    }

    while ($true) {
        # Build frame
        $half      = [int]($listH / 2)
        $scrollTop = [Math]::Max(0, $cursor - $half)
        $scrollTop = [Math]::Min($scrollTop, [Math]::Max(0, $n - $listH))

        $sb = New-Object System.Text.StringBuilder (($W + 5) * ($H + 4) * 6)
        [void]$sb.Append("$ESC[H")

        # Header
        $L = "  WinTools  *  Optimizer v2.0  "
        $R = "  $Title  "
        $gap = [Math]::Max(1, $W - $L.Length - $R.Length)
        [void]$sb.Append("$($BG.Cyan)$($FG.Black)$(($L + (' ' * $gap) + $R).PadRight($W))$RESET`n")

        if ($Subtitle) {
            [void]$sb.Append("  $($FG.DarkGray)$($Subtitle.PadRight($W-3))$RESET`n")
        } else {
            [void]$sb.Append("`n")
        }

        # Column headers
        $riskW = 8
        $descW = 32
        $nameW = $W - $descW - $riskW - 9
        [void]$sb.Append("  $($FG.DarkGray)$('CHECK'.PadRight(7))$('TWEAK'.PadRight($nameW))$('DESCRIPTION'.PadRight($descW))RISK$RESET`n")
        [void]$sb.Append("  $($FG.DarkGray)$('─' * ($W - 4))$RESET`n")

        # Rows
        for ($row = 0; $row -lt $listH; $row++) {
            $i = $scrollTop + $row
            if ($i -ge $n) { [void]$sb.Append("$ESC[2K`n"); continue }

            $item      = $Items[$i]
            $isCursor  = ($i -eq $cursor)
            $isChecked = $sel[$i]
            $risk      = if ($item.PSObject.Properties['Risk']) { $item.Risk } else { "safe" }
            $riskFg    = if ($RISK_COLOR[$risk]) { $RISK_COLOR[$risk] } else { $FG.Gray }

            $label = $item.Label
            $desc  = if ($item.PSObject.Properties['Desc']) { $item.Desc } else { "" }

            $labelTrunc = if ($label.Length -gt $nameW) { $label.Substring(0, $nameW-1) + "~" } else { $label.PadRight($nameW) }
            $descTrunc  = if ($desc.Length -gt $descW)  { $desc.Substring(0, $descW-1)  + "~" } else { $desc.PadRight($descW)  }

            $boxFg  = if ($isChecked) { $FG.Green  } else { $FG.DarkGray }
            $nameFg = if ($isChecked) { $FG.White  } else { $FG.Gray }
            $box    = if ($isChecked) { " [*] " } else { " [ ] " }

            if ($isCursor) {
                [void]$sb.Append("$($BG.DarkGray)${boxFg}${box}${nameFg}${labelTrunc} $($FG.DarkGray)${descTrunc} ${riskFg}$($risk.PadRight($riskW))$RESET`n")
            } else {
                [void]$sb.Append("${boxFg}${box}${nameFg}${labelTrunc} $($FG.DarkGray)${descTrunc} ${riskFg}$($risk.PadRight($riskW))$RESET`n")
            }
        }

        # Footer
        $selCount = ($sel | Where-Object { $_ }).Count
        [void]$sb.Append("  $($FG.DarkGray)$('─' * ($W - 4))$RESET`n")
        [void]$sb.Append("  $($FG.DarkGray)↑↓=move  Space=toggle  A=all  N=none  Enter=apply ($selCount selected)  Esc=back$RESET`n")

        # Desc popup for current item
        $curDesc = if ($Items[$cursor].PSObject.Properties['Desc']) { $Items[$cursor].Desc } else { "" }
        [void]$sb.Append("  $($FG.Cyan)$($curDesc.PadRight($W - 4))$RESET")

        [Console]::Write($sb.ToString())

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $vk  = $key.VirtualKeyCode
        $ch  = "$($key.Character)".ToUpper()

        switch ($vk) {
            38 { if ($cursor -gt 0)    { $cursor-- } }   # Up
            40 { if ($cursor -lt $n-1) { $cursor++ } }   # Down
            33 { $cursor = [Math]::Max($cursor - 8, 0) }  # PgUp
            34 { $cursor = [Math]::Min($cursor + 8, $n-1) } # PgDn
            36 { $cursor = 0 }      # Home
            35 { $cursor = $n-1 }   # End
            32 { $sel[$cursor] = -not $sel[$cursor] }    # Space
            13 {  # Enter — apply
                [Console]::CursorVisible = $true
                return @(0..($n-1) | Where-Object { $sel[$_] })
            }
            27 {  # Escape — cancel
                [Console]::CursorVisible = $true
                return $null
            }
            default {
                if ($ch -eq 'A') { for ($i=0;$i-lt$n;$i++){$sel[$i]=$true}  }
                if ($ch -eq 'N') { for ($i=0;$i-lt$n;$i++){$sel[$i]=$false} }
            }
        }
    }
}

# ════════════════════════════════════════════════════════════
#  APPLY TWEAKS SCREEN
# ════════════════════════════════════════════════════════════
function Invoke-TweakList {
    param(
        [string]$SectionTitle,
        [object[]]$AllItems,
        [int[]]$SelectedIdx
    )

    Show-Banner $SectionTitle
    p-head "Applying $($SelectedIdx.Count) tweak(s)..."

    $done = 0; $fail = 0

    foreach ($idx in $SelectedIdx) {
        $item = $AllItems[$idx]
        p-step $item.Label
        try {
            & $item.Action
            p-ok "Done"
            $done++
        } catch {
            p-err "Failed: $_"
            $fail++
        }
    }

    p-div
    p-ok "$done applied  |  $fail failed"
    p-warn "Some tweaks require a REBOOT to take effect."
    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.DarkGray)Press any key to return...$RESET")
    [Console]::CursorVisible = $true
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [Console]::CursorVisible = $false
}

# ════════════════════════════════════════════════════════════
#  SECTION 1 — PERFORMANCE
# ════════════════════════════════════════════════════════════
$PERF_TWEAKS = @(
    [pscustomobject]@{
        Label   = "Ultimate Performance Power Plan"
        Desc    = "Adds & activates the hidden Ultimate perf plan"
        Risk    = "safe"
        Default = $true
        Action  = {
            $out  = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
            $guid = [regex]::Match("$out",'[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}').Value
            if ($guid) { powercfg /setactive $guid 2>$null }
            else       { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null }
            p-ok "Power plan set"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Power Throttling"
        Desc    = "Prevents CPU from being throttled in background"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1
        }
    },
    [pscustomobject]@{
        Label   = "CPU Foreground Priority (Win32PriorSep=26)"
        Desc    = "More CPU time to active window / game"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 26
        }
    },
    [pscustomobject]@{
        Label   = "SystemResponsiveness = 10"
        Desc    = "MMCSS gives 90% CPU to foreground (default 80%)"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 10
        }
    },
    [pscustomobject]@{
        Label   = "SvcHostSplitThreshold = RAM size"
        Desc    = "Reduces svchost process fragmentation"
        Risk    = "safe"
        Default = $true
        Action  = {
            $si = Get-SysInfo
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" $si.RAM_KB
        }
    },
    [pscustomobject]@{
        Label   = "Disable SysMain / Superfetch"
        Desc    = "Recommended for SSDs — stops RAM pre-loading"
        Risk    = "mild"
        Default = $false
        Action  = {
            Stop-Service SysMain -Force -ErrorAction SilentlyContinue
            Set-Service  SysMain -StartupType Disabled -ErrorAction SilentlyContinue
            p-warn "Re-enable SysMain if you have an HDD"
        }
    },
    [pscustomobject]@{
        Label   = "Windows Search Indexer → Manual"
        Desc    = "Indexer runs only when needed, saves I/O"
        Risk    = "mild"
        Default = $false
        Action  = {
            Stop-Service WSearch -Force -ErrorAction SilentlyContinue
            Set-Service  WSearch -StartupType Manual -ErrorAction SilentlyContinue
        }
    },
    [pscustomobject]@{
        Label   = "Disable Fast Startup"
        Desc    = "Fixes many resume-from-hibernate bugs"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Hibernate (free pagefile space)"
        Desc    = "Removes hiberfil.sys = saves disk = RAM size"
        Risk    = "mild"
        Default = $false
        Action  = {
            powercfg /hibernate off 2>$null
        }
    },
    [pscustomobject]@{
        Label   = "Faster Shutdown Timeouts"
        Desc    = "Kill service/hung app in 2s instead of 20s"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout"     "2000" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "HungAppTimeout"           "3000" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "AutoEndTasks"             "1"    "String"
        }
    },
    [pscustomobject]@{
        Label   = "Remove Startup Apps Delay"
        Desc    = "Apps start immediately, no 10s boot delay"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Prefetch (SSD only)"
        Desc    = "SSDs don't benefit from prefetch"
        Risk    = "mild"
        Default = $false
        Action  = {
            $si = Get-SysInfo
            if ($si.DiskType -notmatch "SSD|Solid") {
                p-warn "Disk type = $($si.DiskType) — prefetch keeps enabled for HDD"
            } else {
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher"    0
                Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch"    0
            }
        }
    },
    [pscustomobject]@{
        Label   = "Disable VBS / HVCI (Core Isolation)"
        Desc    = "Up to 15% FPS gain — removes security layer!"
        Risk    = "strong"
        Default = $false
        Action  = {
            p-warn "VBS OFF reduces kernel-level malware protection."
            p-warn "Do NOT disable on corporate / shared / sensitive PCs."
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"            "EnableVirtualizationBasedSecurity"              0
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"            "RequirePlatformSecurityFeatures"                0
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"         "EnableVirtualizationBasedSecurity"              0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"         "HypervisorEnforcedCodeIntegrity"                0
            p-warn "REBOOT REQUIRED for VBS to actually disable."
        }
    },
    [pscustomobject]@{
        Label   = "Large System Cache (server-like RAM use)"
        Desc    = "OS uses more RAM for file cache — helps large apps"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Paging Executive"
        Desc    = "Keeps kernel in RAM — slightly faster kernel ops"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1
        }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 2 — GAMING (INPUT LAG, MMCSS, GPU, TIMER)
# ════════════════════════════════════════════════════════════
$GAMING_TWEAKS = @(
    [pscustomobject]@{
        Label   = "Enable Game Mode"
        Desc    = "Windows dedicates resources to game process"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode"       1
            Set-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled"     1
        }
    },
    [pscustomobject]@{
        Label   = "Enable HAGS (Hardware-Accelerated GPU Scheduling)"
        Desc    = "GPU manages its own VRAM — less CPU latency"
        Risk    = "mild"
        Default = $true
        Action  = {
            $si = Get-SysInfo
            if (-not ($si.IsNvidia -or $si.IsAMD)) {
                p-warn "HAGS works best with NVIDIA 10xx+ or AMD RX 5xxx+. Enable anyway."
            }
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
            p-warn "HAGS may cause issues with older GPUs or OBS — revert if unstable"
        }
    },
    [pscustomobject]@{
        Label   = "Enable Windowed Game Optimizations"
        Desc    = "Low-latency in borderless windowed mode (Win11)"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" "SwapEffectUpgradeEnable=1;" "String"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Xbox Game DVR + Game Bar"
        Desc    = "Removes recording overlay + background capture"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_Enabled"              0
            Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_FSEBehaviorMode"       2
            Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_FSEBehavior"           2
            Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_HonorUserFSEBehaviorMode" 1
            Set-Reg "HKCU:\System\GameConfigStore"                       "GameDVR_DXGIHonorFSEWindowsCompatible" 1
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR"                  0
            Set-Reg "HKCU:\Software\Microsoft\GameBar"                   "UseNexusForGameBarEnabled"    0
            Set-Reg "HKCU:\Software\Microsoft\GameBar"                   "ShowStartupPanel"             0
        }
    },
    [pscustomobject]@{
        Label   = "MMCSS Games — GPU Priority=8, CPU Priority=6"
        Desc    = "OS gives GPU+CPU priority to game threads"
        Risk    = "safe"
        Default = $true
        Action  = {
            $base = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
            Set-Reg $base "GPU Priority"          8
            Set-Reg $base "Priority"              6
            Set-Reg $base "Scheduling Category"   "High"   "String"
            Set-Reg $base "SFIO Priority"         "High"   "String"
            Set-Reg $base "Clock Rate"            0x2710
            Set-Reg $base "Affinity"              0
            Set-Reg $base "Background Only"       "False"  "String"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Mouse Acceleration (enhance pointer)"
        Desc    = "Raw 1:1 mouse input — essential for FPS"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseSpeed"  "0" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
            Set-Reg "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String"
            # Also via SPI
            Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint uiAction,uint uiParam,uint[] pvParam,uint fWinIni);
"@ -Name "SPIFix" -Namespace "WinAPI" -ErrorAction SilentlyContinue
            try {
                [WinAPI.SPIFix]::SystemParametersInfo(0x0004, 0, @(0, 0, 0), 0x0003) | Out-Null
            } catch {}
        }
    },
    [pscustomobject]@{
        Label   = "Reduce Mouse Buffer (MouseDataQueueSize=30)"
        Desc    = "Lower input buffer = snappier mouse feel"
        Risk    = "mild"
        Default = $false
        Action  = {
            # Safe sweet-spot: 30 (range: 20-60; default: 100)
            # Too low (<16) can cause skips; 30 is well-tested safe
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"   "MouseDataQueueSize"    30
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"   "KeyboardDataQueueSize" 16
            p-warn "If mouse skips/clicks stop responding: increase to 50-100 or remove key"
        }
    },
    [pscustomobject]@{
        Label   = "GPU Contiguous Memory (DpiMapIommuContiguous)"
        Desc    = "Forces DirectX to use contiguous GPU memory"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DpiMapIommuContiguous" 1
        }
    },
    [pscustomobject]@{
        Label   = "Disable Dynamic Tick (bcdedit)"
        Desc    = "Stable 1ms system timer tick — less stutter"
        Risk    = "mild"
        Default = $false
        Action  = {
            $si = Get-SysInfo
            # On Win11 this can cause desync for some hardware — warn user
            if ($si.IsWin11) {
                p-warn "On Win11 disabledynamictick may cause timer desync on some hardware."
                p-warn "Test: if mouse feels sluggish after reboot, run: bcdedit /deletevalue disabledynamictick"
            }
            $res = & bcdedit /set disabledynamictick yes 2>&1
            p-ok "bcdedit: $res"
        }
    },
    [pscustomobject]@{
        Label   = "TSC Sync Policy = Enhanced"
        Desc    = "Better multi-core timestamp sync"
        Risk    = "mild"
        Default = $false
        Action  = {
            $res = & bcdedit /set tscsyncpolicy enhanced 2>&1
            p-ok "bcdedit: $res"
        }
    },
    [pscustomobject]@{
        Label   = "GlobalTimerResolutionRequests (Win11 only)"
        Desc    = "Old-style 0.5ms timer in Win11 kernel"
        Risk    = "mild"
        Default = $false
        Action  = {
            $si = Get-SysInfo
            if (-not $si.IsWin11) {
                p-skip "Win11 only — skipping (Win10 uses different timer path)"
                return
            }
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 1
            p-warn "Reboot required for timer change to take effect"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Hypervisor (if no VMs used)"
        Desc    = "Frees CPU from hypervisor overhead; ~2-5% boost"
        Risk    = "strong"
        Default = $false
        Action  = {
            p-warn "Only disable hypervisor if you do NOT use Hyper-V, WSL2, Docker, or Android Subsystem."
            p-warn "Re-enable: bcdedit /set hypervisorlaunchtype auto"
            & bcdedit /set hypervisorlaunchtype off 2>&1 | ForEach-Object { p-step $_ }
        }
    },
    [pscustomobject]@{
        Label   = "NVIDIA — Power Mode: Prefer Maximum Performance"
        Desc    = "Keeps GPU clocks at max, no throttle"
        Risk    = "mild"
        Default = $false
        Action  = {
            $si = Get-SysInfo
            if (-not $si.IsNvidia) { p-skip "NVIDIA GPU not detected — skipping"; return }
            # NVIDIA driver registry path — works with most driver versions
            $nvPaths = @(
                "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak",
                "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            )
            foreach ($p in $nvPaths) {
                Set-Reg $p "PowerMizerEnable"       1
                Set-Reg $p "PowerMizerLevel"        1
                Set-Reg $p "PowerMizerLevelAC"      1
                Set-Reg $p "PerfLevelSrc"           0x2222
            }
            p-warn "This increases GPU power draw. Check temps after gaming sessions."
        }
    },
    [pscustomobject]@{
        Label   = "NVIDIA Shader Cache = 10GB"
        Desc    = "Avoids in-game shader compilation stutters"
        Risk    = "safe"
        Default = $false
        Action  = {
            $si = Get-SysInfo
            if (-not $si.IsNvidia) { p-skip "NVIDIA GPU not detected — skipping"; return }
            # Set via NV Control Panel registry
            $nvBase = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm"
            Set-Reg $nvBase "EnableCacheForPowerOffTasks" 1
            p-warn "For full effect: also set in NVIDIA Control Panel > Manage 3D Settings > Shader Cache Size = 10GB"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Fullscreen Optimizations globally"
        Desc    = "Some games run better without FSO overlay"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
            Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
            # Also via AppCompatFlags
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" "DisabledMaximizedWindowedMode" "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" "String"
            p-warn "Some games need FSO for proper borderless windowed — revert per-game if needed"
        }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 3 — PRIVACY
# ════════════════════════════════════════════════════════════
$PRIVACY_TWEAKS = @(
    [pscustomobject]@{
        Label   = "Disable Telemetry (AllowTelemetry=0)"
        Desc    = "Stops all diagnostic data to Microsoft"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                "AllowTelemetry" 0
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                "DoNotShowFeedbackNotifications" 1
            # Disable DiagTrack service
            Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
            Set-Service  DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
        }
    },
    [pscustomobject]@{
        Label   = "Disable Advertising ID"
        Desc    = "No targeted ads based on app usage"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "DisabledByGroupPolicy" 1
        }
    },
    [pscustomobject]@{
        Label   = "Disable Cortana"
        Desc    = "Removes Cortana search integration"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana"          0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortanaAboveLock" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch"      1
        }
    },
    [pscustomobject]@{
        Label   = "Disable Activity History / Timeline"
        Desc    = "No activity log sent to Microsoft"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"    0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"  0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Location Tracking"
        Desc    = "System-level location off for all apps"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1
        }
    },
    [pscustomobject]@{
        Label   = "Disable Feedback / SIUF Prompts"
        Desc    = "No 'How do you like Windows?' popups"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
            Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "PeriodInNanoSeconds"  0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Tailored Experiences"
        Desc    = "No personalized tips from diagnostic data"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable App Launch Tracking"
        Desc    = "Start menu doesn't track which apps you use"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Windows Error Reporting"
        Desc    = "No crash reports sent to Microsoft"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
            Stop-Service WerSvc -Force -ErrorAction SilentlyContinue
            Set-Service  WerSvc -StartupType Disabled -ErrorAction SilentlyContinue
        }
    },
    [pscustomobject]@{
        Label   = "Disable Remote Assistance"
        Desc    = "Blocks remote help feature (security)"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" "fAllowToGetHelp" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Bing in Start Menu Search"
        Desc    = "Local-only search, no web results"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent"    0
        }
    },
    [pscustomobject]@{
        Label   = "Block Camera Access (all apps)"
        Desc    = "Denies camera permission system-wide"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" "Value" "Deny" "String"
            p-warn "Re-enable per app in Settings > Privacy > Camera"
        }
    },
    [pscustomobject]@{
        Label   = "Block Microphone Access (all apps)"
        Desc    = "Denies mic permission system-wide"
        Risk    = "mild"
        Default = $false
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny" "String"
            p-warn "Re-enable per app in Settings > Privacy > Microphone"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Windows Copilot (Win11 24H2+)"
        Desc    = "Removes AI Copilot sidebar"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"       "TurnOffWindowsCopilot" 1
            Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"       "TurnOffWindowsCopilot" 1
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Recall (Win11 24H2)"
        Desc    = "Stops AI screenshot history feature"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
            Set-Reg "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
        }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 4 — SERVICES
# ════════════════════════════════════════════════════════════
$SERVICES_TWEAKS = @(
    # Format: {Label, SvcName, Desc, StartType="Disabled"|"Manual", Risk}
    [pscustomobject]@{
        Label   = "DiagTrack — Telemetry"
        Desc    = "Sends usage & diagnostic data to MS"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service DiagTrack -Force -EA SilentlyContinue; Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "dmwappushservice — WAP Push"
        Desc    = "Routes device management WAP messages"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service dmwappushservice -Force -EA SilentlyContinue; Set-Service dmwappushservice -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "MapsBroker — Downloaded Maps"
        Desc    = "Auto-updates offline maps"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service MapsBroker -Force -EA SilentlyContinue; Set-Service MapsBroker -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "RetailDemo — Retail Demo Mode"
        Desc    = "Only needed in retail store displays"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service RetailDemo -Force -EA SilentlyContinue; Set-Service RetailDemo -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "RemoteRegistry — Remote Registry"
        Desc    = "Allows remote users to read/write registry"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service RemoteRegistry -Force -EA SilentlyContinue; Set-Service RemoteRegistry -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "TrkWks — Distributed Link Tracking"
        Desc    = "Tracks NTFS link changes over network"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service TrkWks -Force -EA SilentlyContinue; Set-Service TrkWks -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "XblAuthManager — Xbox Live Auth"
        Desc    = "Xbox Live authentication manager"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service XblAuthManager -Force -EA SilentlyContinue; Set-Service XblAuthManager -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "XblGameSave — Xbox Live Game Save"
        Desc    = "Syncs game saves with Xbox Live"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service XblGameSave -Force -EA SilentlyContinue; Set-Service XblGameSave -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "XboxNetApiSvc — Xbox Networking"
        Desc    = "Xbox networking service"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service XboxNetApiSvc -Force -EA SilentlyContinue; Set-Service XboxNetApiSvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "XboxGipSvc — Xbox Accessory Management"
        Desc    = "Xbox controller firmware updates"
        Risk    = "mild"
        Default = $false
        Action  = { Stop-Service XboxGipSvc -Force -EA SilentlyContinue; Set-Service XboxGipSvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "wisvc — Windows Insider Service"
        Desc    = "Needed only for Insider Preview builds"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service wisvc -Force -EA SilentlyContinue; Set-Service wisvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "WMPNetworkSvc — WMP Network Sharing"
        Desc    = "Media Player network sharing (DLNA)"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service WMPNetworkSvc -Force -EA SilentlyContinue; Set-Service WMPNetworkSvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "Fax — Fax Service"
        Desc    = "No one uses fax anymore"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service Fax -Force -EA SilentlyContinue; Set-Service Fax -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "lfsvc — Geolocation Service"
        Desc    = "GPS/location API for apps"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service lfsvc -Force -EA SilentlyContinue; Set-Service lfsvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "WSearch → Manual (keep available)"
        Desc    = "Indexer starts only when search is used"
        Risk    = "mild"
        Default = $false
        Action  = { Stop-Service WSearch -Force -EA SilentlyContinue; Set-Service WSearch -StartupType Manual -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "Spooler → Manual (if no printer)"
        Desc    = "Print spooler — set manual if no printer"
        Risk    = "mild"
        Default = $false
        Action  = {
            p-warn "If you print (including PDF printer) keep this enabled!"
            Set-Service Spooler -StartupType Manual -EA SilentlyContinue
        }
    },
    [pscustomobject]@{
        Label   = "SysMain (Superfetch) — Disable"
        Desc    = "RAM pre-loading — useless on SSD"
        Risk    = "mild"
        Default = $false
        Action  = { Stop-Service SysMain -Force -EA SilentlyContinue; Set-Service SysMain -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "WbioSrvc — Windows Biometric"
        Desc    = "Fingerprint / Windows Hello service"
        Risk    = "mild"
        Default = $false
        Action  = {
            p-warn "Disables fingerprint & Windows Hello face unlock!"
            Stop-Service WbioSrvc -Force -EA SilentlyContinue
            Set-Service  WbioSrvc -StartupType Disabled -EA SilentlyContinue
        }
    },
    [pscustomobject]@{
        Label   = "PcaSvc — Program Compat Assistant"
        Desc    = "Compatibility warnings for old apps"
        Risk    = "mild"
        Default = $false
        Action  = { Stop-Service PcaSvc -Force -EA SilentlyContinue; Set-Service PcaSvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "WerSvc — Windows Error Reporting"
        Desc    = "Crash report collector"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service WerSvc -Force -EA SilentlyContinue; Set-Service WerSvc -StartupType Disabled -EA SilentlyContinue }
    },
    [pscustomobject]@{
        Label   = "DoSvc — Delivery Optimization"
        Desc    = "P2P update sharing with other PCs"
        Risk    = "safe"
        Default = $true
        Action  = { Stop-Service DoSvc -Force -EA SilentlyContinue; Set-Service DoSvc -StartupType Disabled -EA SilentlyContinue }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 5 — NETWORK
# ════════════════════════════════════════════════════════════
$NETWORK_TWEAKS = @(
    [pscustomobject]@{
        Label   = "Disable Network Throttling (MMCSS)"
        Desc    = "Removes MS media-stream bandwidth cap"
        Risk    = "mild"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
            p-warn "If DPC latency or audio crackles appear, revert to default (10)"
        }
    },
    [pscustomobject]@{
        Label   = "Increase IRPStackSize to 32"
        Desc    = "More network stack buffers = better throughput"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 32
        }
    },
    [pscustomobject]@{
        Label   = "TCP Nagle Off + ACK Frequency=1"
        Desc    = "Lower latency for small TCP packets (gaming)"
        Risk    = "mild"
        Default = $true
        Action  = {
            $tcpGlobal = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Set-Reg $tcpGlobal "TCPNoDelay"      1
            Set-Reg $tcpGlobal "TcpAckFrequency" 1
            Set-Reg $tcpGlobal "Tcp1323Opts"     1
            Set-Reg $tcpGlobal "DefaultTTL"      64
            # Per-interface
            $ifPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            Get-ChildItem $ifPath -ErrorAction SilentlyContinue | ForEach-Object {
                Set-Reg $_.PSPath "TcpAckFrequency" 1
                Set-Reg $_.PSPath "TCPNoDelay"      1
            }
            p-warn "Nagle off increases CPU usage slightly — ideal for gaming/low-latency apps"
        }
    },
    [pscustomobject]@{
        Label   = "TCP Auto-Tuning = Normal"
        Desc    = "Adaptive TCP window sizing"
        Risk    = "safe"
        Default = $true
        Action  = {
            netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
            netsh int tcp set global ecncapability=enabled  2>$null | Out-Null
            netsh int tcp set global timestamps=disabled    2>$null | Out-Null
            p-ok "TCP auto-tuning configured"
        }
    },
    [pscustomobject]@{
        Label   = "Disable QoS Bandwidth Reservation"
        Desc    = "Removes 20% bandwidth reserve for QoS"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Delivery Optimization P2P"
        Desc    = "Stops uploading Windows updates to other PCs"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
        }
    },
    [pscustomobject]@{
        Label   = "DNS → Cloudflare (1.1.1.1 / 1.0.0.1)"
        Desc    = "Fastest DNS globally + privacy"
        Risk    = "mild"
        Default = $false
        Action  = {
            Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
                p-ok "  Adapter: $($_.Name)"
            }
            ipconfig /flushdns | Out-Null
        }
    },
    [pscustomobject]@{
        Label   = "DNS → Google (8.8.8.8 / 8.8.4.4)"
        Desc    = "Reliable fallback DNS"
        Risk    = "mild"
        Default = $false
        Action  = {
            Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
                Set-DnsClientServerAddress -InterfaceIndex $_.IfIndex -ServerAddresses @("8.8.8.8","8.8.4.4") -EA SilentlyContinue
                p-ok "  Adapter: $($_.Name)"
            }
            ipconfig /flushdns | Out-Null
        }
    },
    [pscustomobject]@{
        Label   = "Disable NetBIOS over TCP/IP"
        Desc    = "Removes legacy LAN protocol (small security gain)"
        Risk    = "mild"
        Default = $false
        Action  = {
            Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -EA SilentlyContinue | ForEach-Object {
                $_.SetTcpipNetbios(2) | Out-Null
            }
        }
    },
    [pscustomobject]@{
        Label   = "Flush DNS Cache"
        Desc    = "Clears stale DNS entries immediately"
        Risk    = "safe"
        Default = $true
        Action  = {
            ipconfig /flushdns | Out-Null
            p-ok "DNS cache flushed"
        }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 6 — EXPLORER & UI
# ════════════════════════════════════════════════════════════
$UI_TWEAKS = @(
    [pscustomobject]@{
        Label   = "Show File Extensions"
        Desc    = "Shows .exe .dll .ps1 etc in Explorer"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
        }
    },
    [pscustomobject]@{
        Label   = "Show Hidden Files"
        Desc    = "Makes hidden files/folders visible"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1
        }
    },
    [pscustomobject]@{
        Label   = "Show Full Path in Title Bar"
        Desc    = "C:\Users\... instead of just folder name"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1
        }
    },
    [pscustomobject]@{
        Label   = "Menu Show Delay → 50ms (from 400ms)"
        Desc    = "Context menus appear almost instantly"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "50" "String"
        }
    },
    [pscustomobject]@{
        Label   = "Enable Dark Mode"
        Desc    = "System + Apps dark theme"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme"    0
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
        }
    },
    [pscustomobject]@{
        Label   = "Disable Transparency Effects"
        Desc    = "Solid taskbar/Start menu = less GPU usage"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
        }
    },
    [pscustomobject]@{
        Label   = "Reduce Visual Effects (performance mode)"
        Desc    = "Disables animations, shadows, fades"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
            Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
            # Disable specific effects
            Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows"   "1" "String"
            Set-Reg "HKCU:\Control Panel\Desktop" "FontSmoothing"     "2" "String"
        }
    },
    [pscustomobject]@{
        Label   = "Disable Lock Screen Tips & Ads"
        Desc    = "No 'Did you know' on lock screen"
        Risk    = "safe"
        Default = $true
        Action  = {
            $cdm = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            @(
                "RotatingLockScreenOverlayEnabled","SubscribedContent-338387Enabled",
                "SubscribedContent-338388Enabled","SubscribedContent-353698Enabled",
                "SubscribedContent-310093Enabled","SoftLandingEnabled",
                "SystemPaneSuggestionsEnabled","PreInstalledAppsEnabled",
                "OemPreInstalledAppsEnabled","SilentInstalledAppsEnabled",
                "SubscribedContent-338389Enabled","SubscribedContent-353694Enabled"
            ) | ForEach-Object { Set-Reg $cdm $_ 0 }
        }
    },
    [pscustomobject]@{
        Label   = "Hide News & Interests from Taskbar"
        Desc    = "Removes weather/news widget"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2
        }
    },
    [pscustomobject]@{
        Label   = "Align Taskbar Left (Win11)"
        Desc    = "Moves Start button to the left"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0
        }
    },
    [pscustomobject]@{
        Label   = "Classic Right-Click Menu (Win11)"
        Desc    = "Restores full context menu (no Show More)"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(Default)" "" "String"
            p-warn "Restart Explorer or reboot to see effect"
        }
    },
    [pscustomobject]@{
        Label   = "Enable End Task via Right-Click"
        Desc    = "Right-click taskbar button to kill app"
        Risk    = "safe"
        Default = $true
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1
        }
    },
    [pscustomobject]@{
        Label   = "Hide OneDrive in Explorer Sidebar"
        Desc    = "Removes OneDrive shortcut from nav pane"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"            "System.IsPinnedToNameSpaceTree" 0
            Set-Reg "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
        }
    },
    [pscustomobject]@{
        Label   = "Show Seconds in Clock"
        Desc    = "Taskbar clock shows HH:MM:SS"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSecondsInSystemClock" 1
        }
    },
    [pscustomobject]@{
        Label   = "Disable Low Disk Space Warnings"
        Desc    = "No persistent 'low disk space' nag"
        Risk    = "safe"
        Default = $false
        Action  = {
            Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoLowDiskSpaceChecks" 1
        }
    },
    [pscustomobject]@{
        Label   = "Restart Explorer Now"
        Desc    = "Applies UI changes without reboot"
        Risk    = "safe"
        Default = $true
        Action  = {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 800
            Start-Process explorer
            p-ok "Explorer restarted"
        }
    }
)

# ════════════════════════════════════════════════════════════
#  SECTION 7 — JUNK CLEANER
# ════════════════════════════════════════════════════════════
$JUNK_TWEAKS = @(
    [pscustomobject]@{
        Label   = "User Temp Folder (%TEMP%)"
        Desc    = "App temp files in your profile"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path $env:TEMP
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "System Temp (Windows\Temp)"
        Desc    = "System-wide temporary files"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path "$env:SystemRoot\Temp"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Prefetch Cache"
        Desc    = "Windows startup prefetch files"
        Risk    = "mild"
        Default = $false
        Action  = {
            $freed = Clean-Path "$env:SystemRoot\Prefetch"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "IE / Edge Cache"
        Desc    = "Internet Explorer / legacy Edge cache"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "LocalAppData Temp"
        Desc    = "App-specific temp in user local data"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path "$env:LOCALAPPDATA\Temp"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Windows Update Download Cache"
        Desc    = "Downloaded but installed update files"
        Risk    = "safe"
        Default = $true
        Action  = {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            $freed = Clean-Path "$env:SystemRoot\SoftwareDistribution\Download"
            Start-Service wuauserv -ErrorAction SilentlyContinue
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Error Reports (WER)"
        Desc    = "Crash dump and error report files"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path "$env:LOCALAPPDATA\Microsoft\Windows\WER"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Thumbnail Cache"
        Desc    = "Explorer thumbnail database"
        Risk    = "safe"
        Default = $true
        Action  = {
            # Kill explorer first, clean, restart
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 400
            $freed = Clean-Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Pattern "thumbcache_*.db"
            Start-Process explorer
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Delivery Optimization Cache"
        Desc    = "P2P Windows Update pieces"
        Risk    = "safe"
        Default = $true
        Action  = {
            $freed = Clean-Path "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"
            p-ok "Freed ~$freed MB"
        }
    },
    [pscustomobject]@{
        Label   = "Empty Recycle Bin"
        Desc    = "Permanently deletes all recycled files"
        Risk    = "mild"
        Default = $false
        Action  = {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            p-ok "Recycle Bin emptied"
        }
    },
    [pscustomobject]@{
        Label   = "Windows Disk Cleanup (cleanmgr)"
        Desc    = "Runs built-in disk cleanup silently"
        Risk    = "safe"
        Default = $false
        Action  = {
            $sageSet = 64
            $regBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            @("Temporary Files","Downloaded Program Files","Internet Cache Files","Thumbnails",
              "Old ChkDsk Files","Recycle Bin","Setup Log Files","System error memory dump files",
              "Windows Error Reporting Archive Files","Windows Error Reporting Queue Files") | ForEach-Object {
                Set-Reg "$regBase\$_" "StateFlags$sageSet" 2
            }
            Start-Process cleanmgr.exe -ArgumentList "/sagerun:$sageSet" -Wait -ErrorAction SilentlyContinue
            p-ok "Disk Cleanup complete"
        }
    }
)

function Clean-Path {
    param([string]$Path, [string]$Pattern = "*")
    if (-not (Test-Path $Path)) { return 0 }
    $before = (Get-ChildItem $Path -Recurse -Force -Filter $Pattern -ErrorAction SilentlyContinue |
               Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $Path -Recurse -Force -Filter $Pattern -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after  = (Get-ChildItem $Path -Recurse -Force -Filter $Pattern -ErrorAction SilentlyContinue |
               Measure-Object -Property Length -Sum).Sum
    $beforeValue = if ($null -ne $before) { [int64]$before } else { 0 }
    $afterValue  = if ($null -ne $after)  { [int64]$after }  else { 0 }
    return [Math]::Round(($beforeValue - $afterValue) / 1MB, 1)
}

# ════════════════════════════════════════════════════════════
#  SYSINFO DISPLAY
# ════════════════════════════════════════════════════════════
function Show-SysInfo {
    Show-Banner "System Info"
    p-head "Detecting hardware & Windows configuration..."

    $si = Get-SysInfo

    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.DarkGray)OS       $RESET $($FG.White)$($si.OS)$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)CPU      $RESET $($FG.White)$($si.CPU)$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)GPU      $RESET $($FG.White)$($si.GPU)$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)RAM      $RESET $($FG.White)$($si.RAM_GB) GB$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)Disk     $RESET $($FG.White)$($si.DiskType)$RESET")

    $vbsColor = if ($si.VBS -match "Running|Enabled") { $FG.Red } else { $FG.Green }
    [Console]::WriteLine("  $($FG.DarkGray)VBS/HVCI $RESET ${vbsColor}$($si.VBS)$RESET  $($FG.DarkGray)(gaming: prefer Disabled)$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)Win11    $RESET $($FG.White)$($si.IsWin11) (build $($si.WinBuild))$RESET")
    [Console]::WriteLine("  $($FG.DarkGray)NVIDIA   $RESET $($FG.White)$($si.IsNvidia)$RESET")
    [Console]::WriteLine("")
    p-div

    # Quick tips based on detected config
    if ($si.VBS -match "Running|Enabled") {
        p-warn "VBS/HVCI is ACTIVE — up to 15% FPS loss. Consider Gaming > Disable VBS/HVCI."
    }
    if ($si.DiskType -match "HDD|Unspecified|Unknown") {
        p-warn "Disk = $($si.DiskType) — keep SysMain/Superfetch enabled for HDD performance."
    }
    if ($si.IsNvidia) {
        p-ok "NVIDIA GPU detected — NVIDIA-specific tweaks available in Gaming section."
    }

    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.DarkGray)Press any key to return...$RESET")
    [Console]::CursorVisible = $true
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [Console]::CursorVisible = $false
}

# ════════════════════════════════════════════════════════════
#  ONE-CLICK FULL AUTO
# ════════════════════════════════════════════════════════════
function Run-FullAuto {
    Show-Banner "Full Auto Optimization"

    [Console]::WriteLine("  $($FG.Yellow)This applies ALL default-checked tweaks from every category.$RESET")
    [Console]::WriteLine("  $($FG.Yellow)A restore point will be created first.$RESET")
    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.White)Press $($FG.Green)Y$RESET$($FG.White) to proceed or any other key to cancel...$RESET")
    [Console]::CursorVisible = $true
    $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [Console]::CursorVisible = $false

    if ("$($k.Character)".ToUpper() -ne "Y") {
        p-skip "Auto mode cancelled"
        Start-Sleep 1
        return
    }

    Clear-Host
    Show-Banner "Full Auto — Running"
    New-BackupPoint

    $allSections = @(
        @{ Name="Performance"; Items=$PERF_TWEAKS    }
        @{ Name="Gaming";      Items=$GAMING_TWEAKS  }
        @{ Name="Privacy";     Items=$PRIVACY_TWEAKS }
        @{ Name="Services";    Items=$SERVICES_TWEAKS}
        @{ Name="Network";     Items=$NETWORK_TWEAKS }
        @{ Name="UI";          Items=$UI_TWEAKS      }
    )

    $totalDone = 0; $totalFail = 0

    foreach ($sec in $allSections) {
        p-head $sec.Name
        $defaults = @(0..($sec.Items.Count-1) | Where-Object {
            $sec.Items[$_].PSObject.Properties['Default'] -and [bool]$sec.Items[$_].Default
        })
        foreach ($idx in $defaults) {
            $item = $sec.Items[$idx]
            p-step $item.Label
            try {
                & $item.Action
                $totalDone++
            } catch {
                p-err "  $_"
                $totalFail++
            }
        }
    }

    [Console]::WriteLine("")
    p-div
    p-ok "Auto-optimization complete: $totalDone tweaks applied, $totalFail failed."
    p-warn "REBOOT recommended for all changes to take effect."
    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.DarkGray)Press any key to return...$RESET")
    [Console]::CursorVisible = $true
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [Console]::CursorVisible = $false
}

# ════════════════════════════════════════════════════════════
#  MAIN MENU
# ════════════════════════════════════════════════════════════
function Show-Menu {
    Show-Banner "Main Menu"
    $W = [Console]::WindowWidth

    $si = Get-SysInfo

    # System bar
    $vbsStatus = if ($si.VBS -match "Running|Enabled") { "$($FG.Red)VBS:ON (costs FPS)$RESET" } else { "$($FG.Green)VBS:Off$RESET" }
    $gpuStr    = $si.GPU
    if ($gpuStr.Length -gt 30) { $gpuStr = $gpuStr.Substring(0,28) + ".." }
    [Console]::WriteLine("  $($FG.DarkGray)$($si.OS.PadRight(40)) $($gpuStr.PadRight(32)) $si.RAM_GB GB  $vbsStatus$RESET")
    [Console]::WriteLine("")
    p-div
    [Console]::WriteLine("")

    # Menu items
    $items = @(
        @{ Key="A"; Color=$FG.Green;   Label="AUTO          Apply all defaults silently (safe to run on fresh install)" }
        @{ Key="";  Color=$FG.DarkGray;Label="" }
        @{ Key="1"; Color=$FG.Cyan;    Label="Performance   Power plan, SvcHost, CPU priority, VBS, memory tweaks" }
        @{ Key="2"; Color=$FG.Magenta; Label="Gaming        Input lag, MMCSS, HAGS, mouse, timer, GPU priority" }
        @{ Key="3"; Color=$FG.Blue;    Label="Privacy       Telemetry, ads, Cortana, location, Copilot, Recall" }
        @{ Key="4"; Color=$FG.Yellow;  Label="Services      Disable unnecessary Windows services one by one" }
        @{ Key="5"; Color=$FG.DarkCyan;Label="Network       DNS, TCP, QoS, Nagle, delivery optimization" }
        @{ Key="6"; Color=$FG.White;   Label="Explorer/UI   Dark mode, menus, taskbar, file extensions, visual fx" }
        @{ Key="7"; Color=$FG.Red;     Label="Junk Cleaner  Temp files, update cache, thumbnails, Recycle Bin" }
        @{ Key="";  Color=$FG.DarkGray;Label="" }
        @{ Key="I"; Color=$FG.DarkGray;Label="System Info   Show hardware detection + quick recommendations" }
        @{ Key="B"; Color=$FG.DarkGray;Label="Backup Only   Create restore point + export registry" }
        @{ Key="Q"; Color=$FG.DarkGray;Label="Exit" }
    )

    foreach ($item in $items) {
        if ($item.Key -eq "") {
            [Console]::WriteLine("")
        } elseif ($item.Key -eq "A") {
            [Console]::WriteLine("  $($BG.DarkBlue)$($item.Color) [$($item.Key)] $($item.Label.PadRight($W - 8)) $RESET")
        } else {
            [Console]::WriteLine("  $($item.Color)[$($item.Key)]$RESET  $($FG.Gray)$($item.Label)$RESET")
        }
    }
    [Console]::WriteLine("")
    [Console]::WriteLine("  $($FG.DarkGray)RISK LEGEND:  $($FG.Green)[safe] = no side effects   $($FG.Yellow)[mild] = test after reboot   $($FG.Red)[strong] = security tradeoff$RESET")
    [Console]::WriteLine("")
    [Console]::CursorVisible = $true
}

# ════════════════════════════════════════════════════════════
#  SECTION RUNNER — shows checklist then runs selected
# ════════════════════════════════════════════════════════════
function Run-Section {
    param([string]$Title, [string]$Subtitle, [object[]]$Items)
    $selected = Show-Checklist -Title $Title -Subtitle $Subtitle -Items $Items
    if ($null -eq $selected -or $selected.Count -eq 0) { return }
    Clear-Host
    Invoke-TweakList -SectionTitle $Title -AllItems $Items -SelectedIdx $selected
}

# ════════════════════════════════════════════════════════════
#  ENTRY POINT
# ════════════════════════════════════════════════════════════
while ($true) {
    Show-Menu
    $choice = (Read-Host "  Choice").Trim().ToUpper()

    switch ($choice) {
        "A" { Run-FullAuto }
        "1" { Run-Section "Performance"  "Power, CPU, memory, VBS — affects system stability"    $PERF_TWEAKS    }
        "2" { Run-Section "Gaming"       "Input lag, MMCSS, HAGS, GPU priority, timer, mouse"    $GAMING_TWEAKS  }
        "3" { Run-Section "Privacy"      "Telemetry, ads, Cortana, Copilot, Recall"               $PRIVACY_TWEAKS }
        "4" { Run-Section "Services"     "Disable Windows services — check each carefully"        $SERVICES_TWEAKS}
        "5" { Run-Section "Network"      "TCP/IP, DNS, QoS, bandwidth tweaks"                    $NETWORK_TWEAKS }
        "6" { Run-Section "Explorer/UI"  "Taskbar, themes, menus, visual effects"                 $UI_TWEAKS      }
        "7" { Run-Section "Junk Cleaner" "Temp folders, update cache, thumbnails, Recycle Bin"    $JUNK_TWEAKS    }
        "I" { Show-SysInfo }
        "B" { Show-Banner "Backup"; New-BackupPoint; [Console]::WriteLine(""); p-div; [Console]::WriteLine("  $($FG.DarkGray)Press any key...$RESET"); $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }
        "Q" { Clear-Host; [Console]::WriteLine("`n  $($FG.Cyan)Bye! Reboot if you applied tweaks.$RESET`n"); [Console]::CursorVisible = $true; exit }
        default { [Console]::WriteLine("  $($FG.Red)Invalid choice.$RESET"); Start-Sleep -Milliseconds 600 }
    }
}
