# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Host "Auto-elevating process..."
        $CommandLine = '-noexit irm "https://autopilot.ms/scripts/bootstrap.ps1" | iex'
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        exit
}

$ProgressPreference = 'SilentlyContinue'
$host.ui.RawUI.WindowTitle = "Autopilot Hash Bootstrap"

function Show-Menu {
    param (
        [string]$Title = 'Autopilot hash menu'
    )
    Clear-Host
    Write-Host $header
    Write-Host "                                        "
    Write-Host "================ $Title ================"
    Write-Host "                                        "
    Write-Host "1: Select '1' to export the hash to CSV."
    Write-Host "                                        "
    Write-Host "2: Select '2' to download Get-WindowsAutopilotInfo from the gallery."
    Write-Host "                                        "
    Write-Host "3: Select '3' to attempt to detect which tenant the current device is registered to."
    Write-Host "                                        "
    Write-Host "Exit: Type 'Exit' to close the menu"
    Write-Host "                                        "
}

Clear-Host

$env:logoheader = @"
                                                
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

Write-Host $env:logoheader

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            Invoke-RestMethod "https://autopilot.ms/scripts/autopilot.ps1" | Invoke-Expression
        } '2' {
            Invoke-RestMethod "https://autopilot.ms/scripts/getwindowsautopilotscript.ps1" | Invoke-Expression
        } '3' {
            Invoke-RestMethod "https://autopilot.ms/scripts/gettenant.ps1" | Invoke-Expression
        } 'exit' {
            $closeMenu = $true
        }
    }
}
until ($closeMenu)
