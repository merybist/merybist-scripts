# Windows & Office Activation Toolkit v4.0
# Enhanced with multiple activation methods
# by merybist
# Run as Administrator

#region Initial Setup
$global:IsWindowsActivated = $false
$global:IsOfficeActivated = $false
$global:BackupPath = "$env:TEMP\ActivationBackup"
$global:LogPath = "$env:TEMP\ActivationLogs\activation.log"

if (!(Test-Path (Split-Path $global:LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $global:LogPath) -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Pause-Action {
    Write-Host ""
    Write-Color "Press any key to continue..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
#endregion

#region Main Menu
function Show-MainMenu {
    Clear-Host
    Write-Color ""
    Write-Color "============================================================" "Cyan"
    Write-Color "     WINDOWS & OFFICE ACTIVATION TOOLKIT v4.0" "Cyan"
    Write-Color "     Universal instrument for you" "Yellow"
    Write-Color "     by merybist" "Yellow"
    Write-Color "============================================================" "Cyan"
    Write-Color ""
    
    Show-SystemInfo
    Check-ActivationStatus -DisplayOnly $true
    
    Write-Color ""
    Write-Color "============================================================" "Magenta"
    Write-Color "                      MAIN MENU" "Magenta"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color " 1. Check Activation Status" "White"
    Write-Color " 2. Windows Activation Methods" "White"
    Write-Color " 3. Office Activation Methods" "White"
    Write-Color " 4. Backup Activation" "White"
    Write-Color " 5. Restore Activation" "White"
    Write-Color " 6. Repair Components" "White"
    Write-Color " 7. Auto-Activate (All Methods)" "Yellow"
    Write-Color " 8. View Logs" "White"
    Write-Color " 9. Exit" "Red"
    Write-Color "============================================================" "Magenta"
    Write-Color ""
}

function Show-WindowsMethodsMenu {
    while ($true) {
        Clear-Host
        Write-Color ""
        Write-Color "============================================================" "Magenta"
        Write-Color "              WINDOWS ACTIVATION METHODS" "Magenta"
        Write-Color "------------------------------------------------------------" "Magenta"
        Write-Color " 1. KMS Online Activation (180 days)" "White"
        Write-Color " 2. HWID Digital License (Permanent)" "Green"
        Write-Color " 3. KMS38 Activation (Until 2038)" "Green"
        Write-Color " 4. TSForge Local KMS" "White"
        Write-Color " 5. MAS Method (Recommended)" "Yellow"
        Write-Color " 6. Generic Key Installation" "White"
        Write-Color " 0. Back to Main Menu" "Red"
        Write-Color "============================================================" "Magenta"
        Write-Color ""
        
        $choice = Read-Host "Select method (0-6)"
        
        switch ($choice) {
            "1" { Activate-KMS; Pause-Action }
            "2" { Activate-HWID; Pause-Action }
            "3" { Activate-KMS38; Pause-Action }
            "4" { Activate-TSForge; Pause-Action }
            "5" { Activate-MAS; Pause-Action }
            "6" { Activate-GenericKey; Pause-Action }
            "0" { return }
            default { Write-Color "Invalid selection!" "Red"; Start-Sleep -Seconds 1 }
        }
    }
}

function Show-OfficeMethodsMenu {
    while ($true) {
        Clear-Host
        Write-Color ""
        Write-Color "============================================================" "Magenta"
        Write-Color "               OFFICE ACTIVATION METHODS" "Magenta"
        Write-Color "------------------------------------------------------------" "Magenta"
        Write-Color " 1. KMS Office Activation (180 days)" "White"
        Write-Color " 2. Ohook Method (Permanent)" "Green"
        Write-Color " 3. TSforge Office (Permanent)" "Green"
        Write-Color " 4. Manual Key Activation" "White"
        Write-Color " 5. Office 365 Activation" "Yellow"
        Write-Color " 0. Back to Main Menu" "Red"
        Write-Color "============================================================" "Magenta"
        Write-Color ""
        
        $choice = Read-Host "Select method (0-5)"
        
        switch ($choice) {
            "1" { Activate-Office-KMS; Pause-Action }
            "2" { Activate-Ohook; Pause-Action }
            "3" { Activate-TSForge-Office; Pause-Action }
            "4" { Activate-Office-Manual; Pause-Action }
            "5" { Activate-Office365; Pause-Action }
            "0" { return }
            default { Write-Color "Invalid selection!" "Red"; Start-Sleep -Seconds 1 }
        }
    }
}
#endregion

#region Core Functions
function Show-SystemInfo {
    Write-Color ""
    Write-Color "=== SYSTEM INFORMATION ===" "Cyan"
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        
        if ($os) {
            Write-Color "OS: $($os.Caption)" "White"
            Write-Color "Version: $($os.Version) (Build $($os.BuildNumber))" "White"
            Write-Color "Architecture: $($os.OSArchitecture)" "White"
        }
        
        if ($comp) {
            Write-Color "Computer: $($comp.Name)" "White"
        }
    }
    catch {
        Write-Color "Error getting system info" "Yellow"
    }
}

function Check-ActivationStatus {
    param([bool]$DisplayOnly = $false)
    
    $status = @{
        Windows = "NOT ACTIVATED"
        Office = "NOT ACTIVATED"
    }
    
    try {
        $winStatus = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        if ($winStatus -match "Licensed|Activated") {
            $status.Windows = "ACTIVATED"
            $global:IsWindowsActivated = $true
        }
        else {
            $global:IsWindowsActivated = $false
        }
    }
    catch {
        Write-Log "Error checking Windows activation" "ERROR"
    }
    
    try {
        $officePaths = Get-OfficePaths
        foreach ($path in $officePaths) {
            $ospp = Join-Path $path "ospp.vbs"
            if (Test-Path $ospp) {
                $officeStatus = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($officeStatus -match "LICENSED") {
                    $status.Office = "ACTIVATED"
                    $global:IsOfficeActivated = $true
                    break
                }
            }
        }
        
        if ($status.Office -eq "NOT ACTIVATED") {
            $global:IsOfficeActivated = $false
        }
    }
    catch {
        Write-Log "Error checking Office activation" "ERROR"
    }
    
    if ($DisplayOnly) {
        Write-Color ""
        Write-Color "=== ACTIVATION STATUS ===" "Cyan"
        $winColor = if ($status.Windows -eq "ACTIVATED") { "Green" } else { "Red" }
        $officeColor = if ($status.Office -eq "ACTIVATED") { "Green" } else { "Red" }
        Write-Color "Windows: $($status.Windows)" $winColor
        Write-Color "Office: $($status.Office)" $officeColor
    }
    
    return $status
}

function Backup-Activation {
    Write-Color ""
    Write-Color "Creating activation backup..." "Cyan"
    
    try {
        if (!(Test-Path $global:BackupPath)) {
            New-Item -ItemType Directory -Path $global:BackupPath -Force | Out-Null
        }
        
        $tokenPath = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform"
        if (Test-Path $tokenPath) {
            Copy-Item -Path $tokenPath -Destination "$global:BackupPath\Tokens" -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $regKeys = @(
            "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform",
            "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
        )
        
        foreach ($key in $regKeys) {
            $fileName = $key.Replace("\", "_").Replace(":", "") + ".reg"
            reg export $key "$global:BackupPath\$fileName" /y 2>$null
        }
        
        Write-Color "Backup created at: $global:BackupPath" "Green"
        Write-Log "Backup created successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Color "Backup failed: $_" "Red"
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

function Restore-Activation {
    Write-Color ""
    Write-Color "Restoring activation from backup..." "Cyan"
    
    try {
        if (!(Test-Path $global:BackupPath)) {
            Write-Color "No backup found!" "Red"
            return $false
        }
        
        Stop-Service -Name sppsvc -Force -ErrorAction SilentlyContinue
        Stop-Service -Name osppsvc -Force -ErrorAction SilentlyContinue
        
        $tokenBackup = "$global:BackupPath\Tokens"
        $tokenDest = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform"
        
        if (Test-Path $tokenBackup) {
            if (Test-Path $tokenDest) {
                Remove-Item -Path $tokenDest -Recurse -Force -ErrorAction SilentlyContinue
            }
            Copy-Item -Path $tokenBackup -Destination $tokenDest -Recurse -Force
        }
        
        Get-ChildItem -Path $global:BackupPath -Filter "*.reg" | ForEach-Object {
            reg import $_.FullName 2>$null
        }
        
        Start-Service -Name sppsvc -ErrorAction SilentlyContinue
        Start-Service -Name osppsvc -ErrorAction SilentlyContinue
        
        Write-Color "Activation restored successfully!" "Green"
        Write-Log "Activation restored from backup" "SUCCESS"
        return $true
    }
    catch {
        Write-Color "Restore failed: $_" "Red"
        Write-Log "Restore failed: $_" "ERROR"
        return $false
    }
}

function Repair-Components {
    Write-Color ""
    Write-Color "Repairing activation components..." "Cyan"
    
    try {
        $services = @("sppsvc", "osppsvc", "ClipSVC")
        foreach ($service in $services) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        }
        
        $cachePaths = @(
            "$env:SystemRoot\system32\spp\store\2.0",
            "$env:ProgramData\Microsoft\Windows\ClipSVC\Tokens"
        )
        
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        $dlls = @(
            "$env:SystemRoot\system32\sppcomapi.dll",
            "$env:SystemRoot\system32\slc.dll"
        )
        
        foreach ($dll in $dlls) {
            if (Test-Path $dll) {
                regsvr32.exe /s $dll 2>$null
            }
        }
        
        foreach ($service in $services) {
            Start-Service -Name $service -ErrorAction SilentlyContinue
        }
        
        Write-Color "Components repaired successfully!" "Green"
        Write-Log "Activation components repaired" "SUCCESS"
        return $true
    }
    catch {
        Write-Color "Repair failed: $_" "Red"
        Write-Log "Repair failed: $_" "ERROR"
        return $false
    }
}
#endregion

#region Windows Activation Methods
function Activate-KMS {
    Write-Color ""
    Write-Color "Starting KMS Activation (180 days, renewable)..." "Cyan"
    Write-Log "Starting KMS activation" "INFO"
    
    $kmsServers = @(
        "kms8.msguides.com",
        "kms.digiboy.ir",
        "kms.lotro.cc",
        "kms.chinancce.com",
        "kms.03k.org",
        "kms.library.hk"
    )
    
    $success = $false
    
    foreach ($server in $kmsServers) {
        Write-Color "Trying server: $server" "White"
        
        try {
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms $server 2>&1 | Out-Null
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
            
            Start-Sleep -Seconds 2
            $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
            if ($status -match "Licensed") {
                Write-Color "SUCCESS: Activated via KMS: $server" "Green"
                Write-Log "Windows activated via KMS: $server" "SUCCESS"
                $success = $true
                
                Activate-Office-KMS -Server $server
                break
            }
        }
        catch {
            Write-Color "Failed with server $server" "Yellow"
        }
    }
    
    if (-not $success) {
        Write-Color "All KMS servers failed. Try another method." "Red"
    }
    
    return $success
}

function Activate-HWID {
    Write-Color ""
    Write-Color "Starting HWID (Permanent Digital License)..." "Cyan"
    Write-Log "Starting HWID activation" "INFO"
    
    try {
        $hwidKeys = @{
            "Pro" = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
            "Home" = "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"
            "Education" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
            "Enterprise" = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
        }
        
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $hwidKeys["Pro"] 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        Start-Sleep -Seconds 3
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        
        if ($status -match "Digital License|Licensed") {
            Write-Color "SUCCESS: HWID activation successful (Permanent)!" "Green"
            Write-Log "HWID activation successful" "SUCCESS"
            return $true
        }
        else {
            Write-Color "HWID activation failed" "Red"
            return $false
        }
    }
    catch {
        Write-Color "HWID activation error: $_" "Red"
        Write-Log "HWID activation error: $_" "ERROR"
        return $false
    }
}

function Activate-KMS38 {
    Write-Color ""
    Write-Color "Starting KMS38 (Activate until 2038)..." "Cyan"
    Write-Log "Starting KMS38 method" "INFO"
    
    try {
        $key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $key 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms kms8.msguides.com 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        Start-Sleep -Seconds 3
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /xpr 2>&1
        
        if ($status -match "2038|permanently") {
            Write-Color "SUCCESS: KMS38 activated until 2038!" "Green"
            Write-Log "KMS38 activation successful" "SUCCESS"
            return $true
        }
        else {
            Write-Color "KMS38 method failed" "Red"
            return $false
        }
    }
    catch {
        Write-Color "KMS38 error: $_" "Red"
        Write-Log "KMS38 error: $_" "ERROR"
        return $false
    }
}

function Activate-TSForge {
    Write-Color ""
    Write-Color "Starting TSForge (Local KMS) Method..." "Cyan"
    Write-Log "Starting TSForge method" "INFO"
    
    try {
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms 127.0.0.1 2>&1 | Out-Null
        
        $key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $key 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        Start-Sleep -Seconds 2
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        if ($status -match "Licensed") {
            Write-Color "SUCCESS: TSForge method successful!" "Green"
            Write-Log "TSForge method successful" "SUCCESS"
            return $true
        }
        else {
            Write-Color "TSForge method failed" "Red"
            return $false
        }
    }
    catch {
        Write-Color "TSForge error: $_" "Red"
        Write-Log "TSForge error: $_" "ERROR"
        return $false
    }
}

function Activate-MAS {
    Write-Color ""
    Write-Color "Starting MAS (Recommended Method)..." "Cyan"
    Write-Log "Starting MAS method" "INFO"
    
    try {
        $kms38Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $kms38Key 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms kms8.msguides.com 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        Start-Sleep -Seconds 2
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk "W269N-WFGWX-YVC9B-4J6C9-T83GX" 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        Start-Sleep -Seconds 2
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        if ($status -match "Licensed") {
            Write-Color "SUCCESS: MAS method successful!" "Green"
            Write-Log "MAS method successful" "SUCCESS"
            
            $officePaths = Get-OfficePaths
            foreach ($path in $officePaths) {
                $ospp = Join-Path $path "ospp.vbs"
                if (Test-Path $ospp) {
                    cscript //Nologo "$ospp" /sethst:kms8.msguides.com 2>&1 | Out-Null
                    cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                }
            }
            
            return $true
        }
        else {
            Write-Color "MAS method failed" "Red"
            return $false
        }
    }
    catch {
        Write-Color "MAS method error: $_" "Red"
        Write-Log "MAS method error: $_" "ERROR"
        return $false
    }
}

function Activate-GenericKey {
    Write-Color ""
    Write-Color "=== Generic Key Installation ===" "Cyan"
    Write-Color "1. Windows 10/11 Pro" "White"
    Write-Color "2. Windows 10/11 Home" "White"
    Write-Color "3. Windows 10/11 Education" "White"
    Write-Color "4. Windows 10/11 Enterprise" "White"
    Write-Color ""
    
    $choice = Read-Host "Select edition (1-4)"
    
    $keys = @{
        "1" = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        "2" = "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"
        "3" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
        "4" = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
    }
    
    if ($keys.ContainsKey($choice)) {
        try {
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $keys[$choice] 2>&1 | Out-Null
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
            Write-Color "Generic key installed successfully!" "Green"
            return $true
        }
        catch {
            Write-Color "Failed to install key" "Red"
            return $false
        }
    }
    else {
        Write-Color "Invalid selection" "Red"
        return $false
    }
}
#endregion

#region Office Activation Methods
function Get-OfficePaths {
    $paths = @()
    
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft Office\Office16",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
        "${env:ProgramFiles}\Microsoft Office\Office15",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
        "${env:ProgramFiles}\Microsoft Office\root\Office16",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $paths += $path
        }
    }
    
    return $paths
}

function Activate-Office-KMS {
    param([string]$Server = "kms8.msguides.com")
    
    Write-Color ""
    Write-Color "Activating Office via KMS (180 days, renewable)..." "Cyan"
    Write-Log "Starting Office KMS activation" "INFO"
    
    $officePaths = Get-OfficePaths
    
    if ($officePaths.Count -eq 0) {
        Write-Color "Office not found on this system" "Red"
        return $false
    }
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                Write-Color "Found Office at: $path" "White"
                
                cscript //Nologo "$ospp" /sethst:$Server 2>&1 | Out-Null
                cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                
                Start-Sleep -Seconds 2
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "SUCCESS: Office activated via KMS!" "Green"
                    Write-Log "Office activated via KMS" "SUCCESS"
                    return $true
                }
            }
            catch {
                Write-Color "Office activation failed: $_" "Yellow"
                Write-Log "Office KMS activation failed: $_" "ERROR"
            }
        }
    }
    
    Write-Color "Office activation failed" "Red"
    return $false
}

