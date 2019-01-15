<#
    .SYNOPSIS
        Walk thru creating IaaS with Windows 10 desktop
    .DESCRIPTION
        Create IaaS Windows 10 desktop
    .AUTHOR
        Michael Wharton
    .DATE
        01/01/2019
    .NOTES
        Make sure that VMs are running for AD 
    .FileName 
        5.0.CreateWindows10OnAzure.ps1
#>
$LoginRmAccount   = Login-AzureRmAccount   #  must log into Azure
# $adminUser        = "username"
# $adminPass        = "password"
# $secpass  = $adminPass |ConvertTo-SecureString -AsPlainText -Force
# $cred  = New-Object System.Management.Automation.PSCredential -ArgumentList $adminUser, $secPass
#
$cred = Import-CliXml -Path 'C:\safe\local-mawharton.txt'
#
$groupName        = "demowin10"
$vmName           = "demowin10"          
$storageName      = "demowin10storage2"   # NOTE: must be lowercase 
$OSDiskName       = "demowin10OS" 
$DataDiskName     = "demowin10data1" 
$PIPname          = "demowin10pip"
$NICname          = "demowin10nic"
#
$DomainName       = "demo2dev.local"      # using my demo AD
$vnetName         = "demo2vnet"           # using my current VNET
$vnetGroupName    = "demo2dev"            # from my resouce group
$SecurityGrp      = "demo2Security"       # and security
#
$containerName    = "vhds"
$Location         = "East US 2"
$skuName          = "Standard_LRS"
$instanceSize     = "Standard_D2"
$localIP          = "192.168.0.14"
#
$publisherName    = "MicrosoftWindowsDesktop"
$offer            = "Windows-10"
$sku              = "rs5-pro"
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

########### Windows 10 VM   ########################################################################
$vmExists = Get-AzureRmVM -VMName $vmName -ResourceGroupName $GroupName -ErrorAction SilentlyContinue
if ($vmExists)  
{
Write-Host "  Skipping - Windows 10 VM Exits $vmName  "  -BackgroundColor Green -ForegroundColor Blue
}
else
{  
# 22 minutes 34 seconds
# 23 minutes 33 seconds
Measure-Command {
Write-Host "  Creating Windows 10 VM VM $vmName  "  -BackgroundColor Yellow -ForegroundColor Blue

# Setup Storage for SharePoint 2019 VM ####################################################################################
$StorageAccount = New-AzureRmStorageAccount  `
    -ResourceGroupName $GroupName  -Location $Location `
    -Name $storageName -Sku Standard_LRS  -Verbose
 
# Get storage Content Keys
$storeKey  = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName)
$storeKey1 = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName).value[0]
$storeKey2 = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName).value[1]

# create Storage context and links to blob, table, queue, file, endpoints
$storeContext = New-AzureStorageContext -StorageAccountName $storageName -StorageAccountKey $storeKey1 -Verbose

# Create a storage container 
$container = New-azurestoragecontainer -name $containerName -Permission Container -Context $storeContext -Verbose
# Get-AzureStorageContainer -Context $storecontext

$StorageAccount   =  Get-AzureRmStorageAccount -ResourceGroupName $GroupName -Name $storageName
$OSDiskUri        = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$DataDiskUri      = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName  + ".vhd"

############# Create PIP Address or Public IP address for Windows 10 VM #######################################
# Note: Get-module -ListAvailable  --- If prompt for Login-AzureRmAccount, it may be because multiple version of azure
$publicIP = New-AzureRmPublicIpAddress `
  -ResourceGroupName $GroupName  `
  -Location $Location `
  -AllocationMethod Static `
  -Name $PIPname -Verbose

############## Create network interface card for Windows 10 VM    #############################################
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $vnetGroupName -Name $vnetName   # using my VNET
$IPConfig = New-AzureRmNetworkInterfaceIpConfig -Name $NICname `
     -PrivateIpAddressVersion IPv4 -PrivateIpAddress $localIP `
     -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIP.Id 
$NSG = Get-AzureRmNetworkSecurityGroup -Name $SecurityGrp -ResourceGroupName $vnetGroupName
$nic = New-AzureRmNetworkInterface -Name $NICname -ResourceGroupName $groupname `
     -Location $location -IpConfiguration $ipconfig -NetworkSecurityGroupId $nsg.Id 

########### Create Windows 10 virtual machine  ###########################################################
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $instanceSize |
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  |
    Set-AzureRmVMSourceImage -PublisherName $PublisherName -Offer $offer -Skus $SKU -Version "latest"  |
    Set-AzureRmVMOSDisk     -Name $OSDiskName -VhdUri $OSDiskUri -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite |
    Add-AzureRmVMNetworkInterface -Id $nic.Id -Verbose 
#   Set-AzureRmVMDataDisk -VM $vm -Lun 0  -DiskSizeInGB 50 -Caching ReadWrite -Verbose
New-AzureRmVM -ResourceGroupName $GroupName -Location $Location -VM $vm -Verbose
   }
}

######  RDP Windows 10 VM Client    ################################################################################
# Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName  | Select IpAddress, name
$RDPIP = Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName | WHERE {$_.Name -eq $PIPname } | Select IpAddress
mstsc /v:($RDPIP.IpAddress)
#  host   demowcc10
#  login  azurecloud/youracct
#  Join   DEMO.LOCAL domain
#  reboot
