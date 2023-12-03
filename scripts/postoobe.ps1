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
    @('PSWindowsUpdate') | ForEach-Object {
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

# try {
#     $serialNumber = (Get-WmiObject Win32_bios).SerialNumber
#     if ($env:COMPUTERNAME -ne $serialNumber) {
#         $serialNumber | Rename-Computer
#     }
# } catch {
#    throw "$($_.Exception.Message)"
# }

try {
    Write-Host "ATTEMPTING TO INSTALL ALL WINDOWS UPDATES" -ForegroundColor DarkYellow
    Write-Host "THIS MAY TAKE A WHILE..." -ForegroundColor DarkYellow
    Get-WindowsUpdate -Install -AcceptAll -AutoReboot -RecurseCycle 3 -Verbose -Confirm:$false
} catch {
    throw "$($_.Exception.Message)"
}