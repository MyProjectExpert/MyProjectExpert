<#
.AUTHOR
	Michael Wharton
.Date
	04/25/2019
.FILENAME
    BusinessDataConnectivityService.ps1
#>
#############################################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
############################################################################
$SQLServer_Name     = "SQLServer1"
$DBC_DatabaseName   = "SP16_BDC_ServiceDB"
#
$WebAppName         = "SharePoint - 80"
$WebAppURL          = "http://SP16_APP"
$DBC_Name           = "Business Data Connectivity Service"
$DBC_ProxyName      = "Business Data Connectivity Service"
$SharePointWebServicesDefault  = "SharePoint Web Services Default"
# Create credentials
$ServiceSP         = "domain\acctName"
$credServiceSP     = Import-CliXml -Path 'C:\safe\BDCacct.txt’
########################################################
#  Start Business Data Connectivity Service
################################################################
$BDConline = Get-SPServiceInstance | where {$_.TypeName -eq 'Business Data Connectivity Service'} 
if ($BDConline.Status -eq 'Online'){
    write-host "Business Data Connectivity is Online" -ForegroundColor Green
    }
else
    {
    write-host "Start Business Data Connectivity" -ForegroundColor Yellow
    Start-SPServiceInstance -Identity $BDConline.Id -Verbose
    }
########################################################
#  Note: pool doesnt show up in IIS until after a service is created
$WebServicePool = Get-SPServiceApplicationPool -Identity $SharePointWebServicesDefault -ErrorAction SilentlyContinue
if ($WebServicePool -eq $null) {
    Write-Host "Creating $SharePointWebServicesDefault Pool"  -ForegroundColor yellow
    $WebServicePool = $WebServicesDefault = New-SPServiceApplicationPool -Name $SharePointWebServicesDefault -Account (Get-SPManagedAccount $ServiceSP) -verbose 
    }
    else
    {
        Write-Host "$SharePointWebServicesDefault Pool already created" -ForegroundColor Green
    }
########################################################
#  create both the DBC service and proxy
########################################################
$BDCService = Get-SPServiceApplication |where {$_.TypeName -eq $DBC_Name } 
if ($BDCService -eq $null) {
        Write-Host "Creating $DBC_Name"  -ForegroundColor yellow
        $DBCservice = New-SPBusinessDataCatalogServiceApplication -Name $DBC_Name  -DatabaseServer $SQLServer_Name -DatabaseName $DBC_DatabaseName  -ApplicationPool $WebServicePool -Verbose
    }
    else
    {
        Write-Host "$DBC_Name already created" -ForegroundColor Green 
    }
<#
########################################################
#  Check and Start proxy Service
$BDCproxyStatus = Get-SPServiceApplicationProxy | where {$_.DisplayName -eq 'Business Data Connectivity Service'} 

########################################################
# Update Business Data Connectivity Settings
#
$DBCproxy = Get-SPServiceApplicationProxy |  Where-Object {$_.DisplayName -eq $DBC_ProxyName } 
if ($DBCproxy -ne $null){
    Write-Host "Updating $DBC_ProxyName"  -ForegroundColor yellow
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy  -Scope Database -ThrottleType Items   
    #  update the limits
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Database -ThrottleType Items   |
    Set-SPBusinessDataCatalogThrottleConfig -Maximum 10000000 -Default 2000

    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy  -Scope Database -ThrottleType Items   
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy  -Scope Database -ThrottleType Timeout

    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Global -ThrottleType MaxNumberOfModels
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Global -ThrottleType ModelSize

    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope OData -ThrottleType Size
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope OData -ThrottleType Timeout

    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Wcf -ThrottleType MetadataSize
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Wcf -ThrottleType Size
    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope Wcf -ThrottleType Timeout

    Get-SPBusinessDataCatalogThrottleConfig -ServiceApplicationProxy $DBCproxy -Scope WebService  -ThrottleType Size
    }

#>
