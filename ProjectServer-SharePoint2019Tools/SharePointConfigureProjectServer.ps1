#######################################################
# Author: Michael Wharton
# Date: 04/15/2018
# Description: Configure Project Server Service 2019
#######################################################
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue  -Verbose

Measure-Object {
#######################################################
#  Setup the followig configuration values
#######################################################
$hostname             = $env:COMPUTERNAME            # or hostName
$SqlServerName        = $hostname                    # update SQL host name
$domainName           = $env:USERDOMAIN              # or "domainName"
$ProjectOwner         = $domainName + "\mawharton"   # primary username
$SecondOwner          = $domainName + "\mwharton"    # secondary username
$ServiceSP            = $domainName + "\ServiceSP"   # Service Account
$ServicePass          = "password"
$ProjectKey           = "R9946-QXNHR-62JPQ-3H3QC-TMWJT"
#######################################################
$WebAppURL            = "http://" + $hostName
$SiteRootURL          = "http://" + $hostName
$SitePwaURL           = "http://" + $hostName + "/pwa"
$WebHostHeader        = $hostName + "." + $env:USERDNSDOMAIN
$SiteRootName         = "Root Site"
$WebAppName           = "Project Server 2019"
$ProjectServiceApp    = "Project Server Service Application"
$ProjectServicePool   = "Project Service Pool"
$ProjectAppPool       = "Project App Pool"
$ProjectSiteName      = "Project Management Office"
$ManagedPath          = "PWA"
$WSS_ContentDB        = "SP19_PWAContent"
# Create credentials
$credServiceSP  = New-Object System.Management.Automation.PSCredential -ArgumentList @($ServiceSP,(ConvertTo-SecureString -String $ServicePass -AsPlainText -Force))
################################################################
# create Managed Account
$ManagedAcct = Get-SPManagedAccount -Identity $ServiceSP -ErrorAction SilentlyContinue
If ($ManagedAcct -eq $null)
    {
    Write-Host -ForegroundColor Yellow "Create Managed Account: $ServiceSP "
    $ManagedAcct = New-SPManagedAccount -Credential $credServiceSP -Verbose
    }
else
    {Write-Host -ForegroundColor Green "Managed Account $ServiceSP Already Created"}
################################################################
# Create Project Service Pool
$ServicePool = Get-SPServiceApplicationPool | Where-Object {$_.Name -eq $ProjectServicePool } -ErrorAction SilentlyContinue
If ($ServicePool -eq $null)
    { 
    Write-Host -ForegroundColor Yellow "Create Project Service Pool: $ProjectServicePool"
    $ServicePool = New-SPServiceApplicationPool -Name $ProjectServicePool -Account $ServiceSP -Verbose
    }
Else
    {Write-Host -ForegroundColor Green "Project Service Pool: $ProjectServicePool Already Created"}
################################################################
#  Create Project Server Service and Enable Project Key
$ProjectServiceID = Get-SPServiceApplication |  Where-Object {$_.DisplayName -eq $ProjectServiceApp } -ErrorAction SilentlyContinue
If ($ProjectServiceID -eq $null)
    {
    Write-Host -ForegroundColor Yellow "Create Service Application: $ProjectServiceApp"
    $ProjectServiceID = New-SPProjectServiceApplication -Name $ProjectServiceApp -ApplicationPool $ServicePool -Proxy -verbose
    }
Else
    {Write-Host -ForegroundColor Green "Project Service Application: $ProjectServiceApp  Already Created"}

#################################################################
$ProjectLicnense = Get-ProjectServerLicense -Verbose
If ($ProjectLicense -eq $null) {
    Enable-projectserverlicense -Key $ProjectKey
    }
Else
    {Write-Host -ForegroundColor Green "Project License Enabled"}

#########################################################################
# Create Web Application on root that contains project server collection
#################################################################
$WA = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebAppName } 
if ($WA -eq $null)
    {
    Write-Host -ForegroundColor YELLOW "Create Project Web Application: $WebAppName"
    $AP = New-SPAuthenticationProvider -Verbose
    $WA = New-SPWebApplication -Name $WebAppName -port 80 -URL $WebAppURL -DatabaseName $WSS_ContentDB  -ApplicationPool $ProjectServicePool   -ApplicationPoolAccount (Get-SPManagedAccount $ServiceSP) -AuthenticationProvider $AP -Verbose -Confirm:$false
    }
Else
    {Write-Host -ForegroundColor Green "Project Web Application: $WebAppName  Already Created"}
#########################################################################
# Create Root Site when PWA is defined on root
$Root = Get-SPSite -WebApplication $WebAppName  | Where-Object {$_.URL -eq $SiteRootURL } 
if ($Root -eq $null)
    {
    Write-Host -ForegroundColor Yellow "Create Root Site: $SiteRootURL "
    $Root = New-SPSite -Url $WebAppURL -Template "STS#0" -Name $SiteRootName -OwnerAlias $ProjectOwner -SecondaryOwnerAlias $SecondOwner -Verbose 
    Start $SiteRootURL -Verbose
    # sets Permissions groups
    Start "$SiteRootUrl/_layouts/permsetup.aspx" -verbose
    }
else
    {
    Write-Host -ForegroundColor Green "Root Site: $SiteRootURL already Created"
    }

#########################################################################
# Provision PWA 
$PWA = Get-SPSite | Where-Object {$_.URL -eq $SitePwaURL } 
if ($PWA -eq $null)
    {
    Write-Host -ForegroundColor Green "Creating Project Site: $SitePwaURL"
    New-SPManagedPath $ManagedPath -WebApplication $WebAppURL -Explicit
    $PWA = New-SPSite -Url $SitePwaURL -Template "PWA#0" -Name $ProjectSiteName -OwnerAlias $ProjectOwner -SecondaryOwnerAlias $SecondOwner -Verbose 
 #  Enable-projectserverlicense -Key $ProjectKey 
    Enable-SPFeature PWASITE -Url $SitePwaURL -Verbose 
    Set-SPProjectPermissionMode -Url $SitePwaURL -Mode ProjectServer -Verbose
    Start $SitePwaURL
    }
else
    {
    Write-Host -ForegroundColor Green "Project Site: $SitePwaURL Already Created"
    }
}


