<#
    .DESCRIPTION
        Removes group membership from disabled staff accounts. Logs are removed after 180 days.
    .NOTES
        Filename:   Remove-StaffADGroups.ps1
        Author:     Jacob Kidd
        Created:    8/6/2021
        8/24/2021: Changed if statement to not remove group memberships from accounts with no memberships.

        Change the Searchbase variable in the script to the OU you want to search for.

        Write-Log function shamelessly borrowed from Janik Vonrotz:
        https://janikvonrotz.ch/2017/10/26/powershell-logging-in-cmtrace-format/
#>

Begin {
    $SearchBase = "OU=Staff,OU=Users,DC=contoso,DC=local"
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    } catch [System.Exception] {
        Write-Host "Could not load active directory command module."
        Exit 1
    }
    function Write-log {

        [CmdletBinding()]
        Param(
              [parameter(Mandatory=$true)]
              [String]$Path,
    
              [parameter(Mandatory=$true)]
              [String]$Message,
    
              [parameter(Mandatory=$true)]
              [String]$Component,
    
              [Parameter(Mandatory=$true)]
              [ValidateSet("Info", "Warning", "Error")]
              [String]$Type
        )
    
        switch ($Type) {
            "Info" { [int]$Type = 1 }
            "Warning" { [int]$Type = 2 }
            "Error" { [int]$Type = 3 }
        }
    
        # Create a log entry
        $Content = "<![LOG[$Message]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Type`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"
    
        # Write the line to the log file
        Add-Content -Path $Path -Value $Content
    }
    $LogLife = 180
    $LogFilePath = Join-Path $PSScriptRoot "$(Get-Date -Format yyyy-MM-dd) GroupRemoval.log"
    $Exceptions = "resauser", "costafftemplate"
}
Process {
    $DisabledStaff = Get-ADUser -Filter "Enabled -eq '$false'" -SearchBase $SearchBase -Properties MemberOf
    foreach ($Staff in $DisabledStaff) {
        if (($Staff.SamAccountName -notin $Exceptions) -and ($null -ne $Staff.MemberOf)){
            try {
                $Staff.MemberOf | Remove-ADGroupMember -Members $Staff.DistinguishedName -Confirm:$false -ErrorAction Stop
                Write-Log -Path $LogFilePath -Message "User $($Staff.SamAccountName) had it's group memberships removed successfully." -Component $MyInvocation.MyCommand.Name -Type Info
            } catch [System.Exception] {
                Write-Host "Could not remove group membership for $($Staff.SamAccountName)"
                Write-Log -Path $LogFilePath -Message ("Failed to remove group memberships from $($Staff.SamAccountName) $PSItem") -Component $MyInvocation.MyCommand.Name -Type Error
            }
        } else {
            Write-Log -Path $LogFilePath -Message "User $($Staff.SamAccountName) is in the exceptions list and has been skipped." -Component $MyInvocation.MyCommand.Name -Type Info
        }
    }
}
End {
    $Date = Get-Date
    Get-ChildItem -Path $PSScriptRoot | Where-Object {($Date - $_.LastWriteTime).Days -gt $LogLife -and $_.Extension -eq ".log"} | Remove-Item
}