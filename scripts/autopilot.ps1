# Clear terminal and show logo header
Clear-Host
Write-Host $env:logoheader

function Save-File ([string]$filename) {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $OpenFileDialog.initialDirectory = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    $OpenFileDialog.filter = 'CSV (*.csv)|*.csv'
    $OpenFileDialog.FileName = "$filename.csv"
    $result = $OpenFileDialog.ShowDialog()

    return [pscustomobject]@{
        path = $OpenFileDialog.filename
        status = $result
    }
}

try {
    $serialNumber = (Get-CimInstance -Class Win32_BIOS).SerialNumber
    $hardwareHash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData

    $hashFileDetails = [pscustomobject]@{
        "Device Serial Number" = $serialNumber
        "Windows Product ID" = $product
        "Hardware Hash" = $hardwareHash
    }
} catch {
    throw "Unable to gather hash file details: $($_.Exception.Message)"
}

try {
    $savePath = (Save-File -filename $serialNumber)
    if ($savePath.status -eq "OK") {
        $hashFileDetails | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $savePath.path
    
        if (Test-Path -Path $savePath.path) {
            Write-Host "Hash file for device $serialNumber saved to $($savePath.path)" -ForegroundColor Green
        }
    } else {
        throw "No file save location selected"
    }
} catch {
    throw "Unable to save hash file: $($_.Exception.Message)"
}