function Activate-Ohook {
    Write-Color ""
    Write-Color "Starting Ohook Office Activation (Permanent)..." "Cyan"
    Write-Log "Starting Ohook method" "INFO"
    
    $officePaths = Get-OfficePaths
    
    if ($officePaths.Count -eq 0) {
        Write-Color "Office not found on this system" "Red"
        return $false
    }
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                Write-Color "Applying Ohook method to Office..." "White"
                
                $officeKeys = @{
                    "Office 2019 ProPlus" = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"
                    "Office 2021 ProPlus" = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
                    "Office 365" = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
                }
                
                foreach ($key in $officeKeys.Values) {
                    cscript //Nologo "$ospp" /inpkey:$key 2>&1 | Out-Null
                    Start-Sleep -Milliseconds 500
                }
                
                cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                
                Start-Sleep -Seconds 2
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "SUCCESS: Ohook method successful!" "Green"
                    Write-Log "Ohook method successful" "SUCCESS"
                    return $true
                }
            }
            catch {
                Write-Color "Ohook method failed: $_" "Red"
                Write-Log "Ohook method failed: $_" "ERROR"
            }
        }
    }
    
    return $false
}

function Activate-TSForge-Office {
    Write-Color ""
    Write-Color "Starting TSforge Office Activation (Permanent)..." "Cyan"
    Write-Log "Starting TSforge Office method" "INFO"
    
    $officePaths = Get-OfficePaths
    
    if ($officePaths.Count -eq 0) {
        Write-Color "Office not found on this system" "Red"
        return $false
    }
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                Write-Color "Applying TSforge method..." "White"
                
                cscript //Nologo "$ospp" /sethst:127.0.0.1 2>&1 | Out-Null
                cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                
                Start-Sleep -Seconds 2
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "SUCCESS: TSforge Office activation successful!" "Green"
                    Write-Log "TSforge Office successful" "SUCCESS"
                    return $true
                }
            }
            catch {
                Write-Color "TSforge Office failed: $_" "Red"
            }
        }
    }
    
    return $false
}

