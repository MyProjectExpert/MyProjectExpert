#
#  Minor changes to code
#

Set-ExecutionPolicy -ExecutionPolicy Unrestricted
cd \ps1

# Lesson 3 - Remoting Concepts and Terminology
$PSVersionTable.Add("OS",(Get-WmiObject win32_operatingsystem).caption)
$PSVersionTable

# legacy Remoting
get-service bits -computername Duke-QA-APP
get-service bits -computername Duke-QA-APP | Select *
$computers = "Duke-qa-app", "Bigred", "WCC2MSI2"
get-service bits -ComputerName $computers | select machinename, name, status

# PowerShell Remoting
Invoke-Command {get-service bits } -ComputerName $computers 

$computers = "Duke-qa-app", "Bigred", "WCC2MSI2"
Measure-Command {get-service wuauserv, bits -ComputerName $computers | Select MachineName, Name, Status -OutVariable a}
$a 

Measure-Command {Invoke-Command {get-service wuauserv, bits -ComputerName $computers | Select MachineName, Name, Status -OutVariable b} }
$b 

Update-Help
get-help about_remote -ShowWindow

# Lesson 4 - Setting up PowerShell Remote

Enable-PSRemoting 
Enable-PSRemoting -Force   # disable prompts

# Using Group Policy
#   setup Group Policy
#     gpmc.msc   group policy edit
#     dsa.msc    active directory users and computers
Test-WSMan
Test-WSMan -ComputerName WCC2MSI2
Test-WSMan -ComputerName DUKE-QA-APP
#
#  Gets Product and Version
Test-WSMan WCC2MSI2
Test-WSMan -ComputerName WCC2MSI2 -Authentication Default
Test-WSMan -ComputerName WCC001vs -Authentication Default
Test-WSMan -ComputerName WCC2016APP -Authentication Default
Test-WSMan -ComputerName WCC2016SQL -Authentication Default
#
#  Disable WSMAN and to test
Test-WSMan -ComputerName WCC2019FARM -Authentication Default
get-service winrm -ComputerName WCC2019FARM
Test-Connection -ComputerName WCC2019FARM
ping WCC2019FARM
#
$script=@'
Try {
  test-wsman -erroraction stop | out-null
} catch {
 # Test failed so attempt to enble remoting
 Enable-PSremoting -Force
}
'@

Add-Content -Value $Script -Path 'c:\temp\ConfigurePRemoting.ps1'

Get-Content 'c:\temp\ConfigurePRemoting.ps1'
# Add this script to start script to test WSMAN

# Remove WSMan
#   by disabling Group Policy
#   Disable-PSRemoting cmdlet -- for each server or pc
#   Manually disable or stop WinRM service

Update-Help -Force -ea 0 

# Lesson 5 - One to One Remoting

Enter-PSSession -ComputerName WCC2MSI2 
hostname
whoami
get-service

Invoke-Command -ComputerName WCC2MSI2 {Get-Service} 

Get-PSSession

# Demo 
Get-command -noun PSSESSION 
Get-help Enter-PSSession

Test-WSMan WCC2MSI2

Enter-PSSession -computername WCC2MSI2
HOSTNAME.EXE
whoami.exe
Get-Service
Get-childitem c:\
get-process wsmprovhost -IncludeUserName | Select-Object UserName, StartTime
exit 

Enter-PSSession -computername DUKE-QA-APP
Get-WindowsFeature web* | Where-Object Installed
get-service | Where-Object {$_.Status -eq 'Running'}
$s = "bits"
gsv $s 
get-alias gsv 
get-service $s

get-module web* -list 
Import-Module web*
Get-Module

set-location iis:
# tempory PowerShell Session
Enter-PSSession -ComputerName Duke-QA-APP 
$p = Get-process
$p
exit 

# Create a PowerShell OBJECT
Get-PSSession
$s= New-PSSession -ComputerName Duke-QA-APP 
Enter-PSSession -Session $s

Invoke-Command -script { Get-ChildItem Cert:\LocalMachine\My } -ComputerName Bigred
Invoke-Command -script { Get-ChildItem  Cert:\LocalMachine\My } -ComputerName Duke-QA-APP
# Invoke-Command -script {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force; Add-PSSnapin Microsoft.SharePoint.PowerShell ; Get-SPFarm } -ComputerName Duke-QA-APP

Invoke-Command -ScriptBlock { $p = Get-Process} -ComputerName Bigred -Session $d
Invoke-Command {$p = Select-Object -first 3 } -session $d

Remove-PSSession 3

