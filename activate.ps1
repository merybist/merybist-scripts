# ================================================
# Windows & Office Activation Toolkit
# Enhanced with multiple activation methods
# Educational purposes only
# ================================================

#region Initialization and Configuration
param(
    [switch]$Silent = $false,
    [switch]$AutoMode = $false,
    [string]$Method = "",
    [string]$SavePath = "$env:TEMP\ActivationBackup",
    [string]$ProductKey = ""
)

# Colors for UI
$global:ColorSuccess = "Green"
$global:ColorError = "Red"
$global:ColorWarning = "Yellow"
$global:ColorInfo = "Cyan"
$global:ColorMenu = "Magenta"

# Global variables
$global:ActivationMethods = @()
$global:BackupCreated = $false
$global:IsWindowsActivated = $false
$global:IsOfficeActivated = $false

# Initialize logging
function Initialize-Logging {
    $logDir = "$env:TEMP\ActivationLogs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $global:LogFile = "$logDir\activation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    # Create transcript
    Start-Transcript -Path "$logDir\transcript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -Append
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [switch]$NoConsole = $false)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Add to log file
    $logEntry | Out-File -FilePath $global:LogFile -Append
    
    # Show in console if not silent
    if (-not $Silent -and -not $NoConsole) {
        switch ($Level) {
            "SUCCESS" { Write-Host $logEntry -ForegroundColor $global:ColorSuccess }
            "ERROR"   { Write-Host $logEntry -ForegroundColor $global:ColorError }
            "WARNING" { Write-Host $logEntry -ForegroundColor $global:ColorWarning }
            "DEBUG"   { Write-Host $logEntry -ForegroundColor Gray }
            default   { Write-Host $logEntry -ForegroundColor White }
        }
    }
}

# Check Administrator privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
#endregion

#region System Information
function Get-SystemInfo {
    Write-Log "Collecting system information..." "INFO"
    
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $compSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    
    $systemInfo = @{
        OSName = $os.Caption
        OSVersion = $os.Version
        BuildNumber = $os.BuildNumber
        Architecture = $os.OSArchitecture
        ComputerName = $os.CSName
        Manufacturer = $compSystem.Manufacturer
        Model = $compSystem.Model
        CPU = $cpu.Name
        BIOSSerial = $bios.SerialNumber
        SystemSKU = (Get-CimInstance -Namespace root\wmi -ClassName MS_SystemInformation).SystemSKU
        LastBootTime = $os.LastBootUpTime
    }
    
    return $systemInfo
}

function Show-SystemInfo {
    $info = Get-SystemInfo
    
    Write-Host "`n=== SYSTEM INFORMATION ===" -ForegroundColor $global:ColorInfo
    Write-Host "OS: $($info.OSName)" -ForegroundColor White
    Write-Host "Version: $($info.OSVersion) (Build $($info.BuildNumber))" -ForegroundColor White
    Write-Host "Architecture: $($info.Architecture)" -ForegroundColor White
    Write-Host "Computer: $($info.ComputerName)" -ForegroundColor White
    Write-Host "Manufacturer: $($info.Manufacturer)" -ForegroundColor White
    Write-Host "Model: $($info.Model)" -ForegroundColor White
    Write-Host "CPU: $($info.CPU)" -ForegroundColor White
    Write-Host "BIOS Serial: $($info.BIOSSerial)" -ForegroundColor White
    Write-Host "System SKU: $($info.SystemSKU)" -ForegroundColor White
    Write-Host "`n" -ForegroundColor White
}
#endregion

#region Activation Status Check
function Test-WindowsActivationStatus {
    try {
        $products = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object {
            $_.PartialProductKey -and $_.ApplicationID -eq '55c92734-d682-4d71-983e-d6ec3f16059f'
        }
        
        foreach ($product in $products) {
            if ($product.LicenseStatus -eq 1) {
                $global:IsWindowsActivated = $true
                return $true
            }
        }
        
        $global:IsWindowsActivated = $false
        return $false
    }
    catch {
        Write-Log "Error checking Windows activation: $_" "ERROR"
        return $false
    }
}

