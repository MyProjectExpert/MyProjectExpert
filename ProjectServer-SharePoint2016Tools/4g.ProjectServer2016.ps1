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
$SqlServerName    = "SQLServer1"
#
$WebAppName       = "SharePoint - 80"
$WebAppURL        = "http://SPS16_APP"
$WebAppHostHeader = "SPS16_APP"
$WebAppPoolName   = "SharePoint - 80"
$WSS_ContentDB    = "Sp16_WSS_Content"
#
# Root Collection 
$SiteRootURL       = "http://SPS16_APP"
$SiteRootName      = "SharePoint Root"
# 
$SharePointWebServicesDefault  = "SharePoint Web Services Default"
$ProjectServiceApp    = "Project Server Service Application"
$ProjectServiceProxy  = "Project Server Service Application Proxy"
#$ProjectServicePool   = "Project Service Pool"
$ProjectSiteName      = "Project Management Office"
$ProjectOwner         = "domain\AdminAcct"
$ProjectKey           = "11111-22222-33333-44444-55555" 
$SitePwaURL           = "http://SPS16_APP/PWA"
$ProjectWebAppDB      = "SP16_ProjectWebApp"
#
#  Business Intellience 
$SiteProjectBiURL     = "http://vSPS16_APP/PWA/ProjectBICenter"
$SiteProjectBIName    = "Business Intelligence Center"
#
# Create credentials
$ServiceSP            = "domain\acctName"
$credServiceSP        = Import-CliXml -Path 'C:\safe\ServiceSP.txt’
#
$WebAppAcct           = "domain\acctName"
$credWebAppAcct       = Import-CliXml -Path 'C:\safe\WebAppAcct.txt’
#
################################################################
# Create Managed Accounts for either Project Service or Web Application
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

################################################################
# Create Project Service Pool
$ProjectServicePool = Get-SPServiceApplicationPool | Where-Object {$_.Name -eq $SharePointWebServicesDefault }
If (-not $ProjectServicePool)
    { 
    Write-Host -ForegroundColor Yellow "Create Project Service Pool: $ProjectServiceApp"
    $ProjectServicePool = New-SPServiceApplicationPool -Name  $SharePointWebServicesDefault -Account $ServiceSP -Verbose
    }
Else
    {Write-Host -ForegroundColor Green "Project Service Pool: $ProjectServiceApp  Already Created"}

################################################################
# Create SharePoint - 80 Pool
$WebAppPool = Get-SPServiceApplicationPool | Where-Object {$_.Name -eq $SharePointWebServicesDefault }
If (-not $ProjectServicePool)
    { 
    Write-Host -ForegroundColor Yellow "Create Project Service Pool: $ProjectServiceApp"
    $ProjectServicePool = New-SPServiceApplicationPool -Name  $SharePointWebServicesDefault -Account $ServiceSP -Verbose
    }
Else
    {Write-Host -ForegroundColor Green "Project Service Pool: $ProjectServiceApp  Already Created"}

################################################################
#  Create Project Server Service and Proxy
$ProjectServiceID  = Get-SPServiceApplication |  Where-Object {$_.DisplayName -eq $ProjectServiceApp } 
If (-not $ProjectServiceID )  {
    Write-Host -ForegroundColor Yellow "Creating Service Application: $ProjectServiceApp" 
    $ProjectServiceID = New-SPProjectServiceApplication -Name $ProjectServiceApp -Proxy -ApplicationPool (Get-SPServiceApplicationPool $ProjectServicePool) -Verbose
    }
Else
    {Write-Host -ForegroundColor Green "Project Service Application: $ProjectServiceApp  Already Created"}
<################################################################
#  Enable Project Service Key
$ProjectEnabled = Get-ProjectServerLicense -Verbose
If (($ProjectEnabled).Contains("Disabled")) {
    Write-Host -ForegroundColor Yellow "Project Server 2016 Preview: Disabled"
    Enable-projectserverlicense -Key $ProjectKey
    Write-Host -ForegroundColor Green "Project Server 2016 Preview: NOW Enabled"
    }
Else
    {
    Write-Host -ForegroundColor Green "Project Server 2016 Preview: Already Enabled"
    }