# 6 One to Many Remoting
# $computers = get-content c:\temp\computers.txt | New-PSSession -Credential wcc2prod\mawharton
$computerList = "BigRed", "Duke-QA-APP", "WCC001VS"
$cred = Get-Credential
$computers = $computerList | New-PSSession -Credential $cred
Invoke-Command -ScriptBlock {Get-service wuauserv } -session $computers
Invoke-Command -filepath c:\scripts\Weekly.ps1 -session $computers
Invoke-Command -filepath c:\temp\Weekly.ps1 -session $computers
Invoke-Command -ScriptBlock { get-ciminstance win32_operatingsystem } -session $computers |Select-Object PSComputerName, Caption, Installdate | format-list
Invoke-Command -ScriptBlock { tzutil /g } -session $computers 
Invoke-Command -ScriptBlock { [pscustomobject]@{"TimeZone" = tzutil /g } } -session $computers | Select-Object PSComputerName, TimeZone

$log="System"
Invoke-Command -ScriptBlock {get-eventlog $log -Newest 5 } -session $computers  #fails
Invoke-Command -ScriptBlock {get-eventlog $using:log -Newest 5 } -session $computers 
Invoke-Command -ScriptBlock {get-eventlog $using:log -Newest 5 } -session $computers | Format-Table -GroupBy PSComputerName -Property Timewritten, Source, message 

$log="System"
$sb = {param($log,$count) Get-Eventlog $log -Newest $count }
Invoke-Command $sb -ComputerName $computers -ArgumentList "Security", 1 | Select-Object Message, PSComputerName
Invoke-Command $sb -ComputerName $computers -ArgumentList "System", 1 | Select-Object Message, PSComputerName
#
#
$dcs = New-PSSession -ComputerName WCC2016AD  -cred $cred 
$dcs
Get-PSSession
Invoke-Command {get-service adws, dns, kdc} -Session $dcs | Sort-Object status 
#
Invoke-Command { dir $env:windir\ntds\ntds.dit } -Session $dcs | Sort-Object status 
#
#  run as background jobs
New-PSSession -ComputerName "BigRed","WCC001VS","DUke-QA-APP"
New-PSSession -ComputerName "WCC2016AD"
$all = Get-PSSession
$all.count 
Invoke-Command { get-hotfix } -session $all -AsJob | tee -Variable hot 
$hot 
$data = Receive-Job $hot -Keep 
$data.Count
$data | Select-Object -First 3
#
# Exeute remotely
$sb = { Start-Job { get-eventlog System -EntryType error } -Name SysErr }
$sb
Invoke-Command $sb -Session $all 
# check if jobs are still running
do { start-sleep -Milliseconds 10 } while (Invoke-Command { Get-job -State Running } -session  $all )
#
Invoke-Command {  get-job SysErr } -Session $all[0]
# check if job finished
Invoke-Command {  get-job SysErr } -Session $all
#
# Bring back all the data from all the sessions
$syserrs = Invoke-Command { Receive-Job syserr -Keep  } -Session $all
$syserrs.Count
$syserrs[0] | Select-Object * 
$syserrs | Group-Object Source -NoElement | Sort-Object count -Descending | Select-Object -First 10
#
# remoting the best 
Measure-Command { Invoke-Command {get-windowsfeature } -session $all | Where-Object installed |Select-Object *Name }
#
Measure-Command { Invoke-Command {get-windowsfeature | Where-Object installed |Select-Object *Name } -session $all }
#
#         REMOTING uSING SSL CERTIFICATE
# Requesting a cert
Start-Process 'https://wcc2016ad.wcc2prod.local/certsrv'

# Getting the Cert
$computer = "Duke-qa-APP"
$Cert =Invoke-Command { Get-ChildItem cert:\localmachine\my | Where-Object { $_.EnhancedKeyUsageList -match "Server Authentication" } | Select-Object -first 10 } -computer $computer 
$cert 
# or get from AD  -- not working 
$ad = Get-ADComputer $computer -property CERTIFICATE
$ad.CERTIFICATE
# Get thumbprint
$ad.CERTIFICATE.getcerthash 

# Confgure WSMAN
# check current connection 
Connect-WSMan -ComputerName $computer 
Get-ChildItem WSMAN:\$computer\Listener\L* -Recurse 

Get-command -Noun wsman*
help Get-WSManInstance -ShowWindow   # see Example 5
# Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address="*";Transport="http"}

#not case-sensitive
Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{address="*";Transport="HTTP"} -ComputerName DUKE-QA-APP 

# https Doesnt exist
Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{address="*";Transport="HTTPS"} -ComputerName DUKE-QA-APP 

get-help New-WSManInstance -ShowWindow # see example 1

$dns = Resolve-DnsName -Name $computer -TcpOnly 
$dns

#hastable of setting for new instance
$setting = @{
Address = $dns.Address
Transport = "HTTPS"
CertificateThumbprint = $cert.thumbprint
Enabled = "True"
Hostname = $cert.DnsNameList.unicode 
}
$setting

