<#
.SYNOPSIS
    Cleans Windows 10 disks
.DESCRIPTION
    Leverages cleanmgr.exe to clean bloated Windows 10 OS disks by removing old/temporary files, uses sageset 117
.NOTES
    Filename:   Invoke-DiskCleanup.ps1
    Author:     Poiuim
    Created:    2021-5-13
#>
Begin { #Create registry keys
    $Keys = "Active Setup Temp Folders", "Downloaded Program Files", "Internet Cache Files", "Old ChkDsk Files", "Recycle Bin", "System error memory dump files", "System error minidump files", "Temporary Files", "Update Cleanup"
    $volumeCaches = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Foreach ($Key in $volumeCaches) {
        if ($Key.PSChildName -in $Keys) {
            try {
                New-ItemProperty -Path "$($Key.PSPath)" -Name "StateFlags0117" -Value 2 -PropertyType "DWord" -Force | Out-Null
                Write-Host "Made new item property in $($Key.PSChildName)"
            } catch [System.Exception] {
                Write-Host "Could not create key $($Key.PSChildName)"
            }
        }
    }
}
Process { #Run program and clean misc files
    Write-Host "Starting cleanmgr.exe.. "
    Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -Wait -ArgumentList "/sagerun:117"
    Write-Host "cleanmgr.exe finished.."
}
End { #Remove registry keys
    foreach ($Key in $volumeCaches) {
        if ($Key.PSChildName -in $Keys) {
            try {
                Remove-ItemProperty -Path "$($Key.PSPath)" -Name "StateFlags0117" -Force -ErrorAction Stop | Out-Null
                Write-Host "Deleted item property in $($Key.PSChildName)"
            } catch [System.Exception] {
                Write-Host "Could not delete key $($Key.PSChildName)"
            }
        }
    }
}