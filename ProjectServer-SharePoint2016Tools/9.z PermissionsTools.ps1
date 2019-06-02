#######################################################
# Author: Michael Wharton
# Date: 04/24/2019
# Description: Configure Project Server 2016 configuration
#######################################################
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue  -Verbose
#######################################################
#  Setup the followig configuration values
#######################################################
# Web Application settings
$WebAppName       = "SharePoint - 80"
$RootSiteName     = "Root"
$WebAppURL        = "http://qa-app.domain.local"
$AppPool          = "SharePoint - 80"
$WSS_ContentDB    = "SP16_WSS_Content"
#
#  Root Collection 
$SiteRootURL       = "http://qa-app.domain.local"
$SiteRootName      = "SharePoint Root"
#
$SqlServerName        = "qa-sql"
$WebAppURL            = "http://qa-app.domain.local"
$SiteRootURL          = "http://qa-app.domain.local"
$SiteRootName         = "Root Site"
$WebAppName           = "SharePoint - 80"    # Project Server 2016
$ProjectServiceApp    = "Project Server Service Application"
$ProjectServicePool   = "Project Service Pool"
$ProjectSiteName      = "Project Management Office"
$ProjectOwner         = "domain\username"
$ProjectKey           = "11111-22222-33333-44444-55555"
$SitePwaURL           = "http://qa-app.domain.local/Pwa"
$WebHostHeader        = "qa-app.domain.local"
$WSS_ContentDB        = "SP16_WSS_Content"
#
#  Business Intellience 
$SiteProjectBiURL     = "http://qa-app.domain.local/PWA/ProjectBICenter"
$SiteProjectBIName    = "Business Intelligence Center"
#
# Create credentials
$ServiceSP            = "domain\ServiceSP"   
$ServicePass          = "XXXXXXXX"
$credServiceSP  = New-Object System.Management.Automation.PSCredential -ArgumentList @($ServiceSP,(ConvertTo-SecureString -String $ServicePass -AsPlainText -Force))

$Site = 'http://qa-app.domain.local/sites/demo'
START $Site 


Start $SiteRootUrl + "/_layouts/15/Permsetsup.aspx"
http://qa-app.domain.local/_layouts/15/start.aspx#/_layouts/15/user.aspx

# New user
New-SPUser -UserAlias "domain\sarah" -DisplayName "Sarah Wharton" -Web $Site

Get-SPWeb $Site | New-SPUser -UserAlias "domain\Sarah"

# Delete user
Remove-SPUser "domain\sarah" -Web $SiteRootURL
remove-spuser -Identity  "domain\sarah"  -Web $SiteRootURL

Get-SPSite $SiteRootURL | Get-SPWeb | remove-spuser "domain\sarah"

# Get users
get-spuser -Web $Site  -Group "Demo OWNERS"

start $WebAppURL


################################################
$web = Get-SPWeb -Identity $WebAppURL
# $web | Select *

$grpName = "Intranet members"
$grpName = "Excel Services Viewers"
$group = $web.SiteGroups[$grpName]
$roleAssignment = $web.RoleAssignments.GetAssignmentPrincipal($group)

$web.RoleAssignments | Get-Member


$userAccount = "domain\mawharton"
$user = $web.ensureUser($userAccount)
$roleAssignment = $web.RoleAssignments.GetAssignmentPrincipal($user)

 $web.RoleAssignments.GetAssignmentByPrincipal($user.ID) 

$permissionToAdd = "Contribute"
$permissionToRemove = "Edit"
$addPermissionRole = $web.RoleDefinitionBindings[$permissionToAdd]
$removePermissionrole - $web.RoleDefinitionBiginds[$permissionstoRemove]

$roleAssignment.Update()


################
Set-spuser -Identity "domain\admin2" -Web $WebAppURL -AddPermissionLevel "Contribute"


#######################
get-spsite | select *

get-spsite | select RootWeb, webApplication, url


$site = get-spsite

#Get-SPWebApplication
#Get-SPWeb $WebAppURL
#Get-SPSite 

foreach($web in $site.AllWebs)

{
    Write-Output $web.Name
    $group = $site.RootWeb.SiteGroups
#    $group = $web.Site.RootWeb.SiteGroups
    foreach ($group in $groups)
    {
        Write-Output "asdf"
    }

}


#############################################
$site = "http://qa-app.domain.local/pwa"

GEt-spuser -Web $site | Select Userlogin, `
    @{name="Assigned by Roles" ;expression={$_.Roles}}, `
    @{name="Assigned by Groups" ;expression={$_.Groups | %{$_.Roles}}} , `
    Groups | Format-Table -AutoSize

####
$web = Get-SPWeb $site 
$loginName = "domain\Sarah"
$users = Get-SPUser -Web $web.url

foreach ($user in $users)
{
    write-host $user 
    if($user.loginName.contains( $loginName ))
    {
        Write-host $user
    }
}


#  Audit
#    Initial Deployument
#    Quarerlty Audi#
#    RemediZtion tasks
