<#
.DESCRIPTION
    Removes dbutil_2_3.sys from Windows temp and Local Appdata temp folders per Dell CVE advisory
.NOTES
    Filename:   Remove-DBUtil.ps1
    Author:     Poiuim
    Created:    2021-5-6
#>

$File = "dbutil_2_3.sys"
$WindowsTempSearch = Get-ChildItem -Path "$env:windir\Temp" -Filter $File -Recurse -ErrorAction "SilentlyContinue"
$UserFolderSearch = Get-ChildItem -Path "$env:SystemDrive\Users" -Filter $File -Recurse -ErrorAction "SilentlyContinue"

try{
    if ([boolean]$WindowsTempSearch -eq $true -or [boolean]$UserFolderSearch -eq $true) {
        if (-not [string]::IsNullOrEmpty($WindowsTempSearch.FullName)) {
            foreach ($Object in $WindowsTempSearch.FullName) {
                Remove-Item -Path $Object
            }
        }
        if (-not [string]::IsNullOrEmpty($UserFolderSearch.FullName)) {
            foreach ($Object in $UserFolderSearch.FullName) {
                Remove-Item -Path $Object
            }
        }
    }
} catch [System.Exception] {
    Exit
}