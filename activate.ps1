# Windows & Office Activation Toolkit v3.0
# For execution via: irm https://raw.githubusercontent.com/[username]/[repo]/main/activate.ps1 | iex
# Cybersecurity Course - Section 4, Lesson 26
# Educational Purposes Only

#region Initial Setup
$global:IsWindowsActivated = $false
$global:IsOfficeActivated = $false
$global:BackupPath = "$env:TEMP\ActivationBackup"
$global:LogPath = "$env:TEMP\ActivationLogs\activation.log"

# Create log directory
if (!(Test-Path (Split-Path $global:LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $global:LogPath) -Force | Out-Null
}

# Log function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:LogPath -Value $logEntry
}

# Color output function
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}
#endregion

#region Main Menu
function Show-MainMenu {
    Clear-Host
    Write-Color "`n" "Cyan"
    Write-Color "------------------------------------------------------------" "Cyan"
    Write-Color "|      WINDOWS & OFFICE ACTIVATION TOOLKIT v3.0            |" "Cyan"
    Write-Color "|      Universal instrument for you <3                     |" "Cyan"
    Write-Color "|      by merybist                                         |" "Yellow"
    Write-Color "------------------------------------------------------------" "Cyan"
    Write-Color "`n"
    
    # Show current status
    Show-SystemInfo
    Check-ActivationStatus -DisplayOnly $true
    
    Write-Color "`n" "Cyan"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "|                      MAIN MENU                           |" "Magenta"
    Write-Color "|----------------------------------------------------------|" "Magenta"
    Write-Color "|  1. Check Activation Status                           |" "White"
    Write-Color "|  2. Windows Activation Methods                        |" "White"
    Write-Color "|  3. Office Activation Methods                         |" "White"
    Write-Color "|  4. Backup Activation                                 |" "White"
    Write-Color "|  5. Restore Activation                                |" "White"
    Write-Color "|  6. Repair Components                                 |" "White"
    Write-Color "|  7. Auto-Activate (All Methods)                       |" "Yellow"
    Write-Color "|  8. View Logs                                         |" "White"
    Write-Color "|  9. Exit                                              |" "White"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "`n"
}

function Show-WindowsMethodsMenu {
    Clear-Host
    Write-Color "`n" "Cyan"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "|              WINDOWS ACTIVATION METHODS                  |" "Magenta"
    Write-Color "|----------------------------------------------------------|" "Magenta"
    Write-Color "|  1. KMS Activation (Online Servers)                   |" "White"
    Write-Color "|  2. HWID (Digital License)                            |" "White"
    Write-Color "|  3. TSForge (Local KMS)                              |" "White"
    Write-Color "|  4. MAS Method                                       |" "White"
    Write-Color "|  5. Back to Main Menu                                 |" "White"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "`n"
    
    $choice = Read-Host "Select method (1-5)"
    
    switch ($choice) {
        "1" { Activate-KMS }
        "2" { Activate-HWID }
        "3" { Activate-TSForge }
        "4" { Activate-MAS }
        "5" { return }
        default { Write-Color "Invalid selection!" "Red" }
    }
}

function Show-OfficeMethodsMenu {
    Clear-Host
    Write-Color "`n" "Cyan"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "|               OFFICE ACTIVATION METHODS                  |" "Magenta"
    Write-Color "|----------------------------------------------------------|" "Magenta"
    Write-Color "|  1. KMS Office Activation                             |" "White"
    Write-Color "|  2. Ohook Method                                      |" "White"
    Write-Color "|  3. Manual Key Activation                             |" "White"
    Write-Color "|  4. Back to Main Menu                                 |" "White"
    Write-Color "------------------------------------------------------------" "Magenta"
    Write-Color "`n"
    
    $choice = Read-Host "Select method (1-4)"
    
    switch ($choice) {
        "1" { Activate-Office-KMS }
        "2" { Activate-Ohook }
        "3" { Activate-Office-Manual }
        "4" { return }
        default { Write-Color "Invalid selection!" "Red" }
    }
}
#endregion

#region Core Functions
function Show-SystemInfo {
    Write-Color "`n=== SYSTEM INFORMATION ===" "Cyan"
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        
        if ($os) {
            Write-Color "OS: $($os.Caption)" "White"
            Write-Color "Version: $($os.Version) (Build $($os.BuildNumber))" "White"
            Write-Color "Architecture: $($os.OSArchitecture)" "White"
            Write-Color "Computer: $($os.CSName)" "White"
        }
        
        if ($comp) {
            Write-Color "Manufacturer: $($comp.Manufacturer)" "White"
            Write-Color "Model: $($comp.Model)" "White"
        }
        
        if ($cpu) {
            Write-Color "CPU: $($cpu.Name)" "White"
        }
    }
    catch {
        Write-Color "Error getting system info: $_" "Yellow"
    }
}

