<#
    .SYNOPSIS
        Create Virtual Network  - WORK IN PROGRESS - NOT READY
    .DESCRIPTION
        Create Virtual Network
    .AUTHOR
        Michael Wharton
    .DATE
        1/7/2019
#>
$LoginRmAccount   = Login-AzureRmAccount 
# $adminUser        = "username"
# $adminPass        = "password"
# $secpass  = $adminPass |ConvertTo-SecureString -AsPlainText -Force
# $cred  = New-Object System.Management.Automation.PSCredential -ArgumentList $adminUser, $secPass
#
$cred = Import-CliXml -Path 'C:\safe\local-mawharton.txt’ 
#
$GroupName        = "demoad"
$DomainName       = "demodev.local"
$VNETname         = "demoVNET"
$Location         = "East US 2"
#
#
$SecurityGrp      = "demoSecurity"
#Select-AzureSubscription -SubscriptionName $RmAccount.Context.Subscription.Name | Get-AzureNetworkSecurityGroup -Name $SecurityGrp
#Get-AzureNetworkSecurityGroup -Name $SecurityGrp -Profile
#
$NICname          = "demonic"
$addressPreFix    = "192.168.0.0/16"
$addressVNET      = "192.168.0.0/8"
$subnetName0      = "demosubnet"      
$subnetName1      = "testsubnet"      
$subnetName2      = "LAB1subnet"      

$AddressSpace     = "10.0.0.0/16"
$subnetname1      = "DefaultSubnet"
$subnetrange1     = "10.0.0.0/24"
#
$subnetname2      = "DomainServicesSubnet"
$subnetrange2     = "10.0.1.0/24"
#
#################### Create NEW Resource Group  ################################################
$grpExists = Get-AzureRmResourceGroup -Name $GroupName -ErrorAction SilentlyContinue
if ($grpExists)  
{
Write-Host "  OK - Skip Creating Resource Group $GroupName  "  -BackgroundColor Green -ForegroundColor Blue
}
else
{
Write-Host "  Create Resource Group $GroupName  "  -BackgroundColor Yellow  -ForegroundColor Blue
New-AzureRmResourceGroup -ResourceGroupName $GroupName  -Location $Location -Verbose
}
#################### Create VNET  ################################################
#
$DefaultSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetname1 -AddressPrefix $subnetrange1 -Verbose
$DomainServicesSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetname1 -AddressPrefix $subnetrange1 -Verbose
#
# $VNET = New-AzureRmVirtualNetwork -Name $VNETname -ResourceGroupName $GroupName -Location $Location -AddressPrefix $AddressSpace -Subnet $DefaultSubnet,$DomainServicesSubnet
$VNET = New-AzureRmVirtualNetwork -Name $VNETname -ResourceGroupName $GroupName -Location $Location -AddressPrefix $AddressSpace -Subnet $DefaultSubnet -Verbose
Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetname2  -VirtualNetwork $VNET -AddressPrefix $subnetrange2  -Verbose
$VNET | Set-AzureRmVirtualNetwork -Verbose
