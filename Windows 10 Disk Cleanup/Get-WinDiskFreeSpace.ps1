<#
.DESCRIPTION
    Gets disk space information and returns True if free space is below 26GB (amount needed for Windows 10 Feature Updates)
.NOTES
    Filename:   Get-WinDiskFreeSpace.ps1
    Author:     Poiuim
    Created:    2021-5-24
#>

$FreeSpace = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object {$_.DeviceID -eq $env:SystemDrive} | Select-Object -Property FreeSpace
$FreeSpace = [math]::Floor(($FreeSpace.FreeSpace / 1GB))

if ($FreeSpace -lt 26) {
    Write-Output $true
} else {
    Write-Output $false
}