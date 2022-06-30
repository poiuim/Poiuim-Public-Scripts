<#
.SYNOPSIS
Deletes AD Computers older than date specified
.DESCRIPTION
Deletes AD Computers older than date specified
.EXAMPLE
.\ADCleanup.ps1 -OlderThan 30
.NOTES
    Author:     Jacob Kidd
    Date:       6.30.2022
    Filename:   ADCleanup.ps1
    Modified:   6.30.2022
    Version:    1.0
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Use this to find what would get deleted.")][Switch]$WhatIf,
    [Parameter(Mandatory=$true, HelpMessage="Amount of time in days to search for")][int]$OlderThan
)

$date = Get-Date
$deadline = $date.AddDays(-$OlderThan)

if ($WhatIf){
    $ComputerList = Get-ADComputer -Filter 'LastLogon -lt $deadline' -Properties LastLogon
    Write-Host "Total that would be deleted: $($Computerlist.Count)"
    $userinput = Read-Host "Would you like to see the hostnames that would be deleted? Y/N"
    switch ($userinput.toLower()) {
        "y" {Write-Host "$($Computerlist.name)"}
        "n" {Exit}
        Default {Exit}
    }
} else {
    $ComputerList = Get-ADComputer -Filter 'LastLogon -lt $deadline' -Properties LastLogon
    Write-Host "Total to delete: $($Computerlist.Count)"
    $userinput = Read-Host "Would you like to proceed? Y/N"
    switch ($userinput.toLower()) {
        "y" {$computerlist | Remove-ADComputer -Confirm:$False}
        "n" {Exit}
        Default {Exit}
    }
}
