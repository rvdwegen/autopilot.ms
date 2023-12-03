Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
Get-WindowsUpdate -Install -AcceptAll -AutoReboot -Verbose -Confirm:$false
pause

# try {
#     {(Get-WmiObject Win32_bios).SerialNumber | Rename-Computer}
# } catch {

# }