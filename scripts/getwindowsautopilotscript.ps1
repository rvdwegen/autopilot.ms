# Clear terminal and show logo header
Clear-Host
Write-Host $env:logoheader

# Install NuGet if needed
if (!(Get-PackageProvider | Where-Object { $_.Name -eq "NuGet" })) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$FALSE | Out-Null
}

# Install script if needed
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

# Show command examples
Write-Host "          "
Write-Host "Command examples:"
Write-Host "          "
Write-Host " - Upload hash directly to tenant (requires admin credentials): Get-WindowsAutopilotInfo -Online"
Write-Host "          "
Write-Host " - Get help: Get-WindowsAutopilotInfo -?"
Write-Host "          "


