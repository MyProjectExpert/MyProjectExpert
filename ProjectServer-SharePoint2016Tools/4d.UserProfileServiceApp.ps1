#############################################################################
# Author: Michael Wharton
# Date: 04/26/2019
# Title:  7.Configure2016UserProfileServiceApp
# Description: User Profile Service Application
#############################################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#############################################################################
$SqlServerName    = "SQLserver1"
$DBServer         = "SQLServer1"  
# Web Application settings
$WebAppName       = "SharePoint - 80"
$WebAppURL        = "http://SP16_APP"
$WebAppHostHeader = "SP16_AP"
$WebAppPoolName   = "SharePoint - 80"
$WSS_ContentDB    = "SP16_WSS_Content"
$HostHeader       = "SP16"                 # Be sure DNS name exists - not required
#
#  Root Collection 
$SiteRootURL       = "http://SP16_APP"
$SiteRootName      = "SharePoint Root"
#
#  My Site Collection 
$MySiteURL       = "http://SP16/my"
$MySiteName      = "My Site"
#
#UPA specifics
$upaPool          = "User Profile Pool"
#
$UPSAppName       = "Profile Service Application"
$ProfileProxyName = "Profile Service Application Proxy"
$ProfileDBName    = "SP16_ProfileDB"
$SocialDBname     = "SP16_SocialDB"
$SyncDBName       = "SP16_UserSyncDB"
#
$AppPoolAcct      = "domain\ServiceAcct"
$OwnerAccount     = "domain\ServiceAcc1"

# Create credentials
$ServiceSP         = "domain\ServiceSP"
$credServiceSP     = Import-CliXml -Path 'C:\safe\ServiceSP.txt’
#
$ServiceUPA       = "domain\ServiceUPA"
$credServiceUPA    = Import-CliXml -Path 'C:\safe\ServiceUPA.txt’
#############################################################################
#  Configure User Profile Managed Account and Service Application Pool
###########################################################################
#  Enable Replicating  - Add user "Replicating Directory Change"
#  ADSI Edit - Security enable "Replicating Changes"
$ServiceUpaAcct = Get-SPManagedAccount -Identity $ServiceUPA  -ErrorAction SilentlyContinue
if (-not $ServiceUpaAcct) {
  Write-Host -ForegroundColor Yellow "Creating Managed Account: $ServiceUPA "
  New-SPManagedAccount -Credential $credServiceUPA -Verbose 
}
# Creaet Application Pool
$upaAppPool = Get-SPServiceApplicationPool -Identity $upaPool  -ErrorAction SilentlyContinue
if (-not $upaAppPool) {
    Write-Host -ForegroundColor Yellow "Creating App Pool: $upaPool"
    $upaAppPool= New-SPServiceApplicationPool -Name $upaPool -Account $ServiceUPA -Verbose
}

#################################################################
# Create Web Application on root that contains project server collection
#################################################################
$chkWebApp = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName } 
if (-not $chkWebApp) {
    Write-Host -ForegroundColor YELLOW "Create Web Application: $WebAppName"
    $AP = New-SPAuthenticationProvider -Verbose
    New-SPWebApplication -Name $WebAppName -port 80 -URL $WebAppURL -DatabaseName $WSS_ContentDB -ApplicationPool $AppPool -ApplicationPoolAccount (Get-SPManagedAccount $ServiceSP) -AuthenticationProvider $AP -Verbose -Confirm:$false
    }
Else
    {Write-Host -ForegroundColor Green "Web Application: $WebAppName  Already Created"}
#############################################################################
#  Create ROOT Site Collection 
#############################################################################
# Get-SPSite -Identity $SiteRootName 
$chkRootSite = Get-SPSite -Identity $SiteRootURL -ErrorAction SilentlyContinue
if (-not $chkRootSite) {
    Write-Host -ForegroundColor YELLOW "Create Root Site: $SiteRootURL"
    $RootSite = New-SPSite $SiteRootURL -OwnerAlias $OwnerAccount -name $SiteRootName -Template "STS#0"
    START $SiteRootURL
    }
Else
    {Write-Host -ForegroundColor Green "Root Site: $SiteRootName Already Created"}

#############################################################################
#  Create MY Managed Path - not required
#############################################################################
$chkManagedPath =  Get-SPManagedPath -WebApplication $webAppUrl | Where-Object {$_.Name -eq 'my' } 
if (-not $chkManagedPath) {
    Write-Host -ForegroundColor YELLOW "Create Managed Path: My"
    New-SPManagedPath "my" -WebApplication $WebAppURL -Explicit -Verbose
 #  New-SPManagedPath "my" -HostHeader   
    }
