$ProgressPreference = 'SilentlyContinue'
$host.ui.RawUI.WindowTitle = "Autopilot Hash Bootstrap"
CLS

$script = @"
                                                
       _         _              _ _       _     ____              _       _                   
      / \  _   _| |_ ___  _ __ (_) | ___ | |_  | __ )  ___   ___ | |_ ___| |_ _ __ __ _ _ __  
     / _ \| | | | __/ _ \| '_ \| | |/ _ \| __| |  _ \ / _ \ / _ \| __/ __| __| '__/ _`  | '_ \ 
    / ___ \ |_| | || (_) | |_) | | | (_) | |_  | |_) | (_) | (_) | |_\__ \ |_| | | (_| | |_) |
   /_/   \_\__,_|\__\___/| .__/|_|_|\___/ \__| |____/ \___/ \___/ \__|___/\__|_|  \__,_| .__/ 
                         |_|                                                           |_|    
                                                 
                                                
                      ============ Autopilot hash bootstrap ============                      
                                  Author: Roel van der Wegen

"@

Write-Host $script

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Host "Auto-elevating process..."
        #$CommandLine = '-noexit iwr -useb autopilot.ms | iex'
        $CommandLine = '-noexit irm autopilot.ms | iex'
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        exit
}

$ScriptData = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false; irm "https://raw.githubusercontent.com/rvdwegen/autopilot.ms/main/autopilot.ps1" | iex {ENTER}'
$wshell = New-Object -ComObject wscript.shell
$wshell.AppActivate('Autopilot Hash Bootstrap')
$wshell.SendKeys($ScriptData)
