##########################################################
#
# Author: Michael Wharton
# Date: 04/24/2019
# Description: Configure SharePoint Usage and Health Data Collction
##########################################################
Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#####################################
$usageName   = "Usage and Health data collection" 
$usageDBName = "SP16_WSS_Logging"   
##########################################################
#  Create Usage and Health Data Collection Servcie Application Service
##########################################################
$UsageDataApp  = GET-SPUsageApplication
$UsageInstance = Get-SPUsageService
if (-not $UsageDataApp) {
   #$UsageDataApp= New-SPUsageApplication -Name $usageName  -Verbose # Creates log files
   $UsageDataApp = New-SPUsageApplication -Name $usageName -DatabaseName $usageDBName -UsageService $usageInstance -Verbose
}
##########################################################
#  Start Usage and Health Data Collection
$UsageInstance = Get-SPUsageService
$UsageInstance.Provision()
$UsageInstance.AutoProvision = $true
$UsageInstance.Update()
$UsageInstance.Status
#  Start Usage and Health Data Collection Proxy
$UP = Get-SPServiceApplicationProxy 
$UP.Provision()
#
Get-SPServiceApplicationProxy |
    where {$_.TypeName -eq 'Usage and Health Data Collection Proxy'} |
    Select Status, Displayname
##########################################################
#  Modify Usage Application Service
##########################################################
$ua = Get-SPUsageApplication
Set-SPUsageApplication -Identity $ua -EnableLogging 

##########################################################
#  Finl Notes:  Compare and verify that the same logging is enabled between PROD and QA
#
##########################################################





##########################################################
#  Modify Usage Service
##########################################################
$us = Get-SPUsageService
# $log = "C:\logs" 
# $us | Set-SPUsageService -LoggingEnabled $true -UsageLogLocation $log
##########################################################
#  Modify Usage Providers
##########################################################
# Set-SPUsageDefinition -Identity "Page Requests" -DaysRetained 31
# Set-SPUsageDefinition -Identity "SQL Exceptions Usage" -Enable
# Set-SPUsageDefinition -Identity "SQL Exceptions Usage" -Enable:$false

# Get-SPUsageDefinition
##########################################################
#  Remove Usage and Health Data Collection Servcie Application Service
##########################################################
# Remove-SPUsageApplication -Identity $usageName -RemoveData 
# Remove-SPUsageApplication -Identity ba8bb0f4-83b1-4c56-8f8a-b85547c52756 -RemoveData 
<#
##########################################################
#  Get Performance counters
##########################################################
Get-SPDiagnosticsPerformanceCounter

Get-SPDiagnosticsPerformanceCounter | Format-List
Get-SPDiagnosticsPerformanceCounter | Format-Custom CategoryName

cls
Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'ASP.NET'} | Format-List

Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'Processor'} | Format-List

Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'Disk'} | Format-List
Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'PhysicalDisk'} | Format-List
Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'LogicalDisk'} | Format-List

Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'Memory'} | Format-List

Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'Paging File'} | Format-List

Get-SPDiagnosticsPerformanceCounter | where {$_.CategoryName -eq 'NIC'} | Format-List

##########################################################
#
#  Add  Performance counters
#
##########################################################
Add-SPDiagnosticsPerformanceCounter -Category ASP.NET -Counter "Requests Queue"

Add-SPDiagnosticsPerformanceCounter -Category PhysicalDisk -Counter "Avg. Disk Queue Length" -AllInstances

Add-SPDiagnosticsPerformanceCounter -category Processor -counter "% Processor Time" -instance "_Total" -databaseserver

##########################################################
#
#  Remove Performance counters
#
##########################################################
Remove-SPDiagnosticsPerformanceCounter -category ASP.NET -Counter "Requests Queued"


##########################################################
#
#  Dashboard Monitoring
#
##########################################################

$content = ([Microsoft.SharePoint.Administration.SPWebService]:: ContentService) 
$appsetting = $content.DeveloperDashboardSettings 

$appsetting.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::On
 
$appsetting.DisplayLevel = [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]::Off
 
$appsetting.Update()

##########################################################
#
#  Monitoring SharePoint Storage
#  Note:  Site Settings Metrics report  under the Site Collection Administration 
##########################################################


#>

 