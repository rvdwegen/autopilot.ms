#region functions

function New-ISOFile {
    <#
    .SYNOPSIS
        Create an ISO file from a source folder.

    .DESCRIPTION
        Create an ISO file from a source folder.
        Optionally speicify a boot image and media type.

        This version by Alistair M. of https://thedotsource.com/

        Based on original function by Chris Wu.
        https://gallery.technet.microsoft.com/scriptcenter/New-ISOFile-function-a8deeffd (link appears to be no longer valid.)

        Changes:
            - Updated to work with PowerShell 7
            - Added a bit more error handling and verbose output.
            - Features removed to simplify code:
                * Clipboard support.
                * Pipeline input.

    .PARAMETER source
        The source folder to add to the ISO.

    .PARAMETER destinationIso
        The ISO file to create.

    .PARAMETER bootFile
        Optional. Boot file to add to the ISO.

    .PARAMETER media
        Optional. The media type of the resulting ISO (BDR, CDR etc). Defaults to DVDPLUSRW_DUALLAYER.

    .PARAMETER title
        Optional. Title of the ISO file. Defaults to "untitled".

    .PARAMETER force
        Optional. Force overwrite of an existing ISO file.

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        New-ISOFile -source c:\forIso\ -destinationIso C:\ISOs\testiso.iso

        Simple example. Create testiso.iso with the contents from c:\forIso

    .EXAMPLE
        New-ISOFile -source f:\ -destinationIso C:\ISOs\windowsServer2019Custom.iso -bootFile F:\efi\microsoft\boot\efisys.bin -title "Windows2019"

        Example building Windows media. Add the contents of f:\ to windowsServer2019Custom.iso. Use efisys.bin to make the disc bootable.

    .LINK

    .NOTES
        01           Alistair McNair          Initial version.

    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Low")]
    Param
    (
        [parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [string]$source,
        [parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [string]$destinationIso,
        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$bootFile = $null,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [ValidateSet("CDR","CDRW","DVDRAM","DVDPLUSR","DVDPLUSRW","DVDPLUSR_DUALLAYER","DVDDASHR","DVDDASHRW","DVDDASHR_DUALLAYER","DISK","DVDPLUSRW_DUALLAYER","BDR","BDRE")]
        [string]$media = "DVDPLUSRW_DUALLAYER",
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$title = "untitled",
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [switch]$force
      )

    begin {

        Write-Verbose ("Function start.")

    } # begin

    process {

        Write-Verbose ("Processing nested system " + $vmName)

        ## Set type definition
        Write-Verbose ("Adding ISOFile type.")

        $typeDefinition = @'
        public class ISOFile  {
            public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks) {
                int bytes = 0;
                byte[] buf = new byte[BlockSize];
                var ptr = (System.IntPtr)(&bytes);
                var o = System.IO.File.OpenWrite(Path);
                var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;

                if (o != null) {
                    while (TotalBlocks-- > 0) {
                        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);
                    }

                    o.Flush(); o.Close();
                }
            }
        }
'@

        ## Create type ISOFile, if not already created. Different actions depending on PowerShell version
        if (!('ISOFile' -as [type])) {

            ## Add-Type works a little differently depending on PowerShell version.
            ## https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type
            switch ($PSVersionTable.PSVersion.Major) {

                ## 7 and (hopefully) later versions
                {$_ -ge 7} {
                    Write-Verbose ("Adding type for PowerShell 7 or later.")
                    Add-Type -CompilerOptions "/unsafe" -TypeDefinition $typeDefinition
                } # PowerShell 7

                ## 5, and only 5. We aren't interested in previous versions.
                5 {
                    Write-Verbose ("Adding type for PowerShell 5.")
                    $compOpts = New-Object System.CodeDom.Compiler.CompilerParameters
                    $compOpts.CompilerOptions = "/unsafe"

                    Add-Type -CompilerParameters $compOpts -TypeDefinition $typeDefinition
                } # PowerShell 5

                default {
                    ## If it's not 7 or later, and it's not 5, then we aren't doing it.
                    throw ("Unsupported PowerShell version.")

                } # default

            } # switch

        } # if


        ## Add boot file to image
        if ($bootFile) {

            Write-Verbose ("Optional boot file " + $bootFile + " has been specified.")

            ## Display warning if Blu Ray media is used with a boot file.
            ## Not sure why this doesn't work.
            if(@('BDR','BDRE') -contains $media) {
                    Write-Warning ("Selected boot image may not work with BDR/BDRE media types.")
            } # if

            if (!(Test-Path -Path $bootFile)) {
                throw ($bootFile + " is not valid.")
            } # if

            ## Set stream type to binary and load in boot file
            Write-Verbose ("Loading boot file.")

            try {
                $stream = New-Object -ComObject ADODB.Stream -Property @{Type=1} -ErrorAction Stop
                $stream.Open()
                $stream.LoadFromFile((Get-Item -LiteralPath $bootFile).Fullname)

                Write-Verbose ("Boot file loaded.")
            } # try
            catch {
                throw ("Failed to open boot file. " + $_.exception.message)
            } # catch


            ## Apply the boot image
            Write-Verbose ("Applying boot image.")

            try {
                $boot = New-Object -ComObject IMAPI2FS.BootOptions -ErrorAction Stop
                $boot.AssignBootImage($stream)

                Write-Verbose ("Boot image applied.")
            } # try
            catch {
                throw ("Failed to apply boot file. " + $_.exception.message)
            } # catch


            Write-Verbose ("Boot file applied.")

        }  # if

        ## Build array of media types
        $mediaType = @(
            "UNKNOWN",
            "CDROM",
            "CDR",
            "CDRW",
            "DVDROM",
            "DVDRAM",
            "DVDPLUSR",
            "DVDPLUSRW",
            "DVDPLUSR_DUALLAYER",
            "DVDDASHR",
            "DVDDASHRW",
            "DVDDASHR_DUALLAYER",
            "DISK",
            "DVDPLUSRW_DUALLAYER",
            "HDDVDROM",
            "HDDVDR",
            "HDDVDRAM",
            "BDROM",
            "BDR",
            "BDRE"
        )

        Write-Verbose ("Selected media type is " + $media + " with value " + $mediaType.IndexOf($media))

        ## Initialise image
        Write-Verbose ("Initialising image object.")
        try {
            $image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$title} -ErrorAction Stop
            $image.ChooseImageDefaultsForMediaType($mediaType.IndexOf($media))

            Write-Verbose ("initialised.")
        } # try
        catch {
            throw ("Failed to initialise image. " + $_.exception.Message)
        } # catch


        ## Create target ISO, throw if file exists and -force parameter is not used.
        if ($PSCmdlet.ShouldProcess($destinationIso)) {

            if (!($targetFile = New-Item -Path $destinationIso -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) {
                throw ("Cannot create file " + $destinationIso + ". Use -Force parameter to overwrite if the target file already exists.")
            } # if

        } # if


        ## Get source content from specified path
        Write-Verbose ("Fetching items from source directory.")
        try {
            $sourceItems = Get-ChildItem -LiteralPath $source -ErrorAction Stop
            Write-Verbose ("Got source items.")
        } # try
        catch {
            throw ("Failed to get source items. " + $_.exception.message)
        } # catch


        ## Add these to our image
        Write-Verbose ("Adding items to image.")

        foreach($sourceItem in $sourceItems) {

            try {
                $image.Root.AddTree($sourceItem.FullName, $true)
            } # try
            catch {
                throw ("Failed to add " + $sourceItem.fullname + ". " + $_.exception.message)
            } # catch

        } # foreach

        ## Add boot file, if specified
        if ($boot) {
            Write-Verbose ("Adding boot image.")
            $Image.BootImageOptions = $boot
        }

        ## Write out ISO file
        Write-Verbose ("Writing out ISO file to " + $targetFile)

        try {
            $result = $image.CreateResultImage()
            [ISOFile]::Create($targetFile.FullName,$result.ImageStream,$result.BlockSize,$result.TotalBlocks)
        } # try
        catch {
            throw ("Failed to write ISO file. " + $_.exception.Message)
        } # catch

        Write-Verbose ("File complete.")

        ## Return file details
        return $targetFile

    } # process

    end {
        Write-Verbose ("Function complete.")
    } # end

} # function

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
    @('MSAL.PS') | ForEach-Object {
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
    try {
        Write-Host "Mounting $(([uri]$winurl).Segments[2]) file..."
        $MountIso = Mount-DiskImage -ImagePath "C:\temp\winisobuild\Win11_23H2_EnglishInternational_x64.iso" -PassThru
        $DriveLetter = ($MountIso | Get-Volume).DriveLetter

        Write-Host "Copying source files to temporary location..."
        Copy-Item -Path "$($DriveLetter):\" -Destination C:\temp\winisobuild\lol\ -Recurse -Force
    } catch {
        throw $($_.Exception.Message)
    }

    try {

    } catch {

    }

    Dism /mount-wim /wimfile:"C:\temp\winisobuild\lol\sources\install.wim" /index:6 /mountdir:C:\temp\winisobuild\Mount
    Dism /mount-wim /wimfile:"C:\temp\winisobuild\lol\sources\boot.wim" /index:2 /mountdir:C:\temp\winisobuild\Mount
    Dism /Unmount-Image /MountDir:C:\temp\winisobuild\Mount /commit
    try {
        New-ISOFile -source "C:\temp\winisobuild\lol" -destinationIso "C:\temp\winisobuild\test3.iso" -bootFile "C:\temp\winisobuild\lol\efi\microsoft\boot\efisys_noprompt.bin" -title "TestIso-rvdw"
    } catch {
        throw $($_.Exception.Message)    
    }
} catch {
    throw $($_.Exception.Message)
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -Confirm:$false
Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
Get-WindowsUpdate -Install -AcceptAll -AutoReboot -Verbose -Confirm:$false