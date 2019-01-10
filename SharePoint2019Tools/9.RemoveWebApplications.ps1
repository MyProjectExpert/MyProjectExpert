<#
  Remove Web Applications in SharePoint Farm
  and delete the IIS and database   
#>

Set-ExecutionPolicy "Unrestricted" -ErrorAction SilentlyContinue -Confirm:$false -Verbose
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Function Remove-Web ($WebAppName){
Write-Host -ForegroundColor Yellow "Remove Web Application: " $WebAppName
Remove-SPWebApplication -Identity $WebAppName -RemoveContentDatabases:$true -DeleteIISSite:$true -Confirm:$false -Verbose
}

#######################################################
$WebAppName     = "DemoSP"
Remove-Web $WebAppName
