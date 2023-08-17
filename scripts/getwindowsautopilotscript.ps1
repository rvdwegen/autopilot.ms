$ProgressPreference = 'SilentlyContinue'
$host.ui.RawUI.WindowTitle = "Autopilot Hash Bootstrap"

$header = @"
                                                
       _         _              _ _       _     ____              _       _                   
      / \  _   _| |_ ___  _ __ (_) | ___ | |_  | __ )  ___   ___ | |_ ___| |_ _ __ __ _ _ __  
     / _ \| | | | __/ _ \| '_ \| | |/ _ \| __| |  _ \ / _ \ / _ \| __/ __| __| '__/ _`  | '_ \ 
    / ___ \ |_| | || (_) | |_) | | | (_) | |_  | |_) | (_) | (_) | |_\__ \ |_| | | (_| | |_) |
   /_/   \_\__,_|\__\___/| .__/|_|_|\___/ \__| |____/ \___/ \___/ \__|___/\__|_|  \__,_| .__/ 
                         |_|                                                           |_|    
                                                 
                                                
                      ============ Autopilot hash bootstrap ============                      
                             Author: https://github.com/rvdwegen
                        Repo: https://github.com/rvdwegen/autopilot.ms

"@

CLS

Write-Host $header

if (!(Get-PackageProvider | Where-Object { $_.Name -eq "NuGet" })) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$FALSE
}

if (!(Get-InstalledScript | Where-Object { $_.Name -eq "Get-WindowsAutopilotInfo" })) {
    Install-Script -Name "Get-WindowsAutopilotInfo" -Force -Confirm:$FALSE
    Write-Host "Get-WindowsAutopilotInfo has been succesfully installed" -ForegroundColor Green
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false
    Write-Host "Executionpolicy has been changed to unrestricted for this process" -ForegroundColor Green
} else {
    Write-Host "Get-WindowsAutopilotInfo has been found" -ForegroundColor Green
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false
    Write-Host "Executionpolicy has been changed to unrestricted for this process" -ForegroundColor Green
}

Write-Host "          "
Write-Host "Command examples:"
Write-Host "          "
Write-Host " - Upload hash directly to tenant (requires admin credentials): Get-WindowsAutopilotInfo -Online"
Write-Host "          "
Write-Host " - Thing: Get-WindowsAutopilotInfo -Online sdfsdfsf"
Write-Host "          "
Write-Host " - Thing2: Get-WindowsAutopilotInfo -Online sfdsfsadfasdfadsa"
Write-Host "          "


