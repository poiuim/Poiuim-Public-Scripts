<#
.DESCRIPTION
    Detects the presence of dbutil_2_3.sys and returns $true if found.
.NOTES
    Filename:   Get-DBUtilPresence.ps1
    Author:     Poiuim
    Created:    2021-5-6
#>

$File = "dbutil_2_3.sys"
$UserFolderSearch = Get-ChildItem -Path "$env:SystemDrive\Users" -Filter $File -Recurse -ErrorAction "SilentlyContinue"
$WindowsTempSearch = Get-ChildItem -Path "$env:windir\Temp" -Filter $File -Recurse -ErrorAction "SilentlyContinue"

try {
    if ([boolean]$UserFolderSearch -eq $true -or [boolean]$WindowsTempSearch -eq $true) {
        Write-Output $true
    } else {
        Write-Output $false
    }
} catch [System.Exception] {
    Exit
}
