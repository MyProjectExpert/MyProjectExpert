##################################################################################
# Title:  Pre-Migrate2010-to-2013
# Author: Michael Wharton
# Date:   05/30/2016 
# Description: PowerShell script to automate the migration of Project Server 2010 to Project Server 2013
#
# General Steps
# 1. Check and test database - check so
#    a. No Backward Compatibility
#    b. Check WRES_ACCOUNT is not null
#    c. If backward updated, then save enterprise global
##################################################################################
#  Miscellanous Notes about upgrade
#  DB customization will not be migrated
#  New Tables/Colum will not be added
#  Web parts work and will need need to be test
#  Custom Workflows/Activities dll will need to be installed post-migration
#  Contact the vendor to see if customizations is supported in 2013 or if they have updated version
#  Turn of BCM (backward compatibility Mode)
##################################################################################
Set-ExecutionPolicy "Unrestricted" -confirm:$false -Force
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
##################################################################################
#     Upgrade 2010 to 2013 Upgrade Check
#     1) the WRES_ACCOUNT must be NULL and not EMPTY
##################################################################################
$SqlCMD = "Use ProjectServer_Published"


$SqlCmd = "SELECT RES_Name, RES_TYPE, RES_ID from MSP_RESOURCES 
$SqlCmd = SqlCmd + " WHERE WRES_ACCOUNT ='' "

#	--If accounts with this condition are found, run the following SQL script on the same database: 
#   SQL Command to Fix
#	Update MSP_RESOURCES set WRES_ACCOUNT = null where WRES_ACCOUNT =''
#
#   Find all the Disable Prevent Active Directory Synchronization for this user
#   Not supported in Project Server 2013
#   These users will disapper in migration
#
$SqlCmd = "SELECT RES_NAME, WRES_ACCOUNT, WRES_EMAIL"
$SqlCmd = SqlCmd + " FROM MSP_RESOURCES"
$SqlCmd = SqlCmd + " WHERE RES_PREVENT_ADSYNC = 1 "
#
##################################################################################
#   Update the following section for your organization
#################################################################################
$URL                  = "http://ServerName"
$PWA                  = "http://ServerName/PWA"
$SqlServer            = "SqlServerName"
# SP2013 DBs
$ProjectServiceDBname = "PWA_ProjectWebApp"
$ProjectServerWSS     = "PWA_ProjectWebApp_TEMP_WSS_Content"
#
$WebAppName           = "Project Server 2013"
$ProjServApp          = "Project Service App"
$ProjectAppPool       = "Project Service Pool"
$MigrationLogs        = "C:\Notes\"
# SP2010 Db 
$PS2010ContentDBname  = "WSS_Content_PWA"
$DraftDBname          = "ProjectServer_Draft"
$ArchiveDBname        = "ProjectServer_Archive"
$PublishedDBname      = "ProjectServer_Published"
$ReportingDBname      = "ProjectServer_Reporting"
#  
$WebAppName2010       = "Project Server 2010 Classic"
$Project2010Pool      = "Project 2010 Pool"
#
# Create  Managed Service credentials
$FarmAdmin            = "domain\FarmAdmin"
$FarmAdminClaim       = "i:0#.w|FarmAdmin"
$FarmAdminPass        = "password"
$credFarmAdmin  = New-Object System.Management.Automation.PSCredential -ArgumentList @($FarmAdmin,(ConvertTo-SecureString -String $FarmAdminPass -AsPlainText -Force))
# Create  Managed Service credentials
$ServiceSP            = "domain\ServiceSP"
$ServicePass          = "password"
$credServiceSP  = New-Object System.Management.Automation.PSCredential -ArgumentList @($ServiceSP,(ConvertTo-SecureString -String $ServicePass -AsPlainText -Force))

