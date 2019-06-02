#############################################################################
#
# Author: Michael Wharton
# Date: 05/20/2019 
# Description: Install, Configure Workflow and Restore Workflow datbase
#
# $WfManagementDB       = "SP16_WFManagementDB"          # DO NOT RESTORE
# $SbManagementDB       = "SP16_SBManagementDB"          # DO NOT RESTORE
#
# $WfInstanceDB         = "SP16_WFInstanceManagementDB"  # Restore the following databases 
# $wfResourceDB         = "SP16_WFResourceManagementDB" 
# $SbGatewayDB          = "SP16_SBGatewayDatabase"
# $SbMessageContainer   = "SP16_SBMessageContainer"
#############################################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#############################################################################
$SqlServerName    = "SP16SQLQA1"
#
$WebAppName       = "SharePoint - 80"
$WebAppURL        = "http://SP16appqa1.online14.net"
$WebAppPoolName   = "SharePoint - 80"
#
$WfManagementDB       = "SP16_WFManagementDB"          # DO NOT RESTORE
$WfInstanceDB         = "SP16_WFInstanceManagementDB" 
$wfResourceDB         = "SP16_WFResourceManagementDB" 
$SbManagementDB       = "SP16_SBManagementDB"          # DO NOT RESTORE
$SbGatewayDB          = "SP16_SBGatewayDatabase"
$SbMessageContainer   = "SP16_SBMessageContainer"
#
$WorkflowServiceName  = "Workflow Service Application"
$WorkflowProxyName    = "Workflow Service Application Proxy"
#
$WebServiceDefault    = "SharePoint Web Service Default"
$WfPoolName           = "WorkflowMgmtPool"
#
$WebAppURL            =  "http://SP16APP"
$PWAURL               =  "http://SP16APP/pwa"
$PWAURLssl            = "https://SP16APP/pwa"
$FlowURL              =  "http://SP16APP:12291"
$FlowURLssl           = "https://SP16APP:12290"
# Create credentials
$ServiceSP            = "domain\acctName"
$credServiceSP        = Import-CliXml -Path 'C:\safe\ServiceSP.txt’
#
$WebAppAcct           = "domain\webAppAcct"
$credWebAppAcct       = Import-CliXml -Path 'C:\safe\WebAppAcct.txt’
#
#############################################################################
# Export ServiceBus farm certifcate with Private key
# Export Service bus encryption Certificate with Private key
# 
# Import into local computer\Personal folder
# Import root certicate into Local Computer\Trusted root Authority foloder
#
Get-SBFarm 

#############################################################################
# (3)  Restore Workflow Farm 

Restore-SBFarm -FarmCertificateThumbprint <String> -GatewayDBConnectionString <String> -SBFarmDBConnectionString <String> [-AdminApiCredentials <PSCredential> ] [-AdminGroup <String> ] [-AmqpPort <Int32> ] [-AmqpsPort <Int32> ] [-EncryptionCertificateThumbprint <String> ] [-FarmDns <String> ] [-Force] [-HttpsPort <Int32> ] [-InternalPortRangeStart <Int32> ] [-MessageBrokerPort <Int32> ] [-RPHttpsPort <Int32> ] [-RunAsAccount <String> ] [-TcpPort <Int32> ] [-TenantApiCredentials <PSCredential> ] [-Confirm] [-WhatIf] [ <CommonParameters>]

Restore-SBFarm -RunAsAccount 'farm\test' -FarmCertificateThumbprint '41FED42EC87EA556FB64A41572111B96D13FBFC2' `
 -GatewayDBConnectionString 'Data Source=DBServer;Initial Catalog=SbGatewayDatabase;Integrated Security=True;Encrypt=False' ` 
 -SBFarmDBConnectionString 'Data Source= DBServer;Initial Catalog=SbManagementDB;Integrated Security=True;Encrypt=False' -AdminGroup 'BUILTIN\Administrators' ` 
 -EncryptionCertificateThumbprint 41FED42EC87EA556FB64A41572111B96D13FBFC2

# (4)  Restore SB Gateway 
Restore-SBGateway -GatewayDBConnectionString 'Data Source= DBServer;Initial Catalog=SbGatewayDatabase;Integrated Security=True;Encrypt=False' `
 -SBFarmDBConnectionString 'Data Source= DBServer;Initial Catalog=SbManagementDB;Integrated Security=True;Encrypt=False'

# (5) Restore Message Container 

Restore-SBMessageContainer -ContainerDBConnectionString "Data Source=localhost;Initial Catalog=SBMessageContainer01;Integrated Security=SSPI;Asynchronous Processing=True" -SBFarmDBConnectionString "Data Source=localhost;Initial Catalog= SBManagementDB;Integrated Security=SSPI;Asynchronous Processing=True" –id 1

# (6) Restore SB Host -- SB ManagementDB
$myPassword=convertto-securestring 'ereee' -asplaintext -force  
Add-SBHost -EnableFirewallRules $TRUE -RunAsPassword $myPassword -SBFarmDBConnectionString 'Data Source= DBServer;Initial Catalog=SbManagementDB;Integrated Security=True;Encrypt=False'

# (7) Restore WF Farm  - WF Instance Manager
$mykey=convertto-securestring 'etwegff' -asplaintext -force  
Restore-WFFarm  -RunAsAccount 'farm\test' -InstanceDBConnectionString 'Data Source= DBServer;Initial Catalog=WFInstanceManagementDB;Integrated Security=True;Asynchronous Processing=True;Encrypt=False' -ResourceDBConnectionString 'Data Source= DBServer;Initial Catalog=WFResourceManagementDB;Integrated Security=True;Asynchronous Processing=True;Encrypt=False' -WFFarmDBConnectionString 'Data Source= DBServer;Initial Catalog=WFManagementDB;Integrated Security=True;Encrypt=False' -InstanceStateSyncTime 'Sunday, May 11, 2014 12:30:00 PM' -ConsistencyVerifierLogPath 'c:\log.txt' -CertificateAutoGenerationKey $myKey

# (8) Restore WF Host -- WF Management DB
Add-WFHost -WFFarmDBConnectionString 'Data Source= DBServer;Initial Catalog=WFManagementDB;Integrated Security=True;Asynchronous Processing=True;Encrypt=False' -RunAsPassword $myPassword -EnableFirewallRules $TRUE -CertificateAutoGenerationKey $myKey

#
#$WFADMIN = "Wcc2prod\AdminWF"   # add WFSetupAcct and FarmAdmin to group
#
#Get-SPWorkflowServiceApplicationProxy | fl
#Get-SPWorkflowConfig -webapplication $webappname  | fl
#Get-SPWorkflowConfig -webapplication $webappname | Select *
#############################################################################
#  1. Pre-install Setup
#     Create accounts and groups
#     Add workflow setup account to SQL Server
#     Add setup account to admin on workflow server
#############################################################################
<#
#  Add accounts to AD server
#  domain\WFSetup               workflow setup Account
#  domain\WFservice             workflow service account
#  domain\WFADMIN               workflow ADMIN Group - Add FarmAdmin and WFsetup Account
Import-Module ActiveDirectory    # must be run on AD Server
New-ADUser -Name lab\WFSetup -Name "WFSETUP" -Path "OU=ServiceOU,DC=LAB,DC=LOCAL" `
    -SamAccount "WFSETUP" `
    -DisplayName "WFSetup" `
    -AccountPassword (ConvertdTo-SecureString "mountain#1" -AsPlainText -Force) `
    -ChangePasswordAltLogon $true `
    -Enable $true
#  Add accounts to SQL Server
#  Add lab\WFSetup account to SQL Server 
#  setup SQL Permission to WFSetup as SysAdmin
#
#  Add WFSetup as local Admin on workflow server
#>
#############################################################################
#  2. Install and configure workflow 
#     
#  Microsoft Web Platform Installer 5.1 
#  Start https://www.microsoft.com/web/downloads/platform.aspx   
#
#  Run Workflow Manager 1.0 Refresh (CU2) -- update .Net Frame Work 2.6
#           Wizard "Configure Workflow Manager with Custom Settings"
#
#  Installs Manager, Client and Service Bus
#  Logon on workflow server
#  a.  Install workflow manager
#  b.  Install workflow manager CU (patches)
#  c.  Install workflow service bus CU (patches)
#############################################################################
#  3. Configure workflow 
#
#  Pick one of the 4 configurations for your envirnoment
#  Required to bind port 12290 from IIS for configuration 1 or 3 to work
#    If the following fail below then try binding port 12990
#############################################################################
# 1. Configure Workflow Manager on a server that is part of the SharePoint 2016 farm and using HTTP
# Typical if using workflow manager on same server as SharePoint
# Register-SPWorkflowService –SPSite $PWAURL  –WorkflowHostUri $FlowURL –AllowOAuthHttp

# 2. Configure Workflow Manager on a server that is part of the SharePoint 2016 farm and using HTTPS
#    Note:  Setup AAM for https
#           Update IIS with 443
#
Register-SPWorkflowService –SPSite $PWAURLssl –WorkflowHostUri $FlowURLssl

# 3. Configure Workflow Manager on a server that is NOT part of the SharePoint 2016 farm and using HTTP
# Register-SPWorkflowService –SPSite $PWAURL  –WorkflowHostUri $FlowURL –AllowOAuthHttp

# 4. Configure Workflow Manager on a server that is NOT part of the SharePoint 2016 farm and using HTTPS
# Register-SPWorkflowService –SPSite $PWAURLssl –WorkflowHostUri $FlowURLssl

#############################################################################
#  4. Validate Workflow manager Installation
#############################################################################
#  Start up SharePoint Designer
#  1) Open PWA site
#  2) Click on Workflow
#  3) Check that Project Server Workflow is included

