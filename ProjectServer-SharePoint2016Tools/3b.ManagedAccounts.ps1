#######################################################
# Author: Michael Wharton
# Date: 04/24/2019
# Description: Setup Managed Accounts
#######################################################
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue  -Verbose
#######################################################
#  Setup the followig configuration values
#######################################################
# Setup credentials
$PAcct      = "domain\PAcct"
$credPAcct  = Import-CliXml -Path 'C:\safe\Pacct.txt’

$OAcct       = "domain\OAcct" 
$credOAcct   = Import-CliXml -Path 'C:\safe\Oacct.txt’   
################################################################
# Create Managed Account
################################################################
$ManagedPAcct = Get-SPManagedAccount -Identity $PAcct -ErrorAction SilentlyContinue
If ($ManagedPAcct -eq $null) {
    Write-Host -ForegroundColor Yellow "Create Managed Account: $PAcct "
    $ManagedPAcct =New-SPManagedAccount -Credential $credPAcct  -Verbose
    }
else
    {Write-Host -ForegroundColor Green "Managed Account $PAcct Already Created"}

$ManagedOAcct = Get-SPManagedAccount -Identity $OAcct -ErrorAction SilentlyContinue
If ($ManagedOAcct -eq $null) {
    Write-Host -ForegroundColor Yellow "Create Managed Account: $OAcct"
    $ManagedOAcct = New-SPManagedAccount -Credential $credOAcct -Verbose
    }
else
    {Write-Host -ForegroundColor Green "Managed Account $OAcct Already Created"}

#
Get-SPManagedAccount | Select TypeName, userName