#>
#################################################################
# Create Web Application - using v8128_WSS_Content
#################################################################
$WebApp = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName } 
if (-not $WebApp)  {
    Write-Host -ForegroundColor YELLOW "Create Project Web Application: $WebAppName"
    $AP = New-SPAuthenticationProvider -Verbose
    $WebApp = New-SPWebApplication -Name $WebAppName -port 80 -URL $WebAppURL `
        -DatabaseName $WSS_ContentDB -ApplicationPool $WebAppPoolName  `
        -ApplicationPoolAccount (Get-SPManagedAccount $WebAppAcct) -AuthenticationProvider $AP -Verbose -Confirm:$false
    # mount ProjectWebApp databaswho
    Mount-SPContentDatabase $ProjectWebAppDB -DatabaseServer $SqlServerName -WebApplication $WebAppURL
    }
Else
    {Write-Host -ForegroundColor Green "Project Web Application: $WebAppName  Already Created"}
########################################################################
# Create Root Site -  note: should be needed for refresh of database
#########################################################################
$RootSite = Get-SPSite -Identity $SiteRootURL -ErrorAction SilentlyContinue
if (-not $RootSite) {
    Write-Host -ForegroundColor Yellow "Create Root Site: $SiteRootURL "
    $RootSite = New-SPSite $SiteRootURL -OwnerAlias $OwnerAccount -name $SiteRootName -Template "STS#0"
    Start $SiteRootURL -Verbose
    # sets Permissions groups
    # Start $SiteRootUrl + "/_layouts/15/Permsetsup.aspx"
    # http://qa-app.wcc2prod.local/_layouts/15/start.aspx#/_layouts/15/user.aspx
    }
else
    {
    Write-Host -ForegroundColor Green "Root Site: $SiteRootURL already Created"
    }
START $SiteRootURL
#########################################################################
# Provision PWA (ProjectServer8128)
$chkSite = Get-SPSite | Where-Object {$_.URL -eq $SitePwaURL } 
if (-not $chkSite) {
    Write-Host -ForegroundColor Green "Creating Project Site: $SitePwaURL"
    $chkManagedPath =  Get-SPManagedPath -WebApplication $webAppUrl | Where-Object {$_.Name -eq 'ProjectServer8128' } 
    if (-not $chkManagedPath) {
        New-SPManagedPath "ProjectServer8128" -WebApplication $WebAppURL -Explicit -verbose
        }
    New-SPSite -Url $SitePwaURL -Template "PWA#0" -Name $ProjectSiteName -OwnerAlias $ProjectOwner -Verbose 
#    Enable-projectserverlicense -Key $ProjectKey
    Enable-SPFeature PWASITE -Url $SitePwaURL -Verbose 
    Set-SPProjectPermissionMode -Url $SitePwaURL -Mode ProjectServer -Verbose
    Start $SitePwaURL
# sets Permissions groups
Start $SitePWAUrl + "_layouts/15/Permsetsup.aspx"
    }
else
    {
    Write-Host -ForegroundColor Green "Project Site: $SitePwaURL Already Created"
    }
#########################################################################
# Business Intelligence PWA (ProjectServer8128) - ProjectBICenter
$chkBiWeb = Get-SPWeb -Site $SitePwaURL -Limit ALL | Where-Object {$_.URL -eq $SiteProjectBiURL } 
if (-not $chkBiWeb) {
    Write-Host -ForegroundColor Green "Creating Site: $SiteProjectBIName"
    Enable-SPFeature PublishingSite -Url $SitePwaURL -Verbose 
    Enable-SPFeature PPSSiteCollectionMaster -Url $SitePwaURL -Verbose 
    
    $chkBiWeb = New-Spweb $SiteProjectBiURL -Template "BICenterSite#0" -Name $SiteProjectBIName 
    Start $SiteProjectBiURL
# sets Permissions groups
#    Start $SiteProjectBiURL + "/_layouts/15/Permsetsup.aspx"
    }
else
    {
    Write-Host -ForegroundColor Green "Project Site: $SiteProjectBiURL Already Created"
    }
#########################################################################
# End of Script#
#########################################################################