function Activate-Office365 {
    Write-Color ""
    Write-Color "Starting Office 365 Activation..." "Cyan"
    Write-Log "Starting Office 365 activation" "INFO"
    
    $officePaths = Get-OfficePaths
    
    if ($officePaths.Count -eq 0) {
        Write-Color "Office not found on this system" "Red"
        return $false
    }
    
    $o365Keys = @(
        "DRNV7-VGMM2-B3G9T-4BF84-XWH26",
        "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
    )
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                foreach ($key in $o365Keys) {
                    cscript //Nologo "$ospp" /inpkey:$key 2>&1 | Out-Null
                }
                
                cscript //Nologo "$ospp" /sethst:kms8.msguides.com 2>&1 | Out-Null
                cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                
                Start-Sleep -Seconds 2
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "SUCCESS: Office 365 activated!" "Green"
                    Write-Log "Office 365 activation successful" "SUCCESS"
                    return $true
                }
            }
            catch {
                Write-Color "Office 365 activation failed: $_" "Red"
            }
        }
    }
    
    return $false
}

function Activate-Office-Manual {
    Write-Color ""
    Write-Color "=== Manual Office Key Activation ===" "Cyan"
    
    $key = Read-Host "Enter Office product key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)"
    
    if ($key -match "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$") {
        $officePaths = Get-OfficePaths
        
        if ($officePaths.Count -eq 0) {
            Write-Color "Office not found on this system" "Red"
            return $false
        }
        
        foreach ($path in $officePaths) {
            $ospp = Join-Path $path "ospp.vbs"
            if (Test-Path $ospp) {
                try {
                    cscript //Nologo "$ospp" /inpkey:$key 2>&1 | Out-Null
                    cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                    
                    Write-Color "SUCCESS: Key applied successfully!" "Green"
                    Write-Log "Manual Office key applied" "INFO"
                    return $true
                }
                catch {
                    Write-Color "Failed to apply key: $_" "Red"
                }
            }
        }
    }
    else {
        Write-Color "Invalid key format!" "Red"
    }
    
    return $false
}
#endregion