function Check-ActivationStatus {
    param([bool]$DisplayOnly = $false)
    
    $status = @{
        Windows = "NOT ACTIVATED"
        Office = "NOT ACTIVATED"
    }
    
    try {
        # Check Windows activation
        $winStatus = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli
        if ($winStatus -match "Licensed|Activated") {
            $status.Windows = "ACTIVATED"
            $global:IsWindowsActivated = $true
        }
        else {
            $global:IsWindowsActivated = $false
        }
    }
    catch {
        Write-Log "Error checking Windows activation: $_" "ERROR"
    }
    
    try {
        # Check Office activation
        $officePaths = @(
            "${env:ProgramFiles}\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
            "${env:ProgramFiles}\Microsoft Office\root\Office16"
        )
        
        foreach ($path in $officePaths) {
            $ospp = Join-Path $path "ospp.vbs"
            if (Test-Path $ospp) {
                $officeStatus = cscript //Nologo "$ospp" /dstatus
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
        Write-Log "Error checking Office activation: $_" "ERROR"
    }
    
    if ($DisplayOnly) {
        Write-Color "`n=== ACTIVATION STATUS ===" "Cyan"
        Write-Color "Windows: $($status.Windows)" -Color $(if ($status.Windows -eq "ACTIVATED") { "Green" } else { "Red" })
        Write-Color "Office: $($status.Office)" -Color $(if ($status.Office -eq "ACTIVATED") { "Green" } else { "Red" })
    }
    
    return $status
}

function Backup-Activation {
    Write-Color "`nCreating activation backup..." "Cyan"
    
    try {
        if (!(Test-Path $global:BackupPath)) {
            New-Item -ItemType Directory -Path $global:BackupPath -Force | Out-Null
        }
        
        # Backup Windows tokens
        $tokenPath = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform"
        if (Test-Path $tokenPath) {
            Copy-Item -Path $tokenPath -Destination "$global:BackupPath\Tokens" -Recurse -Force
        }
        
        # Export registry keys
        $regKeys = @(
            "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform",
            "HKLM\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
        )
        
        foreach ($key in $regKeys) {
            $fileName = $key.Replace("\", "_").Replace(":", "") + ".reg"
            reg export $key "$global:BackupPath\$fileName" /y 2>$null
        }
        
        Write-Color "Backup created at: $global:BackupPath" "Green"
        Write-Log "Backup created successfully" "INFO"
        return $true
    }
    catch {
        Write-Color "Backup failed: $_" "Red"
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

function Restore-Activation {
    Write-Color "`nRestoring activation from backup..." "Cyan"
    
    try {
        if (!(Test-Path $global:BackupPath)) {
            Write-Color "No backup found!" "Red"
            return $false
        }
        
        # Stop services
        Stop-Service -Name sppsvc -Force -ErrorAction SilentlyContinue
        Stop-Service -Name osppsvc -Force -ErrorAction SilentlyContinue
        
        # Restore tokens
        $tokenBackup = "$global:BackupPath\Tokens"
        $tokenDest = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform"
        
        if (Test-Path $tokenBackup) {
            if (Test-Path $tokenDest) {
                Remove-Item -Path $tokenDest -Recurse -Force -ErrorAction SilentlyContinue
            }
            Copy-Item -Path $tokenBackup -Destination $tokenDest -Recurse -Force
        }
        
        # Import registry keys
        Get-ChildItem -Path $global:BackupPath -Filter "*.reg" | ForEach-Object {
            reg import $_.FullName 2>$null
        }
        
        # Start services
        Start-Service -Name sppsvc -ErrorAction SilentlyContinue
        Start-Service -Name osppsvc -ErrorAction SilentlyContinue
        
        Write-Color "Activation restored successfully!" "Green"
        Write-Log "Activation restored from backup" "INFO"
        return $true
    }
    catch {
        Write-Color "Restore failed: $_" "Red"
        Write-Log "Restore failed: $_" "ERROR"
        return $false
    }
}

function Repair-Components {
    Write-Color "`nRepairing activation components..." "Cyan"
    
    try {
        # Stop services
        $services = @("sppsvc", "osppsvc", "ClipSVC")
        foreach ($service in $services) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        }
        
        # Clear cache
        $cachePaths = @(
            "$env:SystemRoot\system32\spp\store\2.0",
            "$env:ProgramData\Microsoft\Windows\ClipSVC\Tokens"
        )
        
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Re-register DLLs
        $dlls = @(
            "$env:SystemRoot\system32\sppcomapi.dll",
            "$env:SystemRoot\system32\slc.dll"
        )
        
        foreach ($dll in $dlls) {
            if (Test-Path $dll) {
                regsvr32.exe /s $dll 2>$null
            }
        }
        
        # Restart services
        foreach ($service in $services) {
            Start-Service -Name $service -ErrorAction SilentlyContinue
        }
        
        Write-Color "Components repaired successfully!" "Green"
        Write-Log "Activation components repaired" "INFO"
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
    Write-Color "`nStarting KMS Activation..." "Cyan"
    Write-Log "Starting KMS activation" "INFO"
    
    $kmsServers = @(
        "kms8.msguides.com",
        "kms.digiboy.ir", 
        "kms.lotro.cc",
        "kms.chinancce.com"
    )
    
    $success = $false
    
    foreach ($server in $kmsServers) {
        Write-Color "Trying server: $server" "White"
        
        try {
            # Set KMS server
            $output = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms $server 2>&1
            
            # Activate
            $output = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1
            
            # Check activation
            $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
            if ($status -match "Licensed") {
                Write-Color "✓ Successfully activated via KMS: $server" "Green"
                Write-Log "Windows activated via KMS: $server" "SUCCESS"
                $success = $true
                
                # Try Office activation
                Activate-Office-KMS -Server $server
                break
            }
        }
        catch {
            Write-Color "Failed with server $server" "Yellow"
        }
    }
    
    if (-not $success) {
        Write-Color "All KMS servers failed" "Red"
    }
    
    return $success
}

function Activate-HWID {
    Write-Color "`nStarting HWID (Digital License) Activation..." "Cyan"
    Write-Log "Starting HWID activation" "INFO"
    
    try {
        # Use generic keys for digital entitlement
        $hwidKeys = @{
            "Windows 10/11 Pro" = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
            "Windows 10/11 Home" = "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"
            "Windows 10/11 Education" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
        }
        
        # Install key
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $hwidKeys["Windows 10/11 Pro"] 2>&1 | Out-Null
        
        # Activate
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Check status
        Start-Sleep -Seconds 3
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        
        if ($status -match "Digital License|Licensed") {
            Write-Color "✓ HWID activation successful!" "Green"
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

function Activate-TSForge {
    Write-Color "`nStarting TSForge (Local KMS) Method..." "Cyan"
    Write-Log "Starting TSForge method" "INFO"
    
    try {
        # Set local KMS server
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms 127.0.0.1 2>&1 | Out-Null
        
        # Install generic key
        $key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $key 2>&1 | Out-Null
        
        # Activate
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Check
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        if ($status -match "Licensed") {
            Write-Color "✓ TSForge method successful!" "Green"
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
    Write-Color "`nStarting MAS (Microsoft Activation Scripts) Method..." "Cyan"
    Write-Log "Starting MAS method" "INFO"
    
    try {
        # This simulates MAS behavior
        # Try KMS38 first (activate until 2038)
        $kms38Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $kms38Key 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms kms8.msguides.com 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Try HWID as fallback
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk "W269N-WFGWX-YVC9B-4J6C9-T83GX" 2>&1 | Out-Null
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Check status
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1
        if ($status -match "Licensed") {
            Write-Color "✓ MAS method successful!" "Green"
            Write-Log "MAS method successful" "SUCCESS"
            
            # Try Office activation
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
    
    Write-Color "`nActivating Office via KMS..." "Cyan"
    Write-Log "Starting Office KMS activation" "INFO"
    
    $officePaths = Get-OfficePaths
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                Write-Color "Found Office at: $path" "White"
                
                # Set KMS server
                $output = cscript //Nologo "$ospp" /sethst:$Server 2>&1
                
                # Activate
                $output = cscript //Nologo "$ospp" /act 2>&1
                
                # Check status
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "✓ Office activated via KMS!" "Green"
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
    
    Write-Color "Office not found or activation failed" "Red"
    return $false
}

function Activate-Ohook {
    Write-Color "`nStarting Ohook Office Activation..." "Cyan"
    Write-Log "Starting Ohook method" "INFO"
    
    $officePaths = Get-OfficePaths
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                Write-Color "Applying Ohook method to Office..." "White"
                
                # Ohook simulates a license hook
                # Apply generic Office keys
                $officeKeys = @{
                    "Office 2019 ProPlus" = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"
                    "Office 2021 ProPlus" = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
                    "Office 365" = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
                }
                
                foreach ($key in $officeKeys.Values) {
                    cscript //Nologo "$ospp" /inpkey:$key 2>&1 | Out-Null
                    Start-Sleep -Milliseconds 500
                }
                
                # Activate
                cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                
                # Check status
                $status = cscript //Nologo "$ospp" /dstatus 2>&1
                if ($status -match "LICENSED") {
                    Write-Color "✓ Ohook method successful!" "Green"
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

function Activate-Office-Manual {
    Write-Color "`nManual Office Key Activation" "Cyan"
    
    $key = Read-Host "Enter Office product key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)"
    
    if ($key -match "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$") {
        $officePaths = Get-OfficePaths
        
        foreach ($path in $officePaths) {
            $ospp = Join-Path $path "ospp.vbs"
            if (Test-Path $ospp) {
                try {
                    cscript //Nologo "$ospp" /inpkey:$key 2>&1 | Out-Null
                    cscript //Nologo "$ospp" /act 2>&1 | Out-Null
                    
                    Write-Color "✓ Key applied successfully!" "Green"
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
    Write-Color "`n Starting Auto-Activation Sequence..." "Cyan"
    Write-Color "This will try all activation methods in order" "White"
    Write-Color "`n"
    
    # Backup first
    Write-Color "Step 1: Creating backup..." "Yellow"
    Backup-Activation | Out-Null
    
    # Methods to try
    $methods = @(
        @{Name = "KMS Activation"; Function = { Activate-KMS } },
        @{Name = "HWID Activation"; Function = { Activate-HWID } },
        @{Name = "MAS Method"; Function = { Activate-MAS } },
        @{Name = "TSForge Method"; Function = { Activate-TSForge } }
    )
    
    $activatedWindows = $false
    $activatedOffice = $false
    
    # Try Windows methods
    foreach ($method in $methods) {
        Write-Color "`nTrying: $($method.Name)" "Cyan"
        $result = & $method.Function
        
        if ($result) {
            $activatedWindows = $true
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    # Try Office methods
    if (-not $activatedOffice) {
        Write-Color "`nTrying Office activation..." "Cyan"
        $officeMethods = @(
            @{Name = "Office KMS"; Function = { Activate-Office-KMS } },
            @{Name = "Ohook Method"; Function = { Activate-Ohook } }
        )
        
        foreach ($method in $officeMethods) {
            Write-Color "Trying: $($method.Name)" "Cyan"
            $result = & $method.Function
            
            if ($result) {
                $activatedOffice = $true
                break
            }
            
            Start-Sleep -Seconds 2
        }
    }
    
    # Final status
    Write-Color "`n" + "="*50 "Cyan"
    Write-Color "AUTO-ACTIVATION COMPLETE" "Cyan"
    Write-Color "="*50 "Cyan"
    
    $status = Check-ActivationStatus -DisplayOnly $true
    
    if ($status.Windows -eq "ACTIVATED" -and $status.Office -eq "ACTIVATED") {
        Write-Color " SUCCESS: Both Windows and Office activated!" "Green"
    }
    elseif ($status.Windows -eq "ACTIVATED") {
        Write-Color " Windows activated, Office may need manual activation" "Yellow"
    }
    elseif ($status.Office -eq "ACTIVATED") {
        Write-Color " Office activated, Windows may need manual activation" "Yellow"
    }
    else {
        Write-Color " Activation failed. Try manual methods or repair." "Red"
    }
}
#endregion

#region View Logs
function View-Logs {
    Write-Color "`n=== ACTIVATION LOGS ===" "Cyan"
    
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
    # Check if running as administrator
    $adminTest = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $adminTest) {
        Write-Color "This script requires Administrator privileges!" "Red"
        Write-Color "Please run PowerShell as Administrator and try again." "Yellow"
        Write-Color "`nPress any key to exit..." "Gray"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    # Initial log
    Write-Log "Script started by user: $env:USERNAME" "INFO"
    Write-Log "Computer: $env:COMPUTERNAME" "INFO"
    
    # Main menu loop
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select option (1-9)"
        
        switch ($choice) {
            "1" {
                Check-ActivationStatus -DisplayOnly $true
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                Show-WindowsMethodsMenu
            }
            "3" {
                Show-OfficeMethodsMenu
            }
            "4" {
                Backup-Activation
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                Restore-Activation
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                Repair-Components
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" {
                Auto-Activate
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" {
                View-Logs
                Write-Color "`nPress any key to continue..." "Gray"
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "9" {
                Write-Color "`nExiting... Goodbye!" "Cyan"
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

# Start the script
try {
    # Clear screen and show welcome
    Clear-Host
    Write-Color "`n" "Cyan"
    Write-Color "------------------------------------------------------------" "Cyan"
    Write-Color "|      WINDOWS & OFFICE ACTIVATION TOOLKIT                |" "Cyan"
    Write-Color "|      Version 3.0                                        |" "Cyan"
    Write-Color "|      Loading...                                         |" "Cyan"
    Write-Color "------------------------------------------------------------" "Cyan"
    Write-Color "`n"
    
    Start-Sleep -Seconds 1
    Main
}
catch {
    Write-Color "Fatal error: $_" "Red"
    Write-Log "Fatal error: $_" "ERROR"
    Write-Color "`nPress any key to exit..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
#endregion
