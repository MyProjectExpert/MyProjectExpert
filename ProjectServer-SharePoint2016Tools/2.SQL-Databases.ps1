<#
Test 1
Test 3
#>

Get-NetFirewallProfile -Name Domain
Get-NetFirewallProfile -Name Private
Get-NetFirewallProfile -Name Public

$FireStat = Get-NetFirewallProfile -Name Domain
If ($FireStat.Enabled -eq 1) 
    { 
        Write-Host -ForegroundColor Green "Domain Firewall ON" }
    Else
      { Write-Host -ForegroundColor Red "Domain Firewall OFF"
   }

$FireStat = Get-NetFirewallProfile -Name Private
If ($FireStat.Enabled -eq 1) 
    { 
        Write-Host -ForegroundColor Green "Private Firewall ON" }
    Else
      { Write-Host -ForegroundColor Red "Private Firewall OFF"
   }

$FireStat = Get-NetFirewallProfile -Name Public
If ($FireStat.Enabled -eq 1) 
    { 
        Write-Host -ForegroundColor Green "Public Firewall ON" }
    Else
      { Write-Host -ForegroundColor Red "Public Firewall OFF"
   }

#################################################

New-NetFirewallRule -name "SQL Server(default)" -Group "SQL Server" -LocalPort  "1433" -Enabled True -DisplayName "SQL Server(default)" -Direction Inbound -Protocol "TCP" 
New-NetFirewallRule -name "SQL Browser Service" -Group "SQL Server" -LocalPort  "1434" -Enabled True -DisplayName "SQL Browser Service" -Direction Inbound -Protocol "UDP" 
#
#      Analysis Ports Required for SQL Analysis
#
New-NetFirewallRule -name "SQL Analysis Service Redirector" -Group "SQL Server" -LocalPort  "2382" -Enabled True -DisplayName "SQL Analysis Service Redirector" -Direction Inbound -Protocol "TCP" 
New-NetFirewallRule -name "SQL Analysis Service" -Group "SQL Server" -LocalPort  "2383" -Enabled True -DisplayName "SQL Analysis Service" -Direction Inbound -Protocol "TCP" 


