
$ProjectKey           = "11111-22222-33333-44444-55555"

Set-ExecutionPolicy "Unrestricted"
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

################################################################
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