Else
    {Write-Host -ForegroundColor Green "Managed Path: My Already Created"}

<#
#############################################################################
#  Create MY/PERSONAL Managed Path - not required
#############################################################################
$chkManagedPath =  Get-SPManagedPath -WebApplication $webAppUrl | Where-Object {$_.Name -eq 'my/personal' } 
if (-not $chkManagedPath) {
    Write-Host -ForegroundColor YELLOW "Create Managed Path: my/personal"
    New-SPManagedPath "my/personal" -WebApplication $WebAppURL 
    }
Else
    {Write-Host -ForegroundColor Green "Managed Path: my/personal Already Created"}
#>

#############################################################################
#  Create MY Site Collection - Must be done before User Service Created
#############################################################################
# Get-SPSite -Identity $MySiteName 
$chkMySite = Get-SPSite -Identity $MySiteURL -ErrorAction SilentlyContinue
if (-not $chkMySite) {
    Write-Host -ForegroundColor YELLOW "Create Site Collection: My"
    $MySite = New-SPSite $MySiteURL -OwnerAlias $OwnerAccount -name $MySiteName -Template "SPSMSITEHOST#0" -Verbose  # Template not required.  If you include use line below
 #  $MySite = New-SPSite $MySiteURL -OwnerAlias $OwnerAccount -name $MySiteName -HostHeaderWebApplication $webAppUrl  # Template not required.  If you include use line below
 #  $MySite = New-SPSite $MySiteURL -OwnerAlias $OwnerAccount -name $MySiteName -Template "SPSMSITEHOST#0"
    }
Else
    {Write-Host -ForegroundColor Green "Site Collection: My Already Created"}
# START $MySiteURL

#############################################################################
#  Start User Profile Service  (UPS)
#############################################################################
# Stop-SPServiceInstance -Identity $UPS.ID
# Get-SPServiceInstance | Sort-Object Typename
# Get-SPserviceinstance | Where {$_.TypeName -Like "User Profile Service" } | Select Server, Status, Id, TypeName
# Get-SPserviceinstance | Where {$_.TypeName -Like "User Profile Service" -and $_.Server -Like "*app*" } | Select Status, ID, Server, TypeName

$UPS =  Get-SPserviceinstance | Where {$_.TypeName -Like "User Profile Service" -and $_.Server -Like "*app*" } 
if ($ups.Status -ne "Online") {
    Write-Host  -ForegroundColor YELLOW "Starting the User Profile Service.."
    Start-SPServiceInstance -Identity $UPS.ID -Verbose    # User Profile Synchnorization
    }
    else 
    {
    Write-Host -ForegroundColor GREEN "User Profile Service already started"
    }

Get-SPserviceinstance | Where-Object -Property "TypeName" -Contains "User Profile Service" | Select Status, ID, Server, TypeName
#############################################################################
#  Creates the User Profile Service Application
#     PS  I cannot get the user profile service created using powershell
#############################################################################
# $upaPath = New-SPManagedPath -RelativeURL "/my" -WebApplication $WebAppURL
$upServiceApp = Get-SPServiceApplication | 
 where {$_.Displayname -eq $UPSAppName}

if($upServiceApp -eq $null) { 
    Write-Host  -ForegroundColor YELLOW "Creating  User Profile Service..."
    $upa = New-SPProfileServiceApplication `
        -Name $UPSAppName -ApplicationPool $upaAppPool `
        -ProfileDBName $ProfileDBname -ProfileDBServer $DBServer `
        -SocialDBName $SocialDBname   -SocialDBServer $DBServer `
        -ProfileSyncDBName $SyncDBname -ProfileSyncDBServer $DBServer `
        -MySiteHostLocation $MySiteURL -verbose 
#        -SiteNamingConflictResolution None -DeferUpgradeActions:$false 
#        -MySiteManagedPath "/my/personal" `

    $appProxy = New-SPProfileServiceApplicationProxy `
        -Name $ProfileProxyName -PartitionMode -ServiceApplication $upa 
}

#############################################################################
# Final Notes
# 1) Start the User Profile Sysnc
#############################################################################

# Command to remove User Profile Service
# $spapp  = Get-SPServiceApplication -Name $UPSAppName
# Remove-SPServiceApplication $spapp -RemoveData 

#Get-SPServiceApplicationProxy |Select displayName
#
#Get-SPServiceApplicationProxy | where {$_.Displayname -eq $ProfileProxyName } |
#    Remove-SPServiceApplicationProxy 