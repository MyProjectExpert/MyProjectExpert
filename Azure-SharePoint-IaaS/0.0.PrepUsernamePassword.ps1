<<<<<<< HEAD
﻿<#
    .DESCRIPTION
        Create repository for saving username/password, thus not requiring to save in PowerShell scripts.
        The file must be created on server running scripts.  It cannot be moved because hash uses hostname as seed.
    .AUTHOR
        Michael Wharton
    .DATE
        01/04/2019
    .PARAMETER
        none - however update the constants below
        update username and password in script and run.
    .NOTES
        Script to setup username and passwords in SAFE forward.
        Once done, PowerShell Scripts will not be required to show password.
#>

function Create-CredFile{
    Param([string]$un, [string]$pw, [string]$credFN)
    $secpass  = $pw |ConvertTo-SecureString -AsPlainText -Force  
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $un, $secPass  
    $cred | Export-Clixml -Path $credFN  
    write-host "Create Password File: " $credFN " for account: " $un  -ForegroundColor Yellow
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
Create-CredFile $userName $passWord $credFileName

# domain\mawharton
$userName = "farmadmin"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-farmadmin.txt"
Create-CredFile $userName $passWord $credFileName

# domain\farmadmin
$userName = "ServiceSP"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSP.txt"
Create-CredFile $userName $passWord $credFileName

# domain\SericeSQL
$userName = "ServiceSQL"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSQL.txt"
Create-CredFile $userName $passWord $credFileName



=======
﻿<#
    .DESCRIPTION
        Create repository for saving username/password, thus not requiring to save in PowerShell scripts.
        The file must be created on server running scripts.  It cannot be moved because hash uses hostname as seed.
    .AUTHOR
        Michael Wharton
    .DATE
        01/04/2019
    .PARAMETER
        none - however update the constants below
        update username and password in script and run.
    .NOTES
        Script to setup username and passwords in SAFE forward.
        Once done, PowerShell Scripts will not be required to show password.
#>

function Create-CredFile{
    Param([string]$un, [string]$pw, [string]$credFN)
    $secpass  = $pw |ConvertTo-SecureString -AsPlainText -Force  
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $un, $secPass  
    $cred | Export-Clixml -Path $credFN  
    write-host "Create Password File: " $credFN " for account: " $un  -ForegroundColor Yellow
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
Create-CredFile $userName $passWord $credFileName

# domain\mawharton
$userName = "farmadmin"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-farmadmin.txt"
Create-CredFile $userName $passWord $credFileName

# domain\farmadmin
$userName = "ServiceSP"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSP.txt"
Create-CredFile $userName $passWord $credFileName

# domain\SericeSQL
$userName = "ServiceSQL"
$passWord = "passWord"
$credFileName = "C:\safe\domainName-ServiceSQL.txt"
Create-CredFile $userName $passWord $credFileName



>>>>>>> d9846c5976cd62bf7006b9e00df00208d8c55923
