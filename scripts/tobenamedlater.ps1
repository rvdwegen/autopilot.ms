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

#region

function Save-File ([string]$filename) {
       [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
   
       $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
       $OpenFileDialog.initialDirectory = "C:\Windows\Provisioning\Autopilot"
       $OpenFileDialog.filter = 'JSON (*.json)|*.json'
       $OpenFileDialog.FileName = "$filename.json"
       $result = $OpenFileDialog.ShowDialog()
   
       if ($result -NE "OK") { throw "Failed to select save location" }
       return [pscustomobject]@{
           path = $OpenFileDialog.filename
           status = $result
       }
}

#endregion

try {
       # Change execution policy
       if ((Get-ExecutionPolicy) -ne "Unrestricted") {
              Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false
              Write-Host "Executionpolicy has been changed to unrestricted for this process" -ForegroundColor Green
       }

       # Install PackageProvider NuGet
       try {
              if (!(Get-PackageProvider | Where-Object { $_.Name -eq "NuGet" })) {
                     Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$FALSE | Out-Null
              }
       } catch {
              throw "Failed to find/install NuGet: $($_.Exception.Message)"
       }

       # Check & Install requisite modules
       $installedModules = Get-InstalledModule
       Write-Host "Checking modules..."
       @('Microsoft.Graph.Authentication','Microsoft.Graph.Intune', 'Microsoft.Graph.Groups','Microsoft.Graph.Identity.DirectoryManagement','MSAL.PS', 'WindowsAutoPilotIntune') | ForEach-Object {
              try {
                     if ($installedModules.Name -notcontains $($_)) {
                            Install-Module -Name $($_) -Force -Confirm:$FALSE
                            Write-Host "Module $($_) has been installed" -ForegroundColor Green
                     } else {
                            Write-Host "Module $($_) has been found" -ForegroundColor Green
                     }
              } catch {
                     throw "Failed to install/find module $($_): $($_.Exception.Message)"
              }
       }
} catch {
       throw "$($_.Exception.Message)"
}

try {
       # Validate tenant
       try {
              $tenant = Read-Host "Please enter the tenantId or a valid domain of the tenant"
              $tenantId = (Invoke-RestMethod -Method GET "https://login.windows.net/$tenant/.well-known/openid-configuration").token_endpoint.Split('/')[3]
       } catch {
              throw "Tenant $($tenant) could not be found"
       }

       #Connect-MgGraph -ClientId '1950a258-227b-4e31-a9cf-717495945fc2' -TenantId $tenantId -Scopes "Directory.Read.All DeviceManagementServiceConfig.Read.All" #-NoWelcome # Az
       #Connect-MgGraph -ClientId 'd1ddf0e4-d672-4dae-b554-9d5bdfd93547' -TenantId $tenantId #-NoWelcome # Intune

       $msalTokenSplat = @{
              TenantId = $tenantid
              ClientId = "1950a258-227b-4e31-a9cf-717495945fc2" # OfficeGrip Delegated management app
              UseEmbeddedWebView = $false # Webview2 can't read device compliance
              RedirectUri = 'http://localhost'
          }
      
          $header = @{
              "Authorization"          = (Get-MsalToken @msalTokenSplat -Scopes "offline_access https://graph.microsoft.com/Directory.Read.All https://graph.microsoft.com/DeviceManagementServiceConfig.Read.All" -Verbose).CreateAuthorizationHeader()
              "Content-type"           = "application/json"
              "X-Requested-With"       = "XMLHttpRequest"
              "x-ms-client-request-id" = [guid]::NewGuid()
              "x-ms-correlation-id"    = [guid]::NewGuid()
          }
          $tenantInfo = (Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/organization?`$select=id,displayName,verifiedDomains" -Headers $header).value
          Write-Host "Authenticated to tenant $($tenantInfo.displayName)"
} catch {
       throw "Authentication error: $($_.Exception.Message)"
}

try {
       $tenantId = $tenantInfo.id
       $defaultDomain = ($tenantInfo.verifiedDomains | Where-Object { $_.isDefault -eq $true }).name
       $profile = (Invoke-RestMethod -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles?`filter=(extractHardwareHash eq true)" -Headers $header).value
} catch {
       throw "$($_.Exception.Message)"
}

try {
       $saveFile = Save-File -filename "AutoPilotConfigurationFile"
} catch {

}