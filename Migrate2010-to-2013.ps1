##################################################################################
# Title:  Migrate2010-to-2013
# Author: Michael Wharton
# Date:   05/30/2016 
#
# Description: PowerShell script to automate the migration of Project Server 2010 to Project Server 2013
# V1.0 First draft of migration power script. Later versions to check for sanity of script
#
# First provision a PWA site. The script will update the PWA with a new migrated database
# Also REVIEW PC310 Migration of Great Database by Richard Van Langen
# 
# General Steps
# 1. Check and test database - check so
#    a. No Backward Compatibility
#    b. Check WRES_ACCOUNT is not null
#    c. If backward updated, then save enterprise global
# 2. Database Coping - backup and restore (all 5 databases)
# 3. Content Database Upgrade
#    a. Check DB for errors
#    b. Attach and upgrade
#    c. Take ownership of site collection
#    d. Migratin from Windows to Claims Authentication
#    e. Check the SP for issue
#    f. Upgrade content Database
# 4. Project Server Upgrade
#    a. Existing DB con -- Convertto-SPProjectDatabase
#    b. Attach DB to Web Application -- MOunt-SPProjectDatabase
#    c. DB error Check - Test-SPProjecDatabase
#    d. DB Upgrade - Upgrade-SPProjectDatabase
#    e. Mount PWA instance - Mount-SPProjectWEbInstance
#    f. PWA Upgrade - UPgrade-SPProjectWEbInstance
#    g. PWA Error Check  - Test-SPProjectWebInsnace
#    h. PWA Feature Enabled - Enable-SPFeature
#    Upgrade Proejct Server 2013
# 
##################################################################################
#
#  Miscellanous Notes about upgrade
#  DB customization will not be migrated
#  New Tables/Colum will not be added
#  Web parts work and will need need to be test
#  Custom Workflows/Activities dll will need to be installed post-migration
#  Contact the vendor to see if customizations is supported in 2013 or if they have updated version
#
#  Turn of BCM (backward compatibility Mode)
##################################################################################
Set-ExecutionPolicy "Unrestricted" -confirm:$false -Force
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
##################################################################################
##     Upgrade 2010 to 2013 Upgrade Check
##     1) the WRES_ACCOUNT must be NULL and not EMPTY
##################################################################################
#	Use ProjectServer_Published
#   select RES_Name, RES_TYPE, RES_ID from MSP_RESOURCES where WRES_ACCOUNT =''
#	--If accounts with this condition are found, run the following SQL script on the same database: 
#   SQL Command to Fix
#	Update MSP_RESOURCES set WRES_ACCOUNT = null where WRES_ACCOUNT =''
#--
#--   Find all the Disable Prevent Active Directory Synchronization for this user
#--   Not supported in Project Server 2013
#--   These users will disapper in migration
#--
#SELECT RES_NAME, WRES_ACCOUNT, WRES_EMAIL
#FROM MSP_RESOURCES
#WHERE RES_PREVENT_ADSYNC = 1
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
# sp2010 Db  LABC-2010PS
$PS2010ContentDBname  = "WSS_Content_PWA"
$DraftDBname          = "ProjectServer_Draft"
$ArchiveDBname        = "ProjectServer_Archive"
$PublishedDBname      = "ProjectServer_Published"
$ReportingDBname      = "ProjectServer_Reporting"
#  
$WebAppName2010       = "Project Server 2010 Classic"
$Project2010Pool      = "Project 2010 Pool"
$URL100               = "http://ServerName:100"
################################################################
# Create  Managed Service credentials
$FarmAdmin = "domain\FarmAdmin"
$FarmAdminClaim = "i:0#.w|FarmAdmin"
$FarmAdminPass = "password"
$credFarmAdmin  = New-Object System.Management.Automation.PSCredential -ArgumentList @($FarmAdmin,(ConvertTo-SecureString -String $FarmAdminPass -AsPlainText -Force))
# Create  Managed Service credentials
$ServiceSP = "domain\ServiceSP"
$ServicePass = "password"
$credServiceSP  = New-Object System.Management.Automation.PSCredential -ArgumentList @($ServiceSP,(ConvertTo-SecureString -String $ServicePass -AsPlainText -Force))

################################################################
#  Create Web Application
Measure-Command {
$AP = New-SPAuthenticationProvider -Verbose
New-SPWebApplication -Name $WebAppName -port 80 -URL $URL -DatabaseName $ProjectServerWSS -DatabaseServer $Sqlserver -ApplicationPool $ProjectAppPool -ApplicationPoolAccount (Get-SPManagedAccount $ServiceSP) -AuthenticationProvider $AP  -Verbose -Confirm:$false
}
# Note Time: 42 seconds  4/10/2016  

#################################################################
#  Start Migration Process
#################################################################
# Step 1 - Check SharerPoint content database that contains your Project Site data for errors that can cause upgrade to fail
Test-SPContentDatabase -Name $PS2010ContentDBname -WebApplication $URL
Test-SPContentDatabase -Name $PS2010ContentDBname -WebApplication $URL | out-file $MigrationLogs"Test-SPContentDatabaseClaims.log"

