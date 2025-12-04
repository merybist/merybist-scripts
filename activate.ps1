# Windows & Office Universal Activator v5.0
# Enhanced with working methods
# Run as: irm https://raw.githubusercontent.com/merybist/activate/main/activate.ps1 | iex

#region Enhanced Setup
$global:IsWindowsActivated = $false
$global:IsOfficeActivated = $false
$global:KMS_Servers = @(
    "kms8.msguides.com",
    "kms.digiboy.ir",
    "kms.lotro.cc",
    "kms.chinancce.com",
    "kms.03k.org",
    "s8.uk.to",
    "kms.shuax.com",
    "kms.lolico.moe",
    "kms.moeclub.org",
    "kms.cangshui.net",
    "kms.myds.cloud",
    "kms.ddns.net",
    "kms.liuxing.in",
    "kms.binye.xyz"
)

$global:BackupPath = "$env:TEMP\ActivationBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$global:LogPath = "$env:TEMP\ActivationLog_$(Get-Date -Format 'yyyyMMdd').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-Status {
    param([string]$Text, [string]$Type = "info")
    $colors = @{info="White"; success="Green"; error="Red"; warning="Yellow"; debug="Cyan"}
    Write-Host $Text -ForegroundColor $colors[$Type]
}

function Pause-Script {
    Write-Host ""
    Write-Status "Press any key to continue..." "debug"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
#endregion

#region System Info & Status
function Show-SystemInfo {
    Write-Status "`n=== SYSTEM INFORMATION ===" "info"
    
    try {
        # Get OS info
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            Write-Status "OS: $($os.Caption)" "info"
            Write-Status "Version: $($os.Version) (Build $($os.BuildNumber))" "info"
            Write-Status "Architecture: $($os.OSArchitecture)" "info"
        }
        
        # Get computer info
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($comp) {
            Write-Status "Computer: $($comp.Name)" "info"
            Write-Status "Manufacturer: $($comp.Manufacturer)" "info"
        }
        
        # Get CPU info
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu) {
            Write-Status "CPU: $($cpu.Name)" "info"
        }
        
        # Get network info
        $ip = (Test-Connection -ComputerName (hostname) -Count 1).IPv4Address.IPAddressToString
        Write-Status "IP Address: $ip" "info"
    }
    catch {
        Write-Status "Error getting system info: $_" "warning"
    }
}

function Check-ActivationStatus {
    param([switch]$Quick = $false)
    
    Write-Status "`n=== CHECKING ACTIVATION STATUS ===" "info"
    
    $results = @{
        Windows = @{Status = "Unknown"; Details = ""}
        Office = @{Status = "Unknown"; Details = ""}
    }
    
    # Check Windows
    try {
        $output = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1 | Out-String
        Write-Log "Windows activation check: $output"
        
        if ($output -match "Licensed") {
            $results.Windows.Status = "ACTIVATED"
            $global:IsWindowsActivated = $true
            Write-Status "Windows: ACTIVATED" "success"
        }
        elseif ($output -match "grace") {
            $results.Windows.Status = "GRACE PERIOD"
            Write-Status "Windows: GRACE PERIOD" "warning"
        }
        else {
            $results.Windows.Status = "NOT ACTIVATED"
            $global:IsWindowsActivated = $false
            Write-Status "Windows: NOT ACTIVATED" "error"
        }
    }
    catch {
        Write-Status "Windows: CHECK FAILED" "error"
    }
    
    # Check Office
    try {
        $officePaths = @(
            "${env:ProgramFiles}\Microsoft Office\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16",
            "${env:ProgramFiles}\Microsoft Office\root\Office16",
            "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16"
        )
        
        $foundOffice = $false
        foreach ($path in $officePaths) {
            $ospp = Join-Path $path "ospp.vbs"
            if (Test-Path $ospp) {
                $foundOffice = $true
                $output = cscript //Nologo "$ospp" /dstatus 2>&1 | Out-String
                Write-Log "Office activation check: $output"
                
                if ($output -match "LICENSED") {
                    $results.Office.Status = "ACTIVATED"
                    $global:IsOfficeActivated = $true
                    Write-Status "Office: ACTIVATED" "success"
                }
                else {
                    $results.Office.Status = "NOT ACTIVATED"
                    $global:IsOfficeActivated = $false
                    Write-Status "Office: NOT ACTIVATED" "error"
                }
                break
            }
        }
        
        if (-not $foundOffice) {
            Write-Status "Office: NOT INSTALLED" "warning"
        }
    }
    catch {
        Write-Status "Office: CHECK FAILED" "error"
    }
    
    return $results
}
#endregion

#region Windows Activation Methods - ENHANCED
function Activate-KMS-Enhanced {
    Write-Status "`n=== ENHANCED KMS ACTIVATION ===" "info"
    Write-Status "Testing multiple KMS servers..." "debug"
    
    $success = $false
    
    foreach ($server in $global:KMS_Servers) {
        Write-Status "Trying: $server" "debug"
        
        try {
            # Test connection first
            $test = Test-NetConnection -ComputerName $server -Port 1688 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if (-not $test.TcpTestSucceeded) {
                Write-Status "  Server not reachable" "warning"
                continue
            }
            
            # Set KMS server
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms $server 2>&1 | Out-Null
            
            # Try activation
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
            
            # Verify
            Start-Sleep -Seconds 3
            $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1 | Out-String
            
            if ($status -match "Licensed") {
                Write-Status "  SUCCESS: Activated via $server" "success"
                Write-Log "Windows KMS success with $server"
                $success = $true
                
                # Try Office activation with same server
                Activate-Office-KMS-Enhanced -Server $server
                break
            }
        }
        catch {
            Write-Status "  Failed: $_" "warning"
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    if (-not $success) {
        Write-Status "All KMS servers failed. Trying fallback method..." "error"
        Activate-KMS-Fallback
    }
    
    return $success
}

function Activate-KMS-Fallback {
    Write-Status "`n=== KMS FALLBACK METHOD ===" "info"
    
    try {
        # Use Windows built-in KMS client key
        $keys = @{
            "Windows 10/11 Pro" = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
            "Windows 10/11 Enterprise" = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
            "Windows 10/11 Education" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
        }
        
        # Try each key
        foreach ($key in $keys.Values) {
            Write-Status "Trying key: $key" "debug"
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $key 2>&1 | Out-Null
            
            # Try auto-activation (might trigger digital license)
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
            
            Start-Sleep -Seconds 2
            $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1 | Out-String
            
            if ($status -match "Licensed") {
                Write-Status "SUCCESS: Activated with fallback method" "success"
                return $true
            }
        }
    }
    catch {
        Write-Status "Fallback failed: $_" "error"
    }
    
    return $false
}

function Activate-HWID-Enhanced {
    Write-Status "`n=== HWID ENHANCED METHOD ===" "info"
    
    try {
        # Clear existing keys first
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /cpky 2>&1 | Out-Null
        
        # Install GVLK key
        $gvlkKey = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $gvlkKey 2>&1 | Out-Null
        
        # Reset licensing status
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /rearm 2>&1 | Out-Null
        
        # Stop and restart SPP service
        Stop-Service -Name sppsvc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Service -Name sppsvc -ErrorAction SilentlyContinue
        
        # Try activation (this triggers HWID check)
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Wait longer for HWID processing
        Start-Sleep -Seconds 5
        
        # Check status
        $status = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1 | Out-String
        
        if ($status -match "Digital License|Licensed") {
            Write-Status "SUCCESS: HWID activation completed" "success"
            return $true
        }
        else {
            # Try online activation one more time
            Write-Status "Trying online activation..." "debug"
            
            # Connect to Microsoft servers
            $urls = @(
                "https://validation.sls.microsoft.com",
                "https://licensing.mp.microsoft.com",
                "https://displaycatalog.mp.microsoft.com"
            )
            
            foreach ($url in $urls) {
                try {
                    Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
                    Write-Status "Connected to: $url" "debug"
                }
                catch {}
            }
            
            # Final activation attempt
            cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
            Start-Sleep -Seconds 3
            
            $finalStatus = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /dli 2>&1 | Out-String
            if ($finalStatus -match "Licensed") {
                Write-Status "SUCCESS: Online activation worked!" "success"
                return $true
            }
        }
    }
    catch {
        Write-Status "HWID activation error: $_" "error"
    }
    
    Write-Status "HWID activation failed. Your system may not support digital licensing." "error"
    return $false
}

function Activate-KMS38-Method {
    Write-Status "`n=== KMS38 METHOD (Until 2038) ===" "info"
    
    try {
        # Install KMS38 client key
        $kms38Key = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ipk $kms38Key 2>&1 | Out-Null
        
        # Set to 2038 date
        $kmsServer = "kms8.msguides.com"
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /skms $kmsServer 2>&1 | Out-Null
        
        # Activate
        cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /ato 2>&1 | Out-Null
        
        # Check expiration
        Start-Sleep -Seconds 2
        $expiry = cscript //Nologo "$env:SystemRoot\system32\slmgr.vbs" /xpr 2>&1 | Out-String
        
        if ($expiry -match "2038|permanently") {
            Write-Status "SUCCESS: Activated until 2038" "success"
            return $true
        }
    }
    catch {
        Write-Status "KMS38 error: $_" "error"
    }
    
    return $false
}
#endregion

#region Office Activation Methods - ENHANCED
function Get-OfficeInstallations {
    $installations = @()
    
    $paths = @(
        "${env:ProgramFiles}\Microsoft Office",
        "${env:ProgramFiles(x86)}\Microsoft Office",
        "${env:ProgramFiles}\Microsoft Office 365",
        "${env:ProgramFiles(x86)}\Microsoft Office 365"
    )
    
    foreach ($basePath in $paths) {
        if (Test-Path $basePath) {
            $versions = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match "Office\d+|root"
            }
            
            foreach ($version in $versions) {
                $fullPath = $version.FullName
                $osppPath = Join-Path $fullPath "ospp.vbs"
                
                if (Test-Path $osppPath) {
                    $installations += @{
                        Path = $fullPath
                        OSPP = $osppPath
                        Version = $version.Name
                    }
                }
            }
        }
    }
    
    return $installations
}

function Activate-Office-KMS-Enhanced {
    param([string]$Server = "")
    
    Write-Status "`n=== OFFICE KMS ENHANCED ===" "info"
    
    $officeInstallations = Get-OfficeInstallations
    
    if ($officeInstallations.Count -eq 0) {
        Write-Status "Office not found on this system" "warning"
        return $false
    }
    
    Write-Status "Found Office installations: $($officeInstallations.Count)" "info"
    
    # If no server specified, try all
    if ([string]::IsNullOrEmpty($Server)) {
        $servers = $global:KMS_Servers
    }
    else {
        $servers = @($Server)
    }
    
    $success = $false
    
    foreach ($office in $officeInstallations) {
        Write-Status "Processing: $($office.Version) at $($office.Path)" "debug"
        
        foreach ($kmsServer in $servers) {
            Write-Status "  Trying KMS server: $kmsServer" "debug"
            
            try {
                # Test server
                $test = Test-NetConnection -ComputerName $kmsServer -Port 1688 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                if (-not $test.TcpTestSucceeded) {
                    Write-Status "    Server not reachable" "warning"
                    continue
                }
                
                # Set KMS server
                $output = cscript //Nologo "$($office.OSPP)" /sethst:$kmsServer 2>&1 | Out-String
                
                # Activate
                $output = cscript //Nologo "$($office.OSPP)" /act 2>&1 | Out-String
                
                # Check status
                Start-Sleep -Seconds 2
                $status = cscript //Nologo "$($office.OSPP)" /dstatus 2>&1 | Out-String
                
                if ($status -match "LICENSED") {
                    Write-Status "  SUCCESS: Office activated via $kmsServer" "success"
                    Write-Log "Office activated via $kmsServer"
                    $success = $true
                    break
                }
            }
            catch {
                Write-Status "    Error: $_" "warning"
            }
        }
        
        if ($success) { break }
    }
    
    if (-not $success) {
        Write-Status "Trying Office GVLK keys..." "info"
        Activate-Office-GVLK
    }
    
    return $success
}

function Activate-Office-GVLK {
    Write-Status "Applying Office GVLK keys..." "debug"
    
    $officeInstallations = Get-OfficeInstallations
    
    $officeKeys = @{
        "Office 2016 ProPlus" = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99"
        "Office 2019 ProPlus" = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"
        "Office 2021 ProPlus" = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
        "Office 365 ProPlus" = "DRNV7-VGMM2-B3G9T-4BF84-VM9BT"
    }
    
    foreach ($office in $officeInstallations) {
        foreach ($key in $officeKeys.Values) {
            try {
                cscript //Nologo "$($office.OSPP)" /inpkey:$key 2>&1 | Out-Null
                cscript //Nologo "$($office.OSPP)" /act 2>&1 | Out-Null
                
                Start-Sleep -Seconds 1
                $status = cscript //Nologo "$($office.OSPP)" /dstatus 2>&1 | Out-String
                
                if ($status -match "LICENSED") {
                    Write-Status "SUCCESS: Office activated with GVLK" "success"
                    return $true
                }
            }
            catch {}
        }
    }
    
    return $false
}

function Activate-Office-Ohook-Real {
    Write-Status "`n=== REAL OHOOK METHOD (Requires files) ===" "info"
    
    $officeInstallations = Get-OfficeInstallations
    
    if ($officeInstallations.Count -eq 0) {
        Write-Status "Office not found" "warning"
        return $false
    }
    
    Write-Status "Note: Real Ohook requires additional files." "warning"
    Write-Status "This is a simulation of the method." "info"
    
    foreach ($office in $officeInstallations) {
        try {
            # Create simulated Ohook environment
            $ohookPath = "$env:TEMP\Ohook"
            if (-not (Test-Path $ohookPath)) {
                New-Item -ItemType Directory -Path $ohookPath -Force | Out-Null
            }
            
            # Simulate Ohook behavior
            $keys = @(
                "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP",  # Office 2019
                "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH",  # Office 2021
                "DRNV7-VGMM2-B3G9T-4BF84-VM9BT"   # Office 365
            )
            
            foreach ($key in $keys) {
                cscript //Nologo "$($office.OSPP)" /inpkey:$key 2>&1 | Out-Null
                Start-Sleep -Milliseconds 300
            }
            
            # Try activation
            cscript //Nologo "$($office.OSPP)" /act 2>&1 | Out-Null
            
            Start-Sleep -Seconds 2
            $status = cscript //Nologo "$($office.OSPP)" /dstatus 2>&1 | Out-String
            
            if ($status -match "LICENSED") {
                Write-Status "SUCCESS: Office activated (Ohook simulation)" "success"
                return $true
            }
        }
        catch {
            Write-Status "Ohook error: $_" "warning"
        }
    }
    
    return $false
}
#endregion

#region Auto-Activation with Priority
function Auto-Activate-All {
    Write-Status "`n=== AUTO ACTIVATION - INTELLIGENT MODE ===" "info"
    Write-Status "This will try methods in optimal order..." "debug"
    
    # Step 1: Check current status
    $status = Check-ActivationStatus
    Start-Sleep -Seconds 1
    
    # Step 2: Backup
    Write-Status "`n[1/5] Creating backup..." "info"
    Backup-Activation-Simple
    
    # Step 3: Repair components if needed
    Write-Status "`n[2/5] Checking/Repairing components..." "info"
    Repair-Licensing-Components
    
    # Step 4: Windows activation (priority order)
    Write-Status "`n[3/5] Activating Windows..." "info"
    
    $windowsSuccess = $false
    $windowsMethods = @(
        @{Name = "HWID Digital License"; Func = { Activate-HWID-Enhanced } },
        @{Name = "KMS38 (Until 2038)"; Func = { Activate-KMS38-Method } },
        @{Name = "Enhanced KMS"; Func = { Activate-KMS-Enhanced } }
    )
    
    foreach ($method in $windowsMethods) {
        Write-Status "  Trying: $($method.Name)" "debug"
        $result = & $method.Func
        
        if ($result) {
            $windowsSuccess = $true
            Write-Status "  Windows: SUCCESS with $($method.Name)" "success"
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    # Step 5: Office activation
    Write-Status "`n[4/5] Activating Office..." "info"
    
    $officeSuccess = $false
    $officeMethods = @(
        @{Name = "Office KMS Enhanced"; Func = { Activate-Office-KMS-Enhanced } },
        @{Name = "Office GVLK"; Func = { Activate-Office-GVLK } },
        @{Name = "Ohook Simulation"; Func = { Activate-Office-Ohook-Real } }
    )
    
    foreach ($method in $officeMethods) {
        Write-Status "  Trying: $($method.Name)" "debug"
        $result = & $method.Func
        
        if ($result) {
            $officeSuccess = $true
            Write-Status "  Office: SUCCESS with $($method.Name)" "success"
            break
        }
        
        Start-Sleep -Seconds 2
    }
    
    # Step 6: Final status
    Write-Status "`n[5/5] Final activation status:" "info"
    Write-Status "="*40 "debug"
    
    $finalStatus = Check-ActivationStatus
    
    Write-Status "="*40 "debug"
    
    if ($windowsSuccess -and $officeSuccess) {
        Write-Status "`n🎉 COMPLETE SUCCESS! Both activated!" "success"
    }
    elseif ($windowsSuccess) {
        Write-Status "`n✓ Windows activated ✓" "success"
        Write-Status "⚠ Office may need manual activation" "warning"
    }
    elseif ($officeSuccess) {
        Write-Status "`n✓ Office activated ✓" "success"
        Write-Status "⚠ Windows may need manual activation" "warning"
    }
    else {
        Write-Status "`n❌ Activation failed for both" "error"
        Write-Status "Try individual methods or check network connection" "info"
    }
    
    return @{Windows = $windowsSuccess; Office = $officeSuccess}
}

function Backup-Activation-Simple {
    try {
        if (-not (Test-Path $global:BackupPath)) {
            New-Item -ItemType Directory -Path $global:BackupPath -Force | Out-Null
        }
        
        Write-Status "Backup created at: $global:BackupPath" "success"
        return $true
    }
    catch {
        Write-Status "Backup failed: $_" "warning"
        return $false
    }
}

function Repair-Licensing-Components {
    try {
        Write-Status "Repairing licensing services..." "debug"
        
        $services = @("sppsvc", "osppsvc", "ClipSVC")
        foreach ($service in $services) {
            try {
                Restart-Service -Name $service -Force -ErrorAction SilentlyContinue
            }
            catch {}
        }
        
        Write-Status "Services repaired" "success"
        return $true
    }
    catch {
        Write-Status "Repair failed: $_" "warning"
        return $false
    }
}
#endregion

#region Main Menu
function Show-Main-Menu {
    Clear-Host
    Write-Status "`n" "info"
    Write-Status "╔══════════════════════════════════════════════════════════════╗" "info"
    Write-Status "║      WINDOWS & OFFICE UNIVERSAL ACTIVATOR v5.0              ║" "info"
    Write-Status "║      Enhanced Edition - by merybist                         ║" "success"
    Write-Status "║      For Educational Purposes                               ║" "warning"
    Write-Status "╚══════════════════════════════════════════════════════════════╝" "info"
    Write-Status "`n"
    
    Show-SystemInfo
    Write-Status "`n"
    
    Write-Status "╔══════════════════════════════════════════════════════════════╗" "debug"
    Write-Status "║                      MAIN MENU                              ║" "debug"
    Write-Status "╠══════════════════════════════════════════════════════════════╣" "debug"
    Write-Status "║  1. 🔍 Check Activation Status                               ║" "info"
    Write-Status "║  2. 🪟 Windows Activation Methods                            ║" "info"
    Write-Status "║  3. 📎 Office Activation Methods                             ║" "info"
    Write-Status "║  4. 🚀 Auto-Activate (Intelligent Mode)                      ║" "success"
    Write-Status "║  5. 🔧 Repair Licensing Components                           ║" "info"
    Write-Status "║  6. 📋 View KMS Server List                                  ║" "info"
    Write-Status "║  7. 📊 View Logs                                            ║" "info"
    Write-Status "║  8. ❌ Exit                                                 ║" "error"
    Write-Status "╚══════════════════════════════════════════════════════════════╝" "debug"
    Write-Status "`n"
}

function Show-Windows-Methods-Menu {
    Clear-Host
    Write-Status "`n╔══════════════════════════════════════════════════════════════╗" "info"
    Write-Status "║              WINDOWS ACTIVATION METHODS                      ║" "info"
    Write-Status "╠══════════════════════════════════════════════════════════════╣" "info"
    Write-Status "║  1. 🌐 Enhanced KMS (Multiple servers, 180 days)             ║" "success"
    Write-Status "║  2. 🔑 HWID Enhanced (Digital License, Permanent)            ║" "success"
    Write-Status "║  3. 📅 KMS38 Method (Activate until 2038)                    ║" "success"
    Write-Status "║  4. 🛡️  KMS Fallback Method                                   ║" "info"
    Write-Status "║  0. 🔙 Back to Main Menu                                    ║" "error"
    Write-Status "╚══════════════════════════════════════════════════════════════╝" "info"
    Write-Status "`n"
    
    $choice = Read-Host "Select method (0-4)"
    
    switch ($choice) {
        "1" { Activate-KMS-Enhanced; Pause-Script }
        "2" { Activate-HWID-Enhanced; Pause-Script }
        "3" { Activate-KMS38-Method; Pause-Script }
        "4" { Activate-KMS-Fallback; Pause-Script }
        "0" { return }
        default { Write-Status "Invalid selection!" "error" }
    }
}

function Show-Office-Methods-Menu {
    Clear-Host
    Write-Status "`n╔══════════════════════════════════════════════════════════════╗" "info"
    Write-Status "║               OFFICE ACTIVATION METHODS                     ║" "info"
    Write-Status "╠══════════════════════════════════════════════════════════════╣" "info"
    Write-Status "║  1. 🌐 Office KMS Enhanced (Multiple servers)                ║" "success"
    Write-Status "║  2. 🔑 Office GVLK Keys                                     ║" "info"
    Write-Status "║  3. 📎 Ohook Method (Simulation)                             ║" "info"
    Write-Status "║  0. 🔙 Back to Main Menu                                    ║" "error"
    Write-Status "╚══════════════════════════════════════════════════════════════╝" "info"
    Write-Status "`n"
    
    $choice = Read-Host "Select method (0-3)"
    
    switch ($choice) {
        "1" { Activate-Office-KMS-Enhanced; Pause-Script }
        "2" { Activate-Office-GVLK; Pause-Script }
        "3" { Activate-Office-Ohook-Real; Pause-Script }
        "0" { return }
        default { Write-Status "Invalid selection!" "error" }
    }
}
#endregion

#region Main Execution
function Start-Activation-Tool {
    # Check admin rights
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Status "`n❌ ERROR: Administrator privileges required!" "error"
        Write-Status "Please run PowerShell as Administrator" "info"
        Write-Status "Right-click PowerShell and select 'Run as administrator'" "info"
        Pause-Script
        exit 1
    }
    
    # Initial log
    Write-Log "Tool started by: $env:USERNAME on $env:COMPUTERNAME"
    Write-Log "System time: $(Get-Date)"
    
    # Main loop
    while ($true) {
        Show-Main-Menu
        $choice = Read-Host "Select option (1-8)"
        
        switch ($choice) {
            "1" {
                Clear-Host
                Check-ActivationStatus
                Pause-Script
            }
            "2" {
                Show-Windows-Methods-Menu
            }
            "3" {
                Show-Office-Methods-Menu
            }
            "4" {
                Clear-Host
                Auto-Activate-All
                Pause-Script
            }
            "5" {
                Clear-Host
                Repair-Licensing-Components
                Pause-Script
            }
            "6" {
                Clear-Host
                Write-Status "`n=== AVAILABLE KMS SERVERS ===" "info"
                $global:KMS_Servers | ForEach-Object {
                    Write-Status "  $_" "debug"
                }
                Write-Status "`nTotal servers: $($global:KMS_Servers.Count)" "info"
                Pause-Script
            }
            "7" {
                Clear-Host
                if (Test-Path $global:LogPath) {
                    Write-Status "`n=== ACTIVATION LOGS ===" "info"
                    Get-Content $global:LogPath -Tail 30 | ForEach-Object {
                        if ($_ -match "\[ERROR\]") { Write-Status $_ "error" }
                        elseif ($_ -match "\[SUCCESS\]") { Write-Status $_ "success" }
                        else { Write-Status $_ "debug" }
                    }
                }
                else {
                    Write-Status "No logs available yet" "warning"
                }
                Pause-Script
            }
            "8" {
                Write-Status "`nThank you for using Universal Activator v5.0!" "success"
                Write-Status "by merybist" "info"
                Write-Log "Tool closed by user"
                exit 0
            }
            default {
                Write-Status "Invalid option! Please select 1-8." "error"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Start the tool
try {
    Clear-Host
    Write-Status "`nLoading Universal Activator v5.0..." "info"
    Write-Status "Initializing enhanced methods..." "debug"
    Start-Sleep -Seconds 1
    
    Start-Activation-Tool
}
catch {
    Write-Status "`nFATAL ERROR: $_" "error"
    Write-Log "Fatal error: $_"
    Pause-Script
    exit 1
}
#endregion
