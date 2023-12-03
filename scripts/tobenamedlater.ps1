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

Clear-Host

Write-Host $header

try {
       # Change execution policy
       if ((Get-ExecutionPolicy) -ne "Unrestricted") {
              Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false
              Write-Host "Executionpolicy has been changed to unrestricted for this process" -ForegroundColor Green
       }

       # Install PackageProvider NuGet
       if (!(Get-PackageProvider | Where-Object { $_.Name -eq "NuGet" })) {
              Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$FALSE | Out-Null
       }

       # Check & Install requisite modules
       $installedModules = Get-InstalledModule
       Write-Host "Checking modules..."
       @('Microsoft.Graph.Intune', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Authentication','MSAL.PS', 'WindowsAutoPilotIntune') | ForEach-Object {
              try {
                     if ($installedModules.Name -notcontains $($_)) {
                            Install-Module -Name $($_) -Force -Confirm:$FALSE
                            Write-Host "Module $($_) has been installed" -ForegroundColor Green
                     } else {
                            Write-Host "Module $($_) has been found" -ForegroundColor Green
                     }
              } catch {
                     Write-Error "Failed to install/find modules: $($_)"
              }
       }
} catch {
       throw "$($_)"
}

try {
       # Validate tenant
       try {
              $tenant = Read-Host "Please enter the tenantId or a valid domain of the tenant"
              $tenantId = (Invoke-RestMethod -Method GET "https://login.windows.net/$tenant/.well-known/openid-configuration").token_endpoint.Split('/')[3]
       } catch {
              throw "Tenant $($tenant) could not be found"
       }

       Connect-MgGraph -ClientId 'd1ddf0e4-d672-4dae-b554-9d5bdfd93547' -TenantId $tenantId #-NoWelcome
} catch {
       throw "Authentication error: $($_.Exception.Message)"
}

