<#
.SYNOPSIS
    Resets AD User account passwords
.DESCRIPTION
    Resets AD User account passwords defined by the configuration XML file and emails the account managers
.EXAMPLE
    Reset and send email:
    .\Invoke-Passreset

    Reset and do not send email:
    .\Invoke-Passreset -NoEmail
.NOTES
    Filename:   Invoke-Passreset.ps1
    Author:     Poiuim
    Created:    2021-7-7

    Version History:
    1.0.0 (2021-7-7) Created Script
#>
param(
    [Parameter(Mandatory=$false, HelpMessage="Does not send emails when set")][switch] $NoEmail
)
Begin{
    try {
        [XML]$configuration = Get-Content -Path ".\configuration.xml" -ErrorAction Stop
    } catch [System.Exception] {
        Write-Warning "Could not load configuration file, exiting.."
        Start-Sleep -Seconds 2
        Exit 1
    }
    Function New-Password {
        param(
            [parameter(mandatory=$false)] $length
        )
        if ($null -eq $length){
            $length = 10
        }
        $password = -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
        return $password
    }
}
Process{
    Foreach ($Account in $configuration.Parameters.Account) {
        $EncounteredError = $false
        $PlainPassword = New-Password -length $configuration.Parameters.Length
        $SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force
        try {
            Set-ADAccountPassword $Account.SamAccountName -Reset -NewPassword $SecurePassword -ErrorAction Stop
        } catch [System.Exception] {
            Write-Warning "Could not reset password for $($Account.SamAccountName)"
            $EncounteredError = $true
        }
        if (!$NoEmail -and ($EncounteredError -eq $false)){
            $Subject = "Password reset for $($Account.SamAccountName)"
            $Body = "$($Account.SamAccountName)'s new password is $PlainPassword"
            try {
                Send-MailMessage -To $Account.To -From $Configuration.Parameters.From -Subject $Subject -Body $Body -SmtpServer $configuration.Parameters.SMTPServer -Port $configuration.Parameters.Port
            } catch [System.Exception] {
                Write-Warning "Did not send email to $($Account.To) successfully"
            }
        }
    }
}