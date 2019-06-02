#############################################################################
# FileName; SharePoint2016FarmConfigurationWizardQA.ps1
# Description: SharePoint 016 SharePoint Farm Configuration Wizards
# Author: Michael Wharton
# Date:   05/14/2019 
#############################################################################
Set-ExecutionPolicy "Unrestricted" -ErrorAction SilentlyContinue
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
##########################################################
# disable loopback check - 
# New-ItemProperty HKLM:\System\CurrentControlSet\Control\lsa -Name "DisableLoopbackCheck" -Value "1" -PropertyType DWORD 
#############################################################################
#  Accounts
Measure-Command {
$DatabaseName                      = "TEST_SharePointConfig"
$AdministrationContentDatabasename = "TEST_Admin_Content"
$port                              = "8080"
$WindowAuthProvider                = "NTLM"
$PassPhrase                        = "xxxxxx"
$DatabaseServer                    = "SQLSERVER1"
$CentralAdminSite                  = "http://TESTAPP:8080"
#
$StateServiceName                  = "State Service Application"
$StateServiceProxy                 = "State Service Application Proxy"
$StateServiceDB                    = "TEST_StateServiceDB"
#
$FarmAdminAcct                     = "domain\FarmAdmin"
$credFarmAdmin                     = Import-CliXml -Path 'C:\safe\FarmAdmin.txt’

#############################################################################
write-host "Start Creating Configuration Database" -ForegroundColor Yellow
New-SPConfigurationDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -AdministrationContentDatabasename $AdministrationContentDatabasename  -FarmCredentials $CredFarmAdmin -Passphrase (ConvertTo-SecureString -String $Passphrase -AsPlainText -Force)  -LocalServerRole SingleServerFarm -Verbose

write-host "Start SPHelpCollection" -ForegroundColor Yellow
Install-SPHelpCollection -All -Verbose

write-host "Start SPResource Security" -ForegroundColor Yellow
Initialize-SPResourceSecurity -Verbose

write-host "Start SPService" -ForegroundColor Yellow
Install-SPService  -Verbose

write-host "Start SPFeature" -ForegroundColor Yellow
Install-SPFeature -AllExistingFeatures -Force  -Verbose

write-host "Start SPCentralAdministration" -ForegroundColor Yellow
New-SPCentralAdministration -port $port -WindowsAuthProvider $WindowAuthProvider  -Verbose 

write-host "Install-SPApplicationContent" -ForegroundColor Yellow
Install-SPApplicationContent  -Verbose

write-host "Start Central Admin" -ForegroundColor Yellow
START $CentralAdminSite 

}

####################################################################################
$StateServiceApp =  Get-SPStateServiceApplication 
if ($StateServiceApp -eq $null) 
{
    write-host "Create Service: $StateServiceName " -ForegroundColor Yellow
    $StateServiceApp = New-SPStateServiceApplication -Name $StateServiceName 
    New-SPStateServiceDatabase -Name $StateServiceDB -ServiceApplication $StateServiceApp
    New-SPStateServiceApplicationProxy -Name $StateServiceProxy -ServiceApplication $StateServiceApp -DefaultProxyGroup
}
else
{
    write-host "Service: $StateServiceName is already created " -ForegroundColor Green
}

