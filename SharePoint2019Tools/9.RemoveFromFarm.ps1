<#
  Remove SharePoint Farm
  Run on SharePoint Server Node
    
#>

Set-ExecutionPolicy "Unrestricted" -ErrorAction SilentlyContinue -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Remove-SPConfigurationDatabase

# get-help Remove-SPConfigurationDatabase -Examples

