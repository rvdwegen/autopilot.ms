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

function Save-File ([string]$fileName, [string]$folderPath) {
       [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
   
       $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
       $OpenFileDialog.initialDirectory = $folderPath
       $OpenFileDialog.filter = 'JSON (*.json)|*.json'
       $OpenFileDialog.FileName = "$fileName.json"
       $result = $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
   
       if ($result -NE "OK") { throw "Failed to select save location" }
       return [pscustomobject]@{
           path = $OpenFileDialog.filename
           status = $result
       }
}

#endregion

try {
       # Validate tenant
       try {
              $tenant = Read-Host "Please enter the tenantId or a valid domain of the tenant"
              #$tenantId = (Invoke-RestMethod -Method GET "https://login.windows.net/$tenant/.well-known/openid-configuration").token_endpoint.Split('/')[3]
       
              $tenantObj = Invoke-RestMethod -Method GET -Uri "https://api.vdwegen.app/api/reverseTenant?tenant=$($tenant)"
       } catch {
              throw "Tenant $($tenant) could not be found"
       }
} catch {
       throw "Authentication error: $($_.Exception.Message)"
}

try {

  $CloudAssignedAadServerData = @{
      ZeroTouchConfig = @{
          ForcedEnrollment = '1'
          CloudAssignedTenantDomain = $tenantObj.defaultDomainName
          CloudAssignedTenantUpn = '\'
      }
  } | ConvertTo-Json

  $Profile = @{
      Version = 2049
      CloudAssignedTenantId = $tenantObj.tenantId
      CloudAssignedForcedEnrollment = 1
      CloudAssignedDomainJoinMethod = 0
      CloudAssignedAutopilotUpdateDisabled = 1
      CloudAssignedAutopilotUpdateTimeout = 1800000
      CloudAssignedOobeConfig = 1310
      CloudAssignedAadServerData = $CloudAssignedAadServerData
      CloudAssignedTenantDomain = $tenantObj.defaultDomainName
      ZtdCorrelationId = (New-Guid).Guid
      CloudAssignedDeviceName = "%SERIAL%"
      Comment_File = "Profile Default"
  }

} catch {
       throw "Failed to generate Autopilot JSON file: $($_.Exception.Message)"
}

try {
       $saveFilePath = Save-File -fileName "AutoPilotConfigurationFile" -folderPath (Join-Path -Path $env:windir -ChildPath "Provisioning\Autopilot")
       $profile | ConvertTo-Json -Depth 20 | Out-File -FilePath $saveFilePath.Path -Encoding ASCII
} catch {
       throw "Failed to save file: $($_.Exception.Message)"
}
