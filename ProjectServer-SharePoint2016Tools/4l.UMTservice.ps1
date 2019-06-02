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
$WebAppURL        = "http://SP16APP.domain.local"
$AppPool          = "SharePoint - 80"
$WSS_ContentDB    = "SP16_WSS_Content"
n tasks
