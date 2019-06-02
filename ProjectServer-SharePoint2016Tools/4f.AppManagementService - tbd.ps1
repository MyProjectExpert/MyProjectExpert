#############################################################################
# 
# Author: Michael Wharton
# Date: 04/24/2019 
# FileName:  ConfigureAppManagmentServer
#
# Description: App Management Services
# START http://technet.microsoft.com/en-us/library/fp161236.aspx
#
#############################################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#############################################################################
# 1. Create 
#############################################################################
Get-SPServiceApplication
#############################################################################
#  Start Service
#  1) App Management Service
#  2) Microsoft SharePoint Foundation Subscription Setting Service
#############################################################################

#############################################################################
#  Creates the App Management Services
#############################################################################

#############################################################################
#  Create Subscription Service
#############################################################################

# New-SPSubscriptionSettingsServiceApplication -ApplicationPool "SharePoint Web Services Default" -Name "Subscription Settings Service Application" -DatabaseName "SubscriptionSettingsDB" | New-SPSubscriptionSettingsServiceApplicationProxy
New-SPSubscriptionSettingsServiceApplication -ApplicationPool "SubscriptionPool" -Name "Subscription Settings Service Application" -DatabaseName "LAB_SubscriptionSettingsDB" | New-SPSubscriptionSettingsServiceApplicationProxy

$AppPool = New-SPServiceApplicationPool -Name SettingsServiceAppPool -Account (Get-SPManagedAccount LAB\ServiceSP)

$App = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $appPool -Name AppManagementService -DatabaseName LAB_AppManagmentServiceDB

$proxy = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $App

# Get-SPServiceInstance | where{$_.TypeName -eq "Microsoft SharePoint Foundation Subscription Settings Service"} | Start-SPServiceInstance
# Get-SPServiceInstance | where{$_.TypeName -eq "SettingsServiceApp"} | Start-SPServiceInstance
 Get-SPServiceInstance | where{$_.TypeName -eq "AppManagementService"} | Start-SPServiceInstance

##########################################################
#  List of App Management Services Command
##########################################################
# Get-help SPAppMan
#
Get-Help    New-SPAppManagementServiceApplication 

Get-Help    New-SPAppManagementServiceApplicationProxy

Get-Help    Set-SPAppManagementDeploymentId 

   
#@DisplayName          TypeName             Id                                  
#-----------          --------             --                                  
#SettingsServiceApp   Microsoft SharePo... 53a94bf5-dfb6-4caa-8b09-f2fbd2b404c4