# define a hastable of parameter to splat new-wsmaninstance
$newParams = @{
ResourceURI = 'winrm/config/istener'
SelectorSet = @{Address="*";Transport="HTTPS"}
ValueSet = $setting
ComputerName = $computer 
}
$newParams 
$newParams.SelectorSet

#create new wsman instance
New-WSManInstance @newParams 

#
$newParams.Remove("ValueSet")
Get-WSManInstance @newParams

Get-ChildItem WSMAN:\$computer\Listener\L* -Recurse 

Disconnect-WSMan -ComputerName $computer
#
New-WSManInstance - ResourceURI winrm/config/Listener -SelectorSet @{Transport=HTTPS} -ValueSet @{Hostname="HOST";CertificateThumbprint="XXXXXXXXXX"}

# Configure the firewall to all HTTPS
Get-NetFirewallRule -Name WINRM-HTTP* -CimSession $computer |
 Select-Object PSComputerName, Name, Description, Profile, Enabled

$rule = Get-NetFirewallRule -Name WINRM-HTTP-IN* -CimSession $computer |
 Where-Object { $_.Profile -match "domain"}
$rule 

help New-NetFirewallRule

$paramHash = @{
Name = $rule.Name.Replace("HTTP","HTTPS") 
DisplayName = $rule.DisplayName.Replace("HTTP","HTTPS") 
Enabled = "True"
Profile = $rule.Profile
PolicyStore = $rule.PolicyStoreSource
Direction = 'Inbound'
Action = 'Allow'
Description = $rule.Description.Replace("5985", "5986")
LocalPort = 5986
Protocol = 'TCP'
CimSession = $computer 
}
$paramHash 

New-NetFirewallRule @paramHash

# Using Remoting with SSL
Test-WSMan -ComputerName $computer -UseSSL
Test-wsman -ComputerName Duke-QA-APP.wcc2prod.local -UseSSL 

Invoke-Command { Get-ChildItem c:\ -Hidden } -computer $computer 
Invoke-Command { Get-ChildItem c:\ -Hidden } -computer Duke-QA-APP.wcc2prod.local -UseSSL

NETSTAT.EXE

# PowerShell Remoting Security
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Get-ExecutionPolicy
set-item wsman:\localhost\Client\TrustedHosts -Value WCC2ASUS* -Concatenate 
set-item wsman:\localhost\Client\TrustedHosts -Value WCC2ASUS -Concatenate 
set-item wsman:\localhost\Client\TrustedHosts -Value 192.168.0.151 -Concatenate 
#  can specify IP adress, domain name, netbios name , wilcards permintterd

Test-Connection wcc2asus
Test-Connection 192.168.0.151 

Test-WSMan 192.168.0.151
get-help about_Remote_FAQ -ShowWindow
get-item wsman:\localhost\Client\TrustedHosts 

#
#  Setting up SSP
get-command -noun *credssp*
#
Get-WSManCredSSP
#
# enable on local machine
Enable-WSManCredSSP -Role client -DelegateComputer WCC2MSI2

Disable-WSManCredSSP -Role Client 
Remove-PSSession  21,20,22,23,24
get-pssession

#
# 9. Implicit Remoting
# region the problem

# region setting up implicit remoting
$SqLServer = "DUKE-QA-SQL"
$cred = Get-Credential
$sqlsession = New-PSSession -ComputerName $SqLServer -Credential $cred 
Invoke-Command -ScriptBlock { Import-Module SQLPS -DisableNameChecking } -Session $sqlsession
get-help Export-PSSession

Invoke-Command { get-command -Module sqlps } -session $sqlsession
$commands = "Invoke-SQLCMD", "Backup-SQldatabase", "Restore-SQLDatabase"
Export-PSSession -session $sqlsession -OutputModule SQLtools -Module SQLPS -CommandName $commands -Force -AllowClobber
Remove-PSsession $sqlsession 
Get-pssession 
# remove-module SQLtools

# Region using Implicit remoting
Import-Module SQLtools
get-command -Module SQLtools
# How does it know which server?
Invoke-sqlcmd "Exec sp_helpdb @dbname = 'DUKE_SharepointConfig'" 

# avoid conflict5s
Import-Module SQLtools -Prefix My -DisableNameChecking
get-command -module SQLtools

Invoke-MySqlcmd "Select @@version as Version, @@ServerName as Name"

# 10 Disconnected  Sessions
Invoke-Command -ScriptBlock { $sec = get-eventlog security -Newest 1000} -computer Duke-QA-APP -InDisconnectedSession

$psopt = New-PSSessionOption -IdleTimeout (60*60*4*1000) -OutputBufferingMode Drop   #  4 hours

$sess = New-Pssession -ComputerName Duke-QA-APP -SessionOption $psopt

Invoke-Command -ScriptBlock { get-wmiobject win32_product -AsJob} -Session $sess

Get-PSSession 

disconnect-session $sess 

$connected = Get-PSSession -ComputerName Duke-QA-APP | Connect-PSSession
$connected 

$results = Invoke-Command { get-job | receive-job -keep } -session $connected
$results

# 11 Troubleshooting PowerShell Remoting
$computerList = "WCC2MSI2", "Duke-QA-APP", "WCC001VS", "SDF"
Invoke-Command { get-process -IncludeUserName | sort-object VM -Descending | Select-object -First 5 } -computer $computerList | 
  Format-Table ID, name, Username, VM -AutoSize
  
  Test-Connection -computer $computerList

test-wsman -ComputerName Duke-QA-APP
test-wsman -ComputerName WCC001vs
test-wsman -ComputerName WCC2MSI2
test-wsman -ComputerName SDF  # This fails

# If this fails - next steps  - look at event logs

get-eventlog -logname system -Newest 200 -ComputerName Duke-QA-APP |
 Group-Object source -NoElement |
 Format-Table -AutoSize 

$evt = @{ logname="System"; Source="WinRM"; Newest=50;ComputerName="Duke-QA-APP"}
Get-EventLog @evt | Format-Table EntryType,Message -Wrap -AutoSize 

$evt.Source = "Service Control Manager"
$evt.Message = "*Remote Manager*"
Get-EventLog @evt | Format-Table EntryType, Message -Wrap -AutoSize 

Get-WinEvent -ListProvider *WinRm*

$logs = get-winevent -logname "Microsoft-Windows-WinRM/Operational" -MaxEvents 5 -computername DUKE-QA-APP
$log | Select-Object OpCodeDisplayName, User*, Time*, Message | format-list
$logs
[WMI]"root\cimv2:Win32_SID.sid=''"

$logs = get-winevent -logname "Microsoft-Windows-WinRM/Debug" -MaxEvents 5 -computername DUKE-QA-APP
$log | Select-Object OpCodeDisplayName, User*, Time*, Message | format-list
$logs
$logs = get-winevent -logname "Microsoft-Windows-WinRM/Analytic" -MaxEvents 5 -computername DUKE-QA-APP
$log | Select-Object OpCodeDisplayName, User*, Time*, Message | format-list
$logs

get-service winrm -ComputerName Duke-QA-APP

get-service winrm -ComputerName Duke-QA-APP | Start-Service -PassThru

Get-WmiObject win32_service -Filter "name='winrm'" -ComputerName Duke-QA-APP -Credential $cred
Get-WmiObject win32_service  -ComputerName Duke-QA-APP
Get-WmiObject win32_service  -ComputerName WCC2MSI2

Get-WmiObject win32_service -Filter "name='winrm'" -ComputerName Duke-QA-SQL

get-service winrm -ComputerName Duke-QA-APP |
set-service -StartupType Automatic -PassThru |
start-service -PassThru

$cred = Get-Credential
$PSVersionTable
Invoke-Command { $PSVersionTable } -ComputerName DUKE-QA-APP -Credential $cred
Invoke-Command { $PSVersionTable } -ComputerName DUKE-QA-SQL
Invoke-Command { $PSVersionTable } -ComputerName WCC001VS 
Invoke-Command { $PSVersionTable } -ComputerName BigRed

Get-NetFirewallRule *winrm* -CimSession DUKE-QA-SQL | Select-Object name, Description
Get-NetFirewallRule *winrm* -CimSession DUKE-QA-APP | Select-Object name, Description

connect-wsman -ComputerName Duke-QA-APP
cd WSMan:\Duke-QA-APP
Get-ChildItem
Get-ChildItem .\Listener\L* -Recurse
Get-ChildItem .\Service -Recurse
Get-ChildItem .\Service\RootSDDL | Select-Object Value 

# Start-Process 'https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-sddlstring?view=powershell-6'
s:\sddlparse (Get-item .\Service\RootSDDL).value    # tool from download 

Get-ChildItem .\Plugin\microsoft.powershell 
Get-ChildItem .\Plugin\microsoft.powershell\resources\res*
Get-ChildItem .\Plugin\microsoft.powershell\resources\Resource_1088764045
Get-ChildItem .\Plugin\microsoft.powershell\resources\Resource_1088764045\Security 
Get-ChildItem .\Plugin\microsoft.powershell\resources\Resource_1088764045\Security\Security_2055936308

cd c:\
Disconnect-WSMan -ComputerName Duke-QA-APP

winrm /?
Winrm g wsman/confg -remote:duke-qa-app





















