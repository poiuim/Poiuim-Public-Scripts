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
    1.1.0 (2022-11-7) Password Generation on animal wordlist, added TLS email support, better comments
#>
param(
    [Parameter(Mandatory=$false, HelpMessage="Does not send emails when set")][switch] $NoEmail,
    [Parameter(Mandatory=$false, HelpMessage="Use TLS with authentication for email")][switch] $UseTLS
)
Begin{
    #Import Configuration
    try {
        [XML]$configuration = Get-Content -Path ".\configuration.xml" -ErrorAction Stop
    } catch [System.Exception] {
        Write-Warning "Could not load configuration file, exiting.."
        Start-Sleep -Seconds 2
        Exit 1
    }
#    Function New-Password {
#        param(
#            [parameter(mandatory=$false)] $length
#        )
#        if ($null -eq $length){
#            $length = 10
#        }
#        $password = -join ((65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_})
#        return $password
#    }
    #Generates passwords: Animal Animal Digit
    Function New-Password {
        try {
            $wordlist = Get-Content ".\wordlist.txt"
        } catch [System.Exception] {
            Write-Warning "Could not load word list, exiting.."
            Start-Sleep -Seconds 2
            Exit 1
        }
        $word1 = $wordlist | Where-Object Length -eq 5 | Get-Random
        $word2 = $wordlist | Where-Object Length -eq 5 | Get-Random
        $number1 = (1..10) | Get-Random
        $Password = "$($word1) $($word2) $($number1)"
        Return $Password
    }
    #Generates PSCredential object for SSL authentication
    if ($UseTLS) {
        $emailusername = $configuration.Parameters.EmailUser
        $emailpassword = $configuration.Parameters.EmailPassword
        [SecureString]$secureemailpassword = $emailpassword | ConvertTo-SecureString -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $emailusername, $secureemailpassword
    }
}
Process{
    #Generates and sets password for each account in config file
    Foreach ($Account in $configuration.Parameters.Account) {
        $EncounteredError = $false
        $PlainPassword = New-Password
        $SecurePassword = ConvertTo-SecureString -AsPlainText $PlainPassword -Force
        try {
            Set-ADAccountPassword $Account.SamAccountName -Reset -NewPassword $SecurePassword -ErrorAction Stop
        } catch [System.Exception] {
            Write-Warning "Could not reset password for $($Account.SamAccountName)"
            $EncounteredError = $true
        }
        #No SSL
        if (!$NoEmail -and ($EncounteredError -eq $false) -and !$UseTLS){
            $Subject = "Password reset for $($Account.SamAccountName)"
            $Body = "$($Account.SamAccountName)'s new password is $PlainPassword"
            try {
                Send-MailMessage -To $Account.To -From $Configuration.Parameters.From -Subject $Subject -Body $Body -SmtpServer $configuration.Parameters.SMTPServer -Port $configuration.Parameters.Port
            } catch [System.Exception] {
                Write-Warning "Did not send email to $($Account.To) successfully"
            }
        #With SSL
        } elseif (!$NoEmail -and ($EncounteredError -eq $false)) {
            $Subject = "Password reset for $($Account.SamAccountName)"
            $Body = "$($Account.SamAccountName)'s new password is $PlainPassword"
            try {
                Send-MailMessage -To $Account.To -From $configuration.Parameters.From -Subject $Subject -Body $Body -SmtpServer $configuration.Parameters.SMTPServer -Port $configuration.Parameters.Port -UseSsl -Credential $Credentials
            } catch [System.Exception] {
                Write-Warning "Did not send email to $($Account.To) successfully"
            }
        }
    }
}