Write-Host "=== Massive Windows Optimization Script by merybist ==="

Write-Host "`nEnabling Ultimate Performance power plan..."
$guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
powercfg -duplicatescheme $guid
powercfg -setactive $guid

$services = @(
    "Fax",                # Факс
    "PrintSpooler",       # Друк 
    "DiagTrack",          # Телеметрія
    "SysMain",            # Superfetch (Prefetch)
    "XblGameSave",        # Xbox Game Save
    "XboxNetApiSvc",      # Xbox Networking
    "XboxGipSvc",         # Xbox Accessory
    "WSearch",            # Windows Search 
    "MapsBroker",         # Offline Maps
    "SharedAccess",       # Internet Connection Sharing
    "RemoteRegistry"      # Віддалений реєстр
)

foreach ($svc in $services) {
    Write-Host "Disabling service: $svc"
    try {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled
    }
    catch {
        Write-Host "Could not disable $svc: $($_)"
    }
}

Write-Host "`nDisabling background apps..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

Write-Host "`nDisabling Game DVR and Game Bar..."
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0

Write-Host "`nDisabling visual effects..."
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))

Write-Host "`nCleaning temporary files..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Optimization Finished ==="
