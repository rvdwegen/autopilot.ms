$ProgressPreference = 'SilentlyContinue'
$host.ui.RawUI.WindowTitle = "Autopilot Hash Bootstrap"

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

try {
    $jsonRaw = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\AutopilotPolicyCache").PolicyJsonCache
    $jsonObject = ConvertFrom-Json -InputObject $jsonRaw
} catch {
    throw "Failed to retrieve Autpilot Cache: $($_.Exception.Message)"
}

try {
    $tenantDetails = Invoke-RestMethod -Method GET -Uri "https://api.vdwegen.app/api/tenantDetails?tenant=$($jsonObject.CloudAssignedTenantId)"
} catch {
    throw "Failed to retrieve tenant details: $($_.Exception.Message)"
}

[pscustomobject]@{
    tenantDisplayName = $tenantDetails.displayName
    tenantId = $tenantDetails.tenantId
    tenantDefaultDomainName = $tenantDetails.defaultDomainName
}