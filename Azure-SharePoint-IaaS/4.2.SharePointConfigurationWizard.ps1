<# 
 FileName: 4.2.SharePointConfigurationWizard.ps1
 Description: SharePoint 2019 SharePoint Farm Configuration Wizards
 Author: Michael Wharton, Project MVP
 Date:   11/27/2018 
 
 Using a script to build to SharePoint farm allows for naming SQL databases
 and avoid QUID in database name.   Also enterprise organization frawn on wizards
 and a sript provides details of what is happening.
#
#############################################################################
#    Setup user account
#    1. must be a domain account
#    2. must be a member of local admin group on wech web and application server
#    3. SQL Server must have roles of securityadmin and dbcreator
#############################################################################
#  22 minutes - 2 proc
#  11 minutes - 4 proc
#>
Measure-Command {
Set-ExecutionPolicy "Unrestricted" -ErrorAction SilentlyContinue -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#
$DatabaseServer           = "demosql"
$DatabaseName             = "SP19_SharePointConfig"
$AdminContentDatabasename = "SP19_AdminContent"
$port                     = "8080"
$WindowAuthProvider       = "NTLM"
$PassPhrase               = "Demo9999"
$CentralAdminSite         = "http://demosp:8080"
$AcctFarmAdmin            = "XXX2dev\FarmAdmin"
$credFarmAdmin            = Import-CliXml -Path 'C:\safe\XXX2dev-farmadmin.txt' 
#
##########################################################
#  1. configdb
#  Create SharePoint Configuration Database
##########################################################
#New-SPConfigurationDatabase     
#    -DatabaseName $DatabaseName    
#    -DatabaseServer $DatabaseServer     
#    -AdministrationContentDatabasename $AdministrationContentDatabasename     
#    -Passphase  (convertto-securestring $Passphrase -AsPlainText -Force)   (prompt)
#    -FarmCredentials $CredSPFarm
#    -SkipRegisterAsDistributedCacheHost (Distributed cache is enabled by default.  Recommend to turn off 
#          if  using SharePoint 2010 scripts to build a SharePoint 2013 farm. 
#          Reference Distributed Cache Service in the MS SP 2013: Designing and Architecting Solution
#
write-host "Start Creating Configuration Database" -ForegroundColor Yellow
#New-SPConfigurationDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -AdministrationContentDatabasename $AdministrationContentDatabasename  -FarmCredentials $CredFarmAdmin -Passphrase (ConvertTo-SecureString -String $Passphrase -AsPlainText -Force) -SkipRegisterAsDistributedCacheHost -Verbose
 New-SPConfigurationDatabase -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDatabasename -FarmCredentials $credFarmAdmin -Passphrase (ConvertTo-SecureString -String $Passphrase -AsPlainText -Force)  -LocalServerRole SingleServerFarm -Verbose
#New-SPConfigurationDatabase -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer -AdministrationContentDatabaseName $AdminContentDatabasename -FarmCredentials $credFarmAdmin -Passphrase (ConvertTo-SecureString -String $Passphrase -AsPlainText -Force)  -LocalServerRole SingleServerFarm -Verbose
#
# Use the following command for SharePoint farm with more than 1 server
# New-SPConfigurationDatabase -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName -AdministrationContentDatabasename $AdministrationContentDatabasename  -FarmCredentials $CredFarmAdmin -Passphrase (ConvertTo-SecureString -String $Passphrase -AsPlainText -Force)  -LocalServerRole SingleServerFarm -Verbose
#
# Use command to connect to an existing SHarePoint Fram
#Connect-SPConfigurationDatabase -DatabaseName $DatabaseName -DatabaseServer $DatabaseServer -SkipRegisterAsDistributedCacheHost
##########################################################
#  2. helpcollections
write-host "Start SPHelpCollection" -ForegroundColor Yellow
Install-SPHelpCollection -All -Verbose
##########################################################
#  3. secureresources
#  Install SP Resource Security
#  Ensure all resources, including files, folders and registry keys are ready to controlled
##########################################################
write-host "Start SPResource Security" -ForegroundColor Yellow
Initialize-SPResourceSecurity -Verbose
##########################################################
#  4. services
#  Install SP Services
#  Install and provision Services, Service Proxies and Service Instance
##########################################################
write-host "Start SPService" -ForegroundColor Yellow
Install-SPService  -Verbose
#Install-spservice -Provision   -- what does this do?
##########################################################
#  5. installfeatures
#  Install-SPFeature
#  Install all SharePoint features
##########################################################
write-host "Start SPFeature" -ForegroundColor Yellow
Install-SPFeature -AllExistingFeatures -Force  -Verbose
##########################################################
#  6. adminvs
#  Create Central Administration Web Application and Site
#  Note:  Normally this isn't required when running from the wizard
#  Note:  Requires to use CLASSIC MODE
##########################################################
#New-SPCentralAdministration 
#   -port $port 
#   -WindowsAuthProvider $WindowAuthProvider
write-host "Start SPCentralAdministration" -ForegroundColor Yellow
New-SPCentralAdministration -port $port -WindowsAuthProvider $WindowAuthProvider  -Verbose 
##########################################################
#  7. evalprovision
#  Not required.. This is used for evaluation software
# get-help Request-SPUpgradeEvaluationSite 
# Request-SPUpgradeEvaluationSite -Identity $CentralAdminSite -Verbose 
##########################################################
#  8. Install-SPapplicationContent
#  Install Copy shared appplication data to existing Web Applications
##########################################################
write-host "Install-SPApplicationContent" -ForegroundColor Yellow
Install-SPApplicationContent  -Verbose
##########################################################
#  9. upgrade
#  This command may need to put near the top for cases when there are outstanding UPGRADES
#$spfarm = Get-SPFarm
#Get-SPPendingUpgradeActions -RootObject $spfarm
# Upgrade-SPFarm 
##########################################################
#  Open Central Admin 
##########################################################
write-host "Start Central Admin" -ForegroundColor Yellow
START $CentralAdminSite 
#  Make Central Admin Site a local trusted site and the username prompt will not pop-up
#Start-Process "C:\Program Files\Internet Explorer\iexplore.exe" -ArgumentList $CentralAdminSite -Credential ($CredFarmAdmin)
}