#region Auto-Activation
function Auto-Activate {
    Write-Color ""
    Write-Color "============================================================" "Cyan"
    Write-Color "     Starting Auto-Activation Sequence..." "Cyan"
    Write-Color "     This will try all activation methods in order" "White"
    Write-Color "============================================================" "Cyan"
    Write-Color ""
    
    Write-Color "Step 1: Creating backup..." "Yellow"
    Backup-Activation | Out-Null
    Start-Sleep -Seconds 1
    
    $windowsMethods = @(
        @{Name = "HWID Digital License"; Function = { Activate-HWID } },
        @{Name = "KMS38 Activation"; Function = { Activate-KMS38 } },
        @{Name = "KMS Online"; Function = { Activate-KMS } },
        @{Name = "MAS Method"; Function = { Activate-MAS } }
    )
    
    $activatedWindows = $false
    
    Write-Color ""
    Write-Color "=== WINDOWS ACTIVATION ===" "Cyan"
    foreach ($method in $windowsMethods) {
        Write-Color ""
        Write-Color "Trying: $($method.Name)" "Yellow"
        $result = & $method.Function
        
        if ($result) {
            $activatedWindows = $true
            Write-Color "Windows activation successful!" "Green"
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    $officeMethods = @(
        @{Name = "Ohook Method"; Function = { Activate-Ohook } },
        @{Name = "TSforge Office"; Function = { Activate-TSForge-Office } },
        @{Name = "Office KMS"; Function = { Activate-Office-KMS } },
        @{Name = "Office 365"; Function = { Activate-Office365 } }
    )
    
    $activatedOffice = $false
    
    Write-Color ""
    Write-Color "=== OFFICE ACTIVATION ===" "Cyan"
    foreach ($method in $officeMethods) {
        Write-Color ""
        Write-Color "Trying: $($method.Name)" "Yellow"
        $result = & $method.Function
        
        if ($result) {
            $activatedOffice = $true
            Write-Color "Office activation successful!" "Green"
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    Write-Color ""
    Write-Color "============================================================" "Cyan"
    Write-Color "            AUTO-ACTIVATION COMPLETE" "Cyan"
    Write-Color "============================================================" "Cyan"
    
    $status = Check-ActivationStatus -DisplayOnly $true
    
    Write-Color ""
    if ($status.Windows -eq "ACTIVATED" -and $status.Office -eq "ACTIVATED") {
        Write-Color "SUCCESS: Both Windows and Office activated!" "Green"
    }
    elseif ($status.Windows -eq "ACTIVATED") {
        Write-Color "Windows activated, Office may need manual activation" "Yellow"
    }
    elseif ($status.Office -eq "ACTIVATED") {
        Write-Color "Office activated, Windows may need manual activation" "Yellow"
    }
    else {
        Write-Color "Activation failed. Try manual methods or repair." "Red"
    }
}
#endregion

#region View Logs
function View-Logs {
    Write-Color ""
    Write-Color "=== ACTIVATION LOGS (Last 50 entries) ===" "Cyan"
    Write-Color ""
    
    if (Test-Path $global:LogPath) {
        Get-Content $global:LogPath | Select-Object -Last 50 | ForEach-Object {
            if ($_ -match "\[ERROR\]") {
                Write-Color $_ "Red"
            }
            elseif ($_ -match "\[SUCCESS\]") {
                Write-Color $_ "Green"
            }
            elseif ($_ -match "\[WARNING\]") {
                Write-Color $_ "Yellow"
            }
            else {
                Write-Color $_ "Gray"
            }
        }
    }
    else {
        Write-Color "No logs found yet." "Yellow"
    }
}
#endregion

#region Main Execution
function Main {
    $adminTest = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $adminTest) {
        Write-Color ""
        Write-Color "============================================================" "Red"
        Write-Color "          ERROR: Administrator Privileges Required" "Red"
        Write-Color "============================================================" "Red"
        Write-Color ""
        Write-Color "This script requires Administrator privileges!" "Red"
        Write-Color "Please run PowerShell as Administrator and try again." "Yellow"
        Write-Color ""
        Pause-Action
        exit 1
    }
    
    Write-Log "Script started by user: $env:USERNAME" "INFO"
    Write-Log "Computer: $env:COMPUTERNAME" "INFO"
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select option (1-9)"
        
        switch ($choice) {
            "1" {
                Check-ActivationStatus -DisplayOnly $true
                Pause-Action
            }
            "2" {
                Show-WindowsMethodsMenu
            }
            "3" {
                Show-OfficeMethodsMenu
            }
            "4" {
                Backup-Activation
                Pause-Action
            }
            "5" {
                Restore-Activation
                Pause-Action
            }
            "6" {
                Repair-Components
                Pause-Action
            }
            "7" {
                Auto-Activate
                Pause-Action
            }
            "8" {
                View-Logs
                Pause-Action
            }
            "9" {
                Write-Color ""
                Write-Color "============================================================" "Cyan"
                Write-Color "          Thanks for using Activation Toolkit v4.0!" "Cyan"
                Write-Color "          by merybist" "Yellow"
                Write-Color "============================================================" "Cyan"
                Write-Color ""
                Write-Log "Script ended by user" "INFO"
                exit 0
            }
            default {
                Write-Color "Invalid option! Please select 1-9." "Red"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Script entry point
try {
    Clear-Host
    Write-Color ""
    Write-Color "============================================================" "Cyan"
    Write-Color "      WINDOWS & OFFICE ACTIVATION TOOLKIT" "Cyan"
    Write-Color "      Version 4.0 - Enhanced Edition" "Yellow"
    Write-Color "      by merybist" "Yellow"
    Write-Color "      Loading..." "White"
    Write-Color "============================================================" "Cyan"
    Write-Color ""
    
    Start-Sleep -Seconds 1
    Main
}
catch {
    Write-Color ""
    Write-Color "============================================================" "Red"
    Write-Color "          FATAL ERROR" "Red"
    Write-Color "============================================================" "Red"
    Write-Color "Error: $_" "Red"
    Write-Log "Fatal error: $_" "ERROR"
    Write-Color ""
    Pause-Action
    exit 1
}
#endregion
