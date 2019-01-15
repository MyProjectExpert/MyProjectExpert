<#
    .DESCRIPTION
        Create repository for saving username/password, thus not requiring to save in PowerShell scripts.
        The file must be created on server running scripts.  It cannot be moved because hash uses hostname as seed.
    .AUTHOR
        Michael Wharton
    .DATE
        01/04/2019
    .NOTES
        Script to setup username and passwords in SAFE forward.
        Once done, PowerShell Scripts will not be required to show password.
        Dont update and store back to Github
#>

function Add-CredFile{
    Param([string]$un, [string]$pw, [string]$credFN)
    $secpass  = $pw |ConvertTo-SecureString -AsPlainText -Force  
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $un, $secPass  
    $cred | Export-Clixml -Path $credFN  
    write-host "Create Password File: " $credFN " for account: " $un  -ForegroundColor Yellow
}

function Add-LicenseFile{
    Param([string]$licenseKey, [string]$licenseFN)
    $secKey  = $licenseKey |ConvertTo-SecureString -AsPlainText -Force  
    $secKey | Export-Clixml -Path $licenseFN  
    write-host "Create License Key File: " $licenseKey  -ForegroundColor Yellow
}
# Create directory if not found
$path = "C:\safe"
If(!(test-path $path))
{
  New-Item -ItemType Directory -Force -Path $path
}

# local\mawharton
$userName = "acctName"
$passWord = "passWord"
$credFileName = "C:\safe\local-acctName.txt"
Add-CredFile $userName $passWord $credFileName

# domain\mawharton
$userName = "farmadmin"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-farmadmin.txt"
Add-CredFile $userName $passWord $credFileName

# domain\farmadmin
$userName = "ServiceSP"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSP.txt"
Add-CredFile $userName $passWord $credFileName

# domain\SericeSQL
$userName = "ServiceSQL"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSQL.txt"
Add-CredFile $userName $passWord $credFileName

# SharePoint Server License Key
$licenseKey = "aaaa-bbbb-ccccc-ddddd-eeeee-ffff"
$licenseFileName = "C:\safe\SharePoint-LicenseKey.txt"
Add-LicenseFile $licenseKey $licenseFileName

# Project Server License Key
$licenseKey = "aaaa-bbbb-ccccc-ddddd-eeeee-ffff"
$licenseFileName = "C:\safe\ProjectServer-LicenseKey.txt"
Add-LicenseFile $licenseKey $licenseFileName

# example to unencrypt credentials
# $credServiceSP        = Import-CliXml -Path 'C:\safe\domain-ServiceSP.txt’ 

# example to unencrypt license keys
# $secureKey = Import-CliXml -Path "C:\safe\SharePoint-License.txt"
# $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
# $SharePointLicenseKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