# Step 2 = Attach and upgrade the SharePoint Content Databse
Measure-Command {
Mount-SPContentDatabase -Name $PS2010ContentDBname -DatabaseServer $SqlServer -WebApplication $URL -NoB2BSiteUpgrade -verbose
}
# Note time: 30 seconds    4/10/2016  
$TempDisk = Get-SPContentDatabase  | where {$_.name -eq $ProjectServerWSS }
Dismount-SPContentDatabase -Identity $TempDisk.Id -Confirm:$false

# Step 3 - Add you account as secondary owner of the PWA site collection that you want to upgrade
#################################################################
Set-SPSite $PWA -LockState Unlock
Set-SPSite -identity $PWA -SecondaryOwnerAlias $FarmAdmin

# Step 4 - Migrate PWA 2010 User from Windows Classic to Claims-Based Authentication
(Get-SPWebApplication $url).migrateUsers($true)

# Step 5 - Run health check on the PWA site collection to view upgrade warning information
# Upgrade all PWA and site collections
Test-SPSite -Identity $PWA
Test-SPSite -Identity $PWA | out-file $MigrationLogs"Test-SPSite.log"

# Step 6 - Upgrade teh PWA site from SharePoint 2010 mode
Measure-Command {
upgrade-spsite $pwa -VersionUpgrade -verbose
}
# Note Time:  3 min 48 sec  

#################################################################
#  Second Major Milestone is upgrading Project Sever 2010 to 2013
#  1) Existing DB consolidation
#  2) Attach DB to Web Application
#  3) DB Error check
#  4) DB upgrade
#  5) Mounting PWA instance
#  6) PWA Upgrade
#  7) PWA error check
#  8) PWA Feature Enabled
#  9) Start upgraded Project Server 2013

#################################################################
# Step 1 - Existing DB Consolidation
#   check and delete any existing ProjectWebApp
#   Creates a new Project Server Database 
Measure-Command {
ConvertTo-SPProjectDatabase -WebApplication $URL -Dbserver $SqlServer  -ProjectServiceDbname $ProjectServiceDBname -ArchiveDbname $ArchiveDBname -DraftDbname $DraftDBname -PublishedDbname $PublishedDBname -ReportingDbname $ReportingDBname -Confirm:$false -Verbose
}
# Note Time: 2 min 19 seconds 

#################################################################
# Step 2 - Attach DB to Web Application
Measure-Command {
#Mount-SPProjectDatabase -Name $ProjectServiceDBname -ServiceApplication $ProjServApp -verbose  (the line is below is mounting to web app and not service)
Mount-SPProjectDatabase -Name $ProjectServiceDBname -WebApplication $URL -DatabaseServer $SQLserver  
}
# Note Time: 1 seconds

#################################################################
# Step 3 - DB Error check   ********** needs
Test-SPProjectDatabase -Name $ProjectServiceDBname  -DatabaseServer $SqlServer -Verbose  
Test-SPProjectDatabase -Name $ProjectServiceDBname  -DatabaseServer $SqlServer -Verbose   | out-file $MigrationLogs"Test-SPProjectDatabase.log"
Test-SPProjectDatabase -WebInstance $PWA
get-help test-sprojectdatabase -Examples

#################################################################
# Step 4 - DB Upgrade
Measure-Command {
Upgrade-SPProjectDatabase -Name $ProjectServiceDBname  -WebApplication $URL -DatabaseServer $sqlserver -Confirm:$false -verbose
}
# Note Time: 1 seconds
#################################################################
# Step 5 - Mounting PWA instance
# Mount the Project Web Instance with converted Project Service DB
Measure-Command {
Mount-SPProjectWebInstance -SiteCollection $PWA -DatabaseName $ProjectServiceDBname -DatabaseServer $sqlserver -Verbose
}
# Note Time: 3 seconds

#################################################################
# Step 6 - PWA Upgrade (Project Web Instance)
Measure-Command {
Upgrade-SPProjectWebInstance $PWA -Confirm:$FALSE -Verbose
}
# Note Time: 60 seconds 

#################################################################
# Step 7 - PWA error check
Test-SPProjectWebInstance -Identity $PWA 
Test-SPProjectWebInstance -Identity $PWA | Format-Table -Wrap -AutoSize | more  
Test-SPProjectWebInstance -Identity $PWA | Format-Table -Wrap -AutoSize | out-file $MigrationLogs"Test-SPProjectWebInstance.log"

# Step 8 - PWA Feature Enabled
#Enable-SPFeature pwasite -URL $PWA
Measure-Command {
Enable-SPFeature -Identity PWASITE -Url $PWA -Verbose
}
# Note Time: 26 seconds     4/10/2016

#################################################################
# Step 9 - Start upgraded Project Server 2013
START $PWA
