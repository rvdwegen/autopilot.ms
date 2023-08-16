$ProgressPreference = 'SilentlyContinue'
$host.ui.RawUI.WindowTitle = "Autopilot Hash Bootstrap"

function Show-Menu {
    param (
        [string]$Title = 'Autopilot hash menu'
    )
    Clear-Host
    Write-Host $header
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' to export the hash to CSV."
    Write-Host "2: Press '2' to download Get-WindowsAutopilotInfo from the gallery."
    Write-Host "S: Press 'S' to shutdown the device."
    Write-Host "Q: Press 'Q' to quit."
}

Clear-Host

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

Write-Host $header

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Host "Auto-elevating process..."
        $CommandLine = '-noexit irm "https://autopilot.ms/scripts/bootstrap.ps1" | iex'
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        exit
}

#$ScriptData = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false {ENTER}'
#$wshell = New-Object -ComObject wscript.shell
#[void]$wshell.AppActivate('Autopilot Hash Bootstrap')
#$wshell.SendKeys($ScriptData)

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            irm "https://autopilot.ms/scripts/autopilot.ps1" | iex
        } '2' {
            Write-Host "not functional yet"
        } 'S' {
            Stop-Computer -ComputerName localhost
        }
    }
    pause
}
until ($selection -eq 'q')

#irm "https://autopilot.ms/scripts/autopilot.ps1" | iex
