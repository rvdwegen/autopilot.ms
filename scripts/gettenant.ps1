# Clear terminal and show logo header
Clear-Host
Write-Host $env:logoheader

# Retrieve details from registry
try {
    $jsonRaw = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\AutopilotPolicyCache").PolicyJsonCache
    $jsonObject = ConvertFrom-Json -InputObject $jsonRaw
} catch {
    throw "Failed to retrieve Autpilot Cache: $($_.Exception.Message)"
}

# Reverse search tenantid to get tenant information
try {
    $tenantDetails = Invoke-RestMethod -Method GET -Uri "https://api.vdwegen.app/api/tenantDetails?tenant=$($jsonObject.CloudAssignedTenantId)"
} catch {
    throw "Failed to retrieve tenant details: $($_.Exception.Message)"
}

# Return details
[pscustomobject]@{
    tenantDisplayName = $tenantDetails.displayName
    tenantId = $tenantDetails.tenantId
    tenantDefaultDomainName = $tenantDetails.defaultDomainName
}