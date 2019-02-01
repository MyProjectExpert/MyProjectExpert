<#
Use for SharePoint Swing which upgrading windows server underpinning 
  frrom Windows 2008 R2 to Windows 2012 R2

Architect
DEMOVNET  - VNET
DEMOAD    - Active Directory must be running
DEMOSQL   - SQL configure as below
WEBAPP08  - Build    Windows 2008R2
WEBWEB08  - Build    Windows 2008R2
WEBWEB01  - Build    Windows 2012R2
WEBAPP01  - Build    Windows 2012R2
DEMOWIN10 - Windows 10 client

Post Activities
1) Update 
   EST Timezone, 
   uncheck RDP flag, 
   remove VP6
   Join Domain
2) Open Firewall port
3) Install SQL Server 2008 R2
4) SQL Server Configuration Access
   Add mawharton and farmadmin accounts to SQL
   enable SA account
5) Reboot
#>