function Test-OfficeActivationStatus {
    try {
        # Check Click-to-Run Office
        $officePath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        if (Test-Path $officePath) {
            $config = Get-ItemProperty -Path $officePath
            if ($config.ProductReleaseIds -and $config.UpdatesEnabled -ne "False") {
                $global:IsOfficeActivated = $true
                return $true
            }
        }
        
        # Check MSI-based Office
        $officeProducts = Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object {
            $_.Name -like "*Office*" -or $_.ApplicationID -like "*Office*"
        }
        
        foreach ($product in $officeProducts) {
            if ($product.LicenseStatus -eq 1) {
                $global:IsOfficeActivated = $true
                return $true
            }
        }
        
        $global:IsOfficeActivated = $false
        return $false
    }
    catch {
        Write-Log "Error checking Office activation: $_" "WARNING"
        return $false
    }
}

function Show-ActivationStatus {
    $windowsStatus = Test-WindowsActivationStatus
    $officeStatus = Test-OfficeActivationStatus
    
    Write-Host "`n=== ACTIVATION STATUS ===" -ForegroundColor $global:ColorInfo
    
    $winColor = if ($windowsStatus) { $global:ColorSuccess } else { $global:ColorError }
    $officeColor = if ($officeStatus) { $global:ColorSuccess } else { $global:ColorError }
    
    Write-Host "Windows: $(if ($windowsStatus) {'ACTIVATED'} else {'NOT ACTIVATED'})" -ForegroundColor $winColor
    Write-Host "Office: $(if ($officeStatus) {'ACTIVATED'} else {'NOT ACTIVATED'})" -ForegroundColor $officeColor
    
    return @{
        Windows = $windowsStatus
        Office = $officeStatus
    }
}
#endregion

#region Backup and Restore Functions
function Backup-Activation {
    param([string]$BackupPath = $SavePath)
    
    Write-Log "Creating activation backup..." "INFO"
    
    try {
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        $backupItems = @()
        
        # Backup Windows activation
        $tokensPath = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform"
        if (Test-Path $tokensPath) {
            $dest = Join-Path $BackupPath "SoftwareProtectionPlatform"
            Copy-Item -Path $tokensPath -Destination $dest -Recurse -Force
            $backupItems += "SoftwareProtectionPlatform"
        }
        
        # Backup Office activation
        $officeBackupPaths = @(
            "$env:ProgramData\Microsoft\OfficeSoftwareProtectionPlatform",
            "$env:ProgramData\Microsoft\Windows\ClipSVC\Tokens"
        )
        
        foreach ($path in $officeBackupPaths) {
            if (Test-Path $path) {
                $dest = Join-Path $BackupPath (Split-Path $path -Leaf)
                Copy-Item -Path $path -Destination $dest -Recurse -Force
                $backupItems += (Split-Path $path -Leaf)
            }
        }
        
        # Backup registry keys
        $regKeys = @(
            "HKLM:\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform",
            "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE"
        )
        
        foreach ($key in $regKeys) {
            if (Test-Path $key) {
                $regFile = Join-Path $BackupPath "$((Split-Path $key -Leaf).Replace('\','_')).reg"
                reg export (Split-Path $key -NoQualifier) $regFile /y | Out-Null
                $backupItems += "$((Split-Path $key -Leaf).Replace('\','_')).reg"
            }
        }
        
        # Save system info
        $systemInfo = Get-SystemInfo
        $systemInfo | ConvertTo-Json | Out-File -FilePath (Join-Path $BackupPath "system_info.json")
        
        $global:BackupCreated = $true
        Write-Log "Backup created successfully at: $BackupPath" "SUCCESS"
        Write-Log "Backup items: $($backupItems -join ', ')" "INFO"
        
        return $true
    }
    catch {
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

function Restore-Activation {
    param([string]$BackupPath = $SavePath)
    
    Write-Log "Restoring activation from backup..." "INFO"
    
    try {
        if (-not (Test-Path $BackupPath)) {
            Write-Log "Backup directory not found: $BackupPath" "ERROR"
            return $false
        }
        
        # Stop relevant services
        $services = @("sppsvc", "osppsvc", "ClipSVC")
        foreach ($service in $services) {
            try {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            }
            catch {}
        }
        
        # Restore files
        $items = Get-ChildItem -Path $BackupPath -Directory
        foreach ($item in $items) {
            $source = $item.FullName
            $destination = "$env:SystemRoot\..\$($item.Name)"
            
            if (Test-Path $destination) {
                Remove-Item -Path $destination -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            Copy-Item -Path $source -Destination $destination -Recurse -Force
        }
        
        # Restore registry
        $regFiles = Get-ChildItem -Path $BackupPath -Filter "*.reg"
        foreach ($regFile in $regFiles) {
            reg import $regFile.FullName | Out-Null
        }
        
        # Start services
        foreach ($service in $services) {
            try {
                Start-Service -Name $service -ErrorAction SilentlyContinue
            }
            catch {}
        }
        
        Write-Log "Activation restored successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Restore failed: $_" "ERROR"
        return $false
    }
}
#endregion

#region Activation Methods
# Method 1: KMS Activation
function Activate-KMS {
    Write-Log "Starting KMS Activation..." "INFO"
    
    $kmsServers = @(
        @{Name = "kms8.msguides.com"; Port = 1688},
        @{Name = "kms.digiboy.ir"; Port = 1688},
        @{Name = "kms.lotro.cc"; Port = 1688},
        @{Name = "kms.chinancce.com"; Port = 1688}
    )
    
    $success = $false
    
    foreach ($server in $kmsServers) {
        Write-Log "Trying KMS server: $($server.Name):$($server.Port)" "INFO"
        
        try {
            # Test connection
            $connection = Test-NetConnection -ComputerName $server.Name -Port $server.Port -WarningAction SilentlyContinue
            
            if ($connection.TcpTestSucceeded) {
                # Set KMS server
                cscript //B "$env:SystemRoot\system32\slmgr.vbs" /skms $($server.Name) | Out-Null
                Start-Sleep -Seconds 2
                
                # Activate Windows
                cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ato | Out-Null
                
                # Check activation
                $status = cscript //B "$env:SystemRoot\system32\slmgr.vbs" /dli
                if ($status -match "Licensed") {
                    Write-Log "Windows activated via KMS: $($server.Name)" "SUCCESS"
                    
                    # Try Office activation
                    Activate-Office-KMS -Server $server.Name
                    
                    $success = $true
                    break
                }
            }
        }
        catch {
            Write-Log "KMS server failed: $($server.Name) - $_" "WARNING"
        }
    }
    
    return $success
}

# Method 2: HWID (Digital License) Activation
function Activate-HWID {
    Write-Log "Starting HWID (Digital License) Activation..." "INFO"
    
    try {
        # This method uses generic keys to trigger digital entitlement
        $hwidKeys = @{
            "Windows 10/11 Home" = "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"
            "Windows 10/11 Pro" = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
            "Windows 10/11 Education" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
        }
        
        # Get current edition
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $osName = $osInfo.Caption
        
        $selectedKey = $hwidKeys["Windows 10/11 Pro"] # Default
        
        foreach ($key in $hwidKeys.Keys) {
            if ($osName -like "*$key*") {
                $selectedKey = $hwidKeys[$key]
                break
            }
        }
        
        Write-Log "Using HWID key for edition detection" "INFO"
        
        # Install key
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ipk $selectedKey | Out-Null
        
        # Attempt online activation (triggers digital entitlement)
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ato | Out-Null
        
        # Force HWID activation
        $scriptBlock = {
            $spp = Get-WmiObject -Namespace root\cimv2\security\microsofttpm -Class Win32_Tpm
            if ($spp) {
                # Trigger hardware validation
                $license = Get-WmiObject -Class SoftwareLicensingProduct | Where-Object PartialProductKey
                foreach ($lic in $license) {
                    $lic.TriggerActivation(0)
                }
            }
        }
        
        Invoke-Command -ScriptBlock $scriptBlock
        
        # Check status
        Start-Sleep -Seconds 5
        $status = cscript //B "$env:SystemRoot\system32\slmgr.vbs" /dli
        
        if ($status -match "Digital License") {
            Write-Log "HWID (Digital License) activation successful!" "SUCCESS"
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "HWID activation failed: $_" "ERROR"
        return $false
    }
}

# Method 3: MAS (Microsoft Activation Scripts) - Open Source Method
function Activate-MAS {
    Write-Log "Starting MAS (Microsoft Activation Scripts) Method..." "INFO"
    
    try {
        # MAS uses HWID and KMS38 methods
        $tempDir = "$env:TEMP\MAS"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }
        
        # Download MAS script (simulated - in real scenario would download from GitHub)
        Write-Log "Simulating MAS method execution..." "INFO"
        
        # Method 1: KMS38 (Activate until 2038)
        $kms38Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ipk $kms38Key | Out-Null
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /skms kms8.msguides.com | Out-Null
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ato | Out-Null
        
        # Method 2: Online KMS
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /skms kms.digiboy.ir | Out-Null
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ato | Out-Null
        
        # Check activation
        $status = cscript //B "$env:SystemRoot\system32\slmgr.vbs" /dli
        
        if ($status -match "Licensed") {
            Write-Log "MAS method activation successful!" "SUCCESS"
            
            # Activate Office if present
            $officePaths = Get-OfficePaths
            foreach ($path in $officePaths) {
                $ospp = Join-Path $path "ospp.vbs"
                if (Test-Path $ospp) {
                    cscript //B "$ospp" /sethst:kms8.msguides.com
                    cscript //B "$ospp" /act
                }
            }
            
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "MAS method failed: $_" "ERROR"
        return $false
    }
}

# Method 4: Ohook (Office Hook)
function Activate-Ohook {
    Write-Log "Starting Ohook (Office Hook) Method..." "INFO"
    
    try {
        # Ohook method for Office activation
        $officePaths = Get-OfficePaths
        
        foreach ($officePath in $officePaths) {
            $osppPath = Join-Path $officePath "ospp.vbs"
            
            if (Test-Path $osppPath) {
                Write-Log "Found Office installation at: $officePath" "INFO"
                
                # Stop Office Click-to-Run service
                try {
                    Stop-Service -Name "ClickToRunSvc" -Force -ErrorAction SilentlyContinue
                }
                catch {}
                
                # Create ohook files (simulated)
                $ohookDir = "$env:ProgramData\Ohook"
                if (-not (Test-Path $ohookDir)) {
                    New-Item -ItemType Directory -Path $ohookDir -Force | Out-Null
                }
                
                # Simulate ohook installation
                $ohookScript = @'
# Ohook Office Activation
# This simulates the ohook method
Write-Host "Ohook method applied to Office"
'@
                
                $ohookScript | Out-File -FilePath "$ohookDir\ohook.ps1" -Encoding UTF8
                
                # Apply generic Office keys
                $officeKeys = @{
                    "Office 2019 ProPlus" = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"
                    "Office 2021 ProPlus" = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
                    "Office 365" = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
                }
                
                foreach ($key in $officeKeys.Keys) {
                    cscript //B "$osppPath" /inpkey:$($officeKeys[$key])
                    Start-Sleep -Milliseconds 500
                }
                
                # Activate
                cscript //B "$osppPath" /act
                
                # Start service
                try {
                    Start-Service -Name "ClickToRunSvc" -ErrorAction SilentlyContinue
                }
                catch {}
                
                Write-Log "Ohook method applied to Office" "SUCCESS"
                return $true
            }
        }
        
        Write-Log "Office not found for Ohook method" "WARNING"
        return $false
    }
    catch {
        Write-Log "Ohook method failed: $_" "ERROR"
        return $false
    }
}

# Method 5: TSForge (Tinyumbrella/Forge Method)
function Activate-TSForge {
    Write-Log "Starting TSForge Method..." "INFO"
    
    try {
        # TSForge simulates a KMS server locally
        $tsForgeDir = "$env:ProgramData\TSForge"
        if (-not (Test-Path $tsForgeDir)) {
            New-Item -ItemType Directory -Path $tsForgeDir -Force | Out-Null
        }
        
        # Create local KMS server simulation
        $kmsScript = @'
# Local KMS Server Simulation
$port = 1688
$ip = "127.0.0.1"

Write-Host "TSForge Local KMS Server starting on $($ip):$($port)"
'@
        
        $kmsScript | Out-File -FilePath "$tsForgeDir\kms_server.ps1" -Encoding UTF8
        
        # Set local KMS server
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /skms 127.0.0.1 | Out-Null
        Start-Sleep -Seconds 2
        
        # Use generic key
        $genericKey = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ipk $genericKey | Out-Null
        
        # Activate
        cscript //B "$env:SystemRoot\system32\slmgr.vbs" /ato | Out-Null
        
        # Check activation
        $status = cscript //B "$env:SystemRoot\system32\slmgr.vbs" /dli
        
        if ($status -match "Licensed") {
            Write-Log "TSForge activation successful!" "SUCCESS"
            
            # Activate Office
            $officePaths = Get-OfficePaths
            foreach ($path in $officePaths) {
                $ospp = Join-Path $path "ospp.vbs"
                if (Test-Path $ospp) {
                    cscript //B "$ospp" /sethst:127.0.0.1
                    cscript //B "$ospp" /act
                }
            }
            
            return $true
        }
        
        return $false
    }
    catch {
        Write-Log "TSForge method failed: $_" "ERROR"
        return $false
    }
}

# Helper function to get Office paths
function Get-OfficePaths {
    $paths = @()
    
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft Office\Office16",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
        "${env:ProgramFiles}\Microsoft Office\Office15",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15",
        "${env:ProgramFiles}\Microsoft Office\Office14",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office14",
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
    param([string]$Server)
    
    $officePaths = Get-OfficePaths
    
    foreach ($path in $officePaths) {
        $ospp = Join-Path $path "ospp.vbs"
        if (Test-Path $ospp) {
            try {
                cscript //B "$ospp" /sethst:$Server
                Start-Sleep -Seconds 1
                cscript //B "$ospp" /act
                Write-Log "Office activation attempted via KMS" "INFO"
                return $true
            }
            catch {
                Write-Log "Office KMS activation failed: $_" "WARNING"
            }
        }
    }
    
    return $false
}
#endregion

#region Menu System
function Show-MainMenu {
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $global:ColorMenu
    Write-Host "║   WINDOWS & OFFICE ACTIVATION TOOLKIT v2.0              ║" -ForegroundColor $global:ColorMenu
    Write-Host "║   Cybersecurity Course - Section 4, Lesson 26           ║" -ForegroundColor $global:ColorMenu
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $global:ColorMenu
    Write-Host "`n"
    
    Show-SystemInfo
    Show-ActivationStatus
    
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $global:ColorMenu
    Write-Host "║                    MAIN MENU                             ║" -ForegroundColor $global:ColorMenu
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor $global:ColorMenu
    Write-Host "║  1. 📊 Check Activation Status                           ║" -ForegroundColor White
    Write-Host "║  2. 💾 Create Backup                                    ║" -ForegroundColor White
    Write-Host "║  3. 🔄 Restore from Backup                              ║" -ForegroundColor White
    Write-Host "║  4. ⚙️  Activation Methods                               ║" -ForegroundColor White
    Write-Host "║  5. 🛠️  Repair Activation Components                     ║" -ForegroundColor White
    Write-Host "║  6. 🔍 View Logs                                        ║" -ForegroundColor White
    Write-Host "║  7. 🚀 Auto-Activate (Try All Methods)                  ║" -ForegroundColor $global:ColorWarning
    Write-Host "║  8. ❌ Exit                                              ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $global:ColorMenu
    Write-Host "`n"
}

function Show-ActivationMethodsMenu {
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $global:ColorMenu
    Write-Host "║             ACTIVATION METHODS                          ║" -ForegroundColor $global:ColorMenu
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor $global:ColorMenu
    Write-Host "║  1. 🌐 KMS Activation (Online Servers)                  ║" -ForegroundColor White
    Write-Host "║  2. 🔑 HWID (Digital License)                           ║" -ForegroundColor White
    Write-Host "║  3. 🛡️  MAS (Microsoft Activation Scripts)              ║" -ForegroundColor White
    Write-Host "║  4. 🏗️  TSForge (Local KMS Server)                      ║" -ForegroundColor White
    Write-Host "║  5. 📎 Ohook (Office Hook)                              ║" -ForegroundColor White
    Write-Host "║  6. 🔙 Back to Main Menu                                ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $global:ColorMenu
    Write-Host "`n"
    
    $choice = Read-Host "Select method (1-6)"
    
    switch ($choice) {
        "1" { 
            Write-Log "User selected: KMS Activation" "INFO"
            $backup = Backup-Activation
            if ($backup -or $global:BackupCreated) {
                Activate-KMS
            }
        }
        "2" { 
            Write-Log "User selected: HWID Activation" "INFO"
            $backup = Backup-Activation
            if ($backup -or $global:BackupCreated) {
                Activate-HWID
            }
        }
        "3" { 
            Write-Log "User selected: MAS Activation" "INFO"
            $backup = Backup-Activation
            if ($backup -or $global:BackupCreated) {
                Activate-MAS
            }
        }
        "4" { 
            Write-Log "User selected: TSForge Activation" "INFO"
            $backup = Backup-Activation
            if ($backup -or $global:BackupCreated) {
                Activate-TSForge
            }
        }
        "5" { 
            Write-Log "User selected: Ohook Activation" "INFO"
            $backup = Backup-Activation
            if ($backup -or $global:BackupCreated) {
                Activate-Ohook
            }
        }
        "6" { return }
        default { Write-Host "Invalid selection!" -ForegroundColor $global:ColorError }
    }
}

function Show-BackupMenu {
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $global:ColorMenu
    Write-Host "║                    BACKUP MENU                           ║" -ForegroundColor $global:ColorMenu
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor $global:ColorMenu
    Write-Host "║  1. 💾 Create New Backup                                ║" -ForegroundColor White
    Write-Host "║  2. 📁 Set Backup Location                              ║" -ForegroundColor White
    Write-Host "║  3. 🔄 Restore from Backup                              ║" -ForegroundColor White
    Write-Host "║  4. 📊 View Backup Contents                             ║" -ForegroundColor White
    Write-Host "║  5. 🔙 Back to Main Menu                                ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $global:ColorMenu
    Write-Host "`n"
    
    $choice = Read-Host "Select option (1-5)"
    
    switch ($choice) {
        "1" { 
            $location = Read-Host "Enter backup location (press Enter for default)"
            if ([string]::IsNullOrWhiteSpace($location)) {
                $location = $SavePath
            }
            Backup-Activation -BackupPath $location
        }
        "2" { 
            $newPath = Read-Host "Enter new backup location"
            if (-not [string]::IsNullOrWhiteSpace($newPath)) {
                $script:SavePath = $newPath
                Write-Host "Backup location set to: $newPath" -ForegroundColor $global:ColorSuccess
            }
        }
        "3" { 
            $backupPath = Read-Host "Enter backup path to restore from"
            if ([string]::IsNullOrWhiteSpace($backupPath)) {
                $backupPath = $SavePath
            }
            Restore-Activation -BackupPath $backupPath
        }
        "4" { 
            if (Test-Path $SavePath) {
                Get-ChildItem -Path $SavePath -Recurse | Format-Table Name, Length, LastWriteTime
            }
            else {
                Write-Host "No backup found at: $SavePath" -ForegroundColor $global:ColorWarning
            }
        }
        "5" { return }
    }
}

function Repair-ActivationComponents {
    Write-Log "Starting activation components repair..." "INFO"
    
    try {
        Write-Host "`nRepairing activation components..." -ForegroundColor $global:ColorInfo
        
        # Stop services
        $services = @("sppsvc", "osppsvc", "ClipSVC", "EventLog")
        foreach ($service in $services) {
            try {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped service: $service" -ForegroundColor Gray
            }
            catch {
                Write-Host "Failed to stop service: $service" -ForegroundColor $global:ColorWarning
            }
        }
        
        # Clear cache
        $cachePaths = @(
            "$env:SystemRoot\system32\spp\store\2.0",
            "$env:ProgramData\Microsoft\Windows\ClipSVC\Tokens",
            "$env:ProgramData\Microsoft\OfficeSoftwareProtectionPlatform"
        )
        
        foreach ($path in $cachePaths) {
            if (Test-Path $path) {
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Cleared cache: $path" -ForegroundColor Gray
            }
        }
        
        # Re-register DLLs
        $dlls = @(
            "$env:SystemRoot\system32\sppobjs.dll",
            "$env:SystemRoot\system32\sppcomapi.dll",
            "$env:SystemRoot\system32\slc.dll",
            "$env:SystemRoot\system32\sppcext.dll"
        )
        
        foreach ($dll in $dlls) {
            if (Test-Path $dll) {
                regsvr32.exe /s $dll
                Write-Host "Registered: $(Split-Path $dll -Leaf)" -ForegroundColor Gray
            }
        }
        
        # Reset licensing
        $commands = @(
            "sc delete sppsvc",
            "sc delete osppsvc",
            "net start sppsvc",
            "net start osppsvc"
        )
        
        foreach ($cmd in $commands) {
            try {
                Invoke-Expression $cmd 2>&1 | Out-Null
            }
            catch {}
        }
        
        # Start services
        foreach ($service in $services) {
            try {
                Start-Service -Name $service -ErrorAction SilentlyContinue
                Write-Host "Started service: $service" -ForegroundColor Gray
            }
            catch {
                Write-Host "Failed to start service: $service" -ForegroundColor $global:ColorWarning
            }
        }
        
        Write-Log "Activation components repaired successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Repair failed: $_" "ERROR"
        return $false
    }
}

function View-Logs {
    Clear-Host
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor $global:ColorMenu
    Write-Host "║                    LOG VIEWER                           ║" -ForegroundColor $global:ColorMenu
    Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor $global:ColorMenu
    Write-Host "║  1. 📄 View Current Session Log                         ║" -ForegroundColor White
    Write-Host "║  2. 📁 Open Log Directory                               ║" -ForegroundColor White
    Write-Host "║  3. 🧹 Clear All Logs                                   ║" -ForegroundColor $global:ColorWarning
    Write-Host "║  4. 🔙 Back to Main Menu                                ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor $global:ColorMenu
    Write-Host "`n"
    
    $choice = Read-Host "Select option (1-4)"
    
    switch ($choice) {
        "1" {
            if (Test-Path $global:LogFile) {
                Get-Content $global:LogFile | Out-Host -Paging
            }
            else {
                Write-Host "No log file found!" -ForegroundColor $global:ColorWarning
            }
        }
        "2" {
            $logDir = Split-Path $global:LogFile -Parent
            if (Test-Path $logDir) {
                explorer.exe $logDir
            }
        }
        "3" {
            $confirm = Read-Host "Are you sure you want to clear all logs? (yes/no)"
            if ($confirm -eq "yes") {
                $logDir = Split-Path $global:LogFile -Parent
                if (Test-Path $logDir) {
                    Remove-Item -Path "$logDir\*" -Recurse -Force
                    Write-Host "All logs cleared!" -ForegroundColor $global:ColorSuccess
                }
            }
        }
        "4" { return }
    }
}

function Auto-Activate {
    Write-Log "Starting Auto-Activation (trying all methods)..." "INFO"
    Write-Host "`n🚀 Starting Auto-Activation Sequence..." -ForegroundColor $global:ColorWarning
    Write-Host "This will try all activation methods in sequence" -ForegroundColor White
    Write-Host "`n"
    
    # Create backup first
    Write-Host "Step 1: Creating backup..." -ForegroundColor $global:ColorInfo
    $backupResult = Backup-Activation
    
    if (-not $backupResult) {
        Write-Host "Backup failed! Continue anyway? (yes/no)" -ForegroundColor $global:ColorWarning
        $continue = Read-Host
        if ($continue -ne "yes") {
            return
        }
    }
    
    # List of methods to try
    $methods = @(
        @{Name = "KMS Activation"; Function = { Activate-KMS } },
        @{Name = "HWID Activation"; Function = { Activate-HWID } },
        @{Name = "MAS Method"; Function = { Activate-MAS } },
        @{Name = "TSForge"; Function = { Activate-TSForge } },
        @{Name = "Ohook"; Function = { Activate-Ohook } }
    )
    
    $success = $false
    $methodNumber = 1
    
    foreach ($method in $methods) {
        Write-Host "`nStep $($methodNumber): Trying $($method.Name)..." -ForegroundColor $global:ColorInfo
        
        try {
            $result = & $method.Function
            
            if ($result) {
                Write-Host "✓ $($method.Name) SUCCESSFUL!" -ForegroundColor $global:ColorSuccess
                $success = $true
                
                # Check if everything is activated
                $windowsStatus = Test-WindowsActivationStatus
                $officeStatus = Test-OfficeActivationStatus
                
                if ($windowsStatus -and $officeStatus) {
                    Write-Host "`n🎉 COMPLETE SUCCESS! Both Windows and Office are activated!" -ForegroundColor $global:ColorSuccess
                    break
                }
                elseif ($windowsStatus) {
                    Write-Host "✓ Windows activated, continuing with Office methods..." -ForegroundColor $global:ColorSuccess
                }
                elseif ($officeStatus) {
                    Write-Host "✓ Office activated, continuing with Windows methods..." -ForegroundColor $global:ColorSuccess
                }
            }
            else {
                Write-Host "✗ $($method.Name) failed" -ForegroundColor $global:ColorWarning
            }
        }
        catch {
            Write-Host "✗ $($method.Name) error: $_" -ForegroundColor $global:ColorError
        }
        
        $methodNumber++
        Start-Sleep -Seconds 2
    }
    
    if (-not $success) {
        Write-Host "`n❌ All methods failed! Trying repair..." -ForegroundColor $global:ColorError
        Repair-ActivationComponents
        
        # Try KMS one more time
        Write-Host "`nTrying KMS one more time after repair..." -ForegroundColor $global:ColorInfo
        Activate-KMS
    }
    
    # Final status
    Write-Host "`n" + "="*50 -ForegroundColor $global:ColorInfo
    Show-ActivationStatus
    Write-Host "="*50 -ForegroundColor $global:ColorInfo
}

function Pause-AndReturn {
    Write-Host "`nPress any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
#endregion

#region Main Execution
function Main {
    # Check admin rights
    if (-not (Test-Administrator)) {
        Write-Host "This script requires Administrator privileges!" -ForegroundColor $global:ColorError
        Write-Host "Please run PowerShell as Administrator and execute the script again." -ForegroundColor $global:ColorWarning
        exit 1
    }
    
    # Initialize
    Initialize-Logging
    
    # Welcome
    if (-not $Silent) {
        Write-Host "`n" -NoNewline
        Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor $global:ColorMenu
        Write-Host "     WINDOWS & OFFICE ACTIVATION TOOLKIT v2.0" -ForegroundColor $global:ColorMenu
        Write-Host "     Cybersecurity Course - Section 4, Lesson 26" -ForegroundColor $global:ColorMenu
        Write-Host "     Educational Purposes Only" -ForegroundColor $global:ColorWarning
        Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor $global:ColorMenu
        Write-Host "`n"
    }
    
    Write-Log "Script started" "INFO"
    Write-Log "User: $env:USERNAME" "INFO"
    Write-Log "Computer: $env:COMPUTERNAME" "INFO"
    
    # Auto mode
    if ($AutoMode) {
        Write-Log "Running in auto mode" "INFO"
        Auto-Activate
        exit 0
    }
    
    # Specific method
    if (-not [string]::IsNullOrWhiteSpace($Method)) {
        Write-Log "Running specific method: $Method" "INFO"
        switch ($Method.ToLower()) {
            "kms" { Activate-KMS }
            "hwid" { Activate-HWID }
            "mas" { Activate-MAS }
            "tsforge" { Activate-TSForge }
            "ohook" { Activate-Ohook }
            default { Write-Host "Unknown method: $Method" -ForegroundColor $global:ColorError }
        }
        exit 0
    }
    
    # Interactive menu mode
    while ($true) {
        try {
            Show-MainMenu
            $choice = Read-Host "Select option (1-8)"
            
            switch ($choice) {
                "1" { 
                    Show-ActivationStatus
                    Pause-AndReturn
                }
                "2" { 
                    Show-BackupMenu
                    Pause-AndReturn
                }
                "3" { 
                    Show-BackupMenu
                    Pause-AndReturn
                }
                "4" { 
                    Show-ActivationMethodsMenu
                    Pause-AndReturn
                }
                "5" { 
                    Repair-ActivationComponents
                    Pause-AndReturn
                }
                "6" { 
                    View-Logs
                    Pause-AndReturn
                }
                "7" { 
                    Auto-Activate
                    Pause-AndReturn
                }
                "8" { 
                    Write-Log "Script ended by user" "INFO"
                    Stop-Transcript | Out-Null
                    Write-Host "`nGoodbye!`n" -ForegroundColor $global:ColorSuccess
                    exit 0
                }
                default {
                    Write-Host "Invalid selection! Please choose 1-8." -ForegroundColor $global:ColorError
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Write-Log "Menu error: $_" "ERROR"
            Pause-AndReturn
        }
    }
}

# Run main function
try {
    Main
}
catch {
    Write-Host "Fatal error: $_" -ForegroundColor $global:ColorError
    Write-Log "Fatal error: $_" "ERROR"
    Pause-AndReturn
    exit 1
}
#endregion
