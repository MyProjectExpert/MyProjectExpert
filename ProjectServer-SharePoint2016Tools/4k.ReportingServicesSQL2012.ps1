# ConfigureReport
# Author: Michael Wharton
# Date: 04/25/2019
# Configure Reporting Services
#
# Description: Configure SQL Reporting Services for SharerPoint mode
# Start https://msdn.microsoft.com/en-us/library/jj219068.aspx
# Start https://social.technet.microsoft.com/wiki/contents/articles/36240.sharepoint-2016-install-reporting-service-in-farm.aspx 
#
#  Once install and configured, then must setup SSRS up in site collection.
#
Set-ExecutionPolicy "Unrestricted" -ErrorAction SilentlyContinue
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
##############################################################
#######################################################
$SqlServerName    = "VSP16SQLQA1"
$SsrsDB           = "SP16_ReportingServices"
$SsrsAlerts       = "SP16_ReportingServices_Alerting"  # Not used - db build based on report services DB name 
$SsrsTempDB       = "SP16_ReportingServices_TempDB"    # Not used - db build based on report services DB name
#
$SsrsPoolName         = "SSRS on VSP16APPQA1"
$SsrsName             = "SSRS on VSP16APPQA1"
$SsrsProxy            = "SSRS on VSP16APPQA1 Proxy"
#
$WebServiceDefault    = "SharePoint Web Service Default"
# Create credentials
$ServiceSP            = "domain\acctName"
$credServiceSP        = Import-CliXml -Path 'C:\safe\ServiceSP.txt’
##############################################################
#
# Put the SSRS engine on the SharePoint server
# Step 1
#    Load SQL Server 2016 Standard and install SSRS for SharePoint 2016
#    Database Engine (not needed)
#    Management Tools (not needed)
#    Reporting Services (not needed)
#   * Reporting Services Add-in for SharePoint Report 
#
#  Step 2
#  Register and Start Reporting Services
Install-SPRSService 
Install-SPRSServiceProxy
Get-spserviceInstance | Sort-Object  status,TypeName |
    Select Status, TypeName
Get-SPserviceInstance -all | where {$_.TypeName -like "SQL Server Reporting*"} | Start-SPServiceInstance
# Step 3
#  Create Reporting Service Application from SharePoint Central
#  Manager Service Applications / NEW / SQL Server Reporting Services Service Application
$ServiceAcct = Get-SPManagedAccount -Identity $ServiceSP  -ErrorAction SilentlyContinue
if (-not $ServiceAcct) {
  New-SPManagedAccount -Credential $credServiceSP -Verbose 
}
#
$AppPool = Get-SPServiceApplicationPool -Identity $SsrsPoolName -ErrorAction SilentlyContinue
if (-not $AppPool) {
    $AppPool= New-SPServiceApplicationPool -Name $SsrsPoolName -Account $ServiceSP -Verbose
}
#
$SSRSA = New-SPRSServiceApplication -name $SsrsName -ApplicationPool $AppPool -DatabaseName $SsrsDB -DatabaseServer $SqlServerName
#
$SSRSAP = $SSRSA | New-SPRSServiceApplicationProxy $SsrsProxy
#$SSRSAP = Get-SPRSServiceApplication | New-SPRSServiceApplicationProxy $SsrsProxy
# 
# Step 4
#     Activate the Power View Site Collection Features
#    Site Settings / Power View Integration Feature - ENABLE
##  Download for the reporting services SharePoint Mode

#  MS SQL Server 2012 SP1 Reporting Service Addin for MS SharePoint
#  http://www.microsoft.com/en-us/download/details.aspx?id=35583
#
#  Add Report Server Content Types to a Library (Reporting Services in SharePoint Integrated Mode)
#  http://msdn.microsoft.com/en-us/library/bb326289.aspx
#
<#
#  Uninstall SSRS 

get-spserviceinstance -all |where {$_.TypeName -like "SQL Server*"} 
get-spserviceinstance -all |where {$_.TypeName -like "SQL Server Reporting*"} | Stop-SPServiceInstance

Install-SPRSService -Uninstall
Install-SPRSServiceProxy -Uninstall

#>
