#######################################################
# Author: Michael Wharton
# Date: 05/14/2019
# Description: Secure Store configuration Project Server 2016 
#   1) Audit current Secure Store Configuration
#   2) Start Secure Store Serivce
#   3) Create new Secure Store
#   4) Configure Secure Store (Manual process)
#######################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#######################################################
$SqlServerName     = "SQLServer1"
$SecureStoreDB     = "SP16_SecureStoreDB"
$SecureStoreName   = "Secure Store Service"   # default name "Secure Store Service Application"
$SecureStoreProxy  = "Secure Store Service Proxy"
$SecureAppPool     = "Secure Store Pool"
$SharePointWebServicesDefault  = "SharePoint Web Services Default"
# Create credentials
$ServiceSP         = "domain\acctName"
$credServiceSP     = Import-CliXml -Path 'C:\safe\SecureStoreAcct.txt’
#######################################################
#  Start Secure store Service
################################################################
$SSSonline = Get-SPServiceInstance | where {$_.TypeName -eq 'Secure Store Service'} 
if ($SSSonline.Status -eq 'Online'){
    write-host "Secure Store Service is Online" -ForegroundColor Green
    }
else
    {
    write-host "Starting Secure Store Service" -ForegroundColor Yellow
    Start-SPServiceInstance -Identity $SSSonline.Id -Verbose
    }
#######################################################
#  Create SharePoint Web Services Default
#  note:  May be better to use is own pool Secure Application Pool
################################################################
$SecureServicePool = Get-SPServiceApplicationPool | Where-Object {$_.Name -eq $SharePointWebServicesDefault }
If ($SecureServicePool -eq $null )
    { 
    Write-Host -ForegroundColor Yellow "Create Secure Service Pool: $SharePointWebServicesDefault"
    $SecureServicePool = New-SPServiceApplicationPool -Name $SharePointWebServicesDefault  -Account $ServiceSP -Verbose
    }
Else
    {Write-Host -ForegroundColor Green "$SharePointWebServicesDefault Already Created"}

#######################################################
#  Create Secure store Service Application
################################################################
$SSSA = Get-SPServiceApplication | Where-object {$_.DisplayName -eq $SecureStoreName  }
If ($SSSA -eq $null) {
    Write-Host -ForegroundColor Yellow "Creating $SecureStoreName "
    $SSSA = New-SPSecureStoreServiceApplication -Name $SecureStoreName -ApplicationPool $SharePointWebServicesDefault -DatabaseName $SecureStoreDB -AuditingEnabled:$false -Verbose
    }

#  create Secure Store Proxy
$SSSAP = Get-SPServiceApplicationProxy | Where-object {$_.DisplayName -eq $SecureStoreProxy }
IF ($SSSAP -eq $null) {
    $SSSAP = New-SPSecureStoreServiceApplicationProxy -ServiceApplication $SSSA -Name $SecureStoreProxy -Verbose
}
#
Write-Host -ForegroundColor Green "Secure Service Application Completed"

<#
remove App Pool 
# Get-SPServiceApplicationPool | Where-Object {$_.Name -eq $SecureAppPool } | Remove-SPServiceApplicationPool 
# Get-SPServiceApplicationPool | Where-Object {$_.Name -eq 'SharePoint Web Services Default' } | Remove-SPServiceApplicationPool 
#>
