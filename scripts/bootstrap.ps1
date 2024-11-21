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

#################

function DrawMenu {
    param ($menuItems, $menuPosition, $Multiselect, $selection)
    $l = $menuItems.length
    for ($i = 0; $i -le $l;$i++) {
		if ($menuItems[$i] -ne $null){
			$item = $menuItems[$i]
			if ($Multiselect)
			{
				if ($selection -contains $i){
					$item = '[x] ' + $item
				}
				else {
					$item = '[ ] ' + $item
				}
			}
			if ($i -eq $menuPosition) {
				Write-Host "> $($item)" -ForegroundColor Green
			} else {
				Write-Host "  $($item)"
			}
		}
    }
}

function Toggle-Selection {
	param ($pos, [array]$selection)
	if ($selection -contains $pos){ 
		$result = $selection | where {$_ -ne $pos}
	}
	else {
		$selection += $pos
		$result = $selection
	}
	$result
}

function Menu {
    param ([array]$menuItems, [switch]$ReturnIndex=$false, [switch]$Multiselect)
    $vkeycode = 0
    $pos = 0
    $selection = @()
    if ($menuItems.Length -gt 0)
	{
		try {
			$startPos = [System.Console]::CursorTop		
			[console]::CursorVisible=$false #prevents cursor flickering
			DrawMenu $menuItems $pos $Multiselect $selection
			While ($vkeycode -ne 13 -and $vkeycode -ne 27) {
				$press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
				$vkeycode = $press.virtualkeycode
				If ($vkeycode -eq 38 -or $press.Character -eq 'k') {$pos--}
				If ($vkeycode -eq 40 -or $press.Character -eq 'j') {$pos++}
				If ($vkeycode -eq 36) { $pos = 0 }
				If ($vkeycode -eq 35) { $pos = $menuItems.length - 1 }
				If ($press.Character -eq ' ') { $selection = Toggle-Selection $pos $selection }
				if ($pos -lt 0) {$pos = 0}
				If ($vkeycode -eq 27) {$pos = $null }
				if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
				if ($vkeycode -ne 27)
				{
					$startPos = [System.Console]::CursorTop - $menuItems.Length
					[System.Console]::SetCursorPosition(0, $startPos)
					DrawMenu $menuItems $pos $Multiselect $selection
				}
			}
		}
		finally {
			[System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
			[console]::CursorVisible = $true
		}
	}
	else {
		$pos = $null
	}

    if ($ReturnIndex -eq $false -and $pos -ne $null)
	{
		if ($Multiselect){
			return $menuItems[$selection]
		}
		else {
			return $menuItems[$pos]
		}
	}
	else 
	{
		if ($Multiselect){
			return $selection
		}
		else {
			return $pos
		}
	}
}

#################

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
                        Menu: https://github.com/chrisseroka/ps-menu

"@

Write-Host $env:logoheader

Write-Host "                                        "
Write-Host "================ $Title ================"
Write-Host "                                        "
Write-Host "        Select your choice below        "

$menuItems = @(
    @(
        "Select to export the hash to CSV.",
        "Select to download Get-WindowsAutopilotInfo from the gallery.",
        "Select to attempt to detect which tenant the current device is registered to."
        "Select to exit."
    )
)

$selection = menu -menuItems $menuItems -ReturnIndex

switch ($selection) {
    '0' {
        Invoke-RestMethod "https://autopilot.ms/scripts/autopilot.ps1" | Invoke-Expression
    } '1' {
        Invoke-RestMethod "https://autopilot.ms/scripts/getwindowsautopilotscript.ps1" | Invoke-Expression
    } '2' {
        Invoke-RestMethod "https://autopilot.ms/scripts/gettenant.ps1" | Invoke-Expression
    } '3' {
        Write-Host "lol"
    }
}

# do {
#     Show-Menu
#     $selection = Read-Host "Please make a selection"
#     switch ($selection) {
#         '1' {
#             Invoke-RestMethod "https://autopilot.ms/scripts/autopilot.ps1" | Invoke-Expression
#         } '2' {
#             Invoke-RestMethod "https://autopilot.ms/scripts/getwindowsautopilotscript.ps1" | Invoke-Expression
#         } '3' {
#             Invoke-RestMethod "https://autopilot.ms/scripts/gettenant.ps1" | Invoke-Expression
#         } 'exit' {
#             $closeMenu = $true
#         }
#     }
# }
# until ($closeMenu)
