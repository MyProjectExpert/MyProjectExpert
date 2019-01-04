<#
    .SYNOPSIS
        Walk thru creating IaaS SQL Server 2019
    .DESCRIPTION
        Create IaaS SQL Server VM usnig Trial bits
    .AUTHOR
        Michael Wharton
    .DATE
        01/04/2019
    .PARAMETER
        none - however update the constants below
    .EXAMPLE
        live demo
    .NOTES
        Make sure that VMs are running for AD

  Azure Setup with VNET, Storage, AD Server VM, SQL Server VM and SharePoint Server VM
#>
$LoginRmAccount   = Login-AzureRmAccount   #  must log into Azure
$cred             = Get-Credential -UserName 'mawharton' -Message 'Enter Password'   
$adminUser        = "username"
$adminPass        = "password"
#
$GroupName        = "2019trialsql"
$DomainName       = "dev.local"
$VNETname         = "VNET"
#
$containerName    = "vhds"
$Location         = "East US 2"
$skuName          = "Standard_LRS"
$instanceSize     = "Standard_D2"
# 
# Get-AzureRoleSize | where {$_.Cores -eq 2 -and $_.MemoryInMB -gt 4000 -and $_.MemoryInMB -lt 9000 } | select instance_size, rolesizelabel
#
$SecurityGrp      = "Security"
#Select-AzureSubscription -SubscriptionName $RmAccount.Context.Subscription.Name | Get-AzureNetworkSecurityGroup -Name $SecurityGrp
#Get-AzureNetworkSecurityGroup -Name $SecurityGrp -Profile
#
$NICname          = "2nic"
$addressPreFix    = "192.168.0.0/16"
$addressVNET      = "192.168.0.0/8"
$subnetName0      = "devsubnet"         # dev
$subnetName1      = "demosubnet"        # demo
$subnetName2      = "LAB1subnet"        # 2019trial
#
$vmAD             = "2016AD"       # do not change
$vmSQL            = "2019trialsql" # usng 2016sql for sharepoint configureation 
$vmSP             = "2019trialsp"
#
###############################################################################################################
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

###############################################################################################################
########### SQL Server Trial VM   ########################################################################
$vmName           = "2019trialsql"          #  using SharePoint 2019 trial as Active Directory
$storageName      = "2019trialsqlstorage"   # NOTE: must be lowercase 
$vmExists = Get-AzureRmVM -VMName $vmName -ResourceGroupName $GroupName -ErrorAction SilentlyContinue

if ($vmExists)  
{
Write-Host "  OK - Skip Creating SQL Server 2017 VM $vmName  "  -BackgroundColor Green -ForegroundColor Blue
}
else
{  # 13 minutes 25 seconds
Measure-Command {
Write-Host "  Creating Trial SQL Server VM  $vmName  "  -BackgroundColor Yellow -ForegroundColor Blue
###############################################################################################################
# Setup Storage for SharePoint 2019 VM ####################################################################################
$StorageAccount = New-AzureRmStorageAccount  `
    -ResourceGroupName $GroupName  -Location $Location `
    -Name $storageName -Sku Standard_LRS  -Verbose
#  Save the $storageAccount in an object
# $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $GroupName -Name $storageName
 
# Get storage Content Keys
$storeKey  = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName)
$storeKey1 = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName).value[0]
$storeKey2 = (Get-AzureRmStorageAccountKey -ResourceGroupName $GroupName -Name $storageName).value[1]

# create Storage context and links to blob, table, queue, file, endpoints
$storeContext = New-AzureStorageContext -StorageAccountName $storageName -StorageAccountKey $storeKey1 -Verbose

# Create a storage container 
$container = New-azurestoragecontainer -name $containerName -Permission Container -Context $storeContext -Verbose
# Look at what was created
# Get-AzureStorageContainer -Context $storecontext

$OSDiskName       = "2019trialsqlOS" 
$DataDiskName     = "2019trialsqlData1" 
$StorageAccount   =  Get-AzureRmStorageAccount -ResourceGroupName $GroupName -Name $storageName
$OSDiskUri        = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$DataDiskUri      = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName  + ".vhd"
###############################################################################################################
############# Create PIP Address or Public IP address for SharePoint Server VM #######################################
# Note: Get-module -ListAvailable  --- If prompt for Login-AzureRmAccount, it may be because multiple version of azure
$PIPname = "2019trialsqlpip"
#$2019trialtrialsppipName = $PIPname 
$2019trialsqlpip = New-AzureRmPublicIpAddress `
  -ResourceGroupName $GroupName  `
  -Location $Location `
  -AllocationMethod Static `
  -Name $PIPname -Verbose
###############################################################################################################
############## Create network interface card for SharePoint Server VM    #############################################
$NICname      = "2019trialsqlnic"
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName "2dev" -Name $VNETname   # using prod VNET
#
$IPConfig = New-AzureRmNetworkInterfaceIpConfig -Name $NICname -PrivateIpAddressVersion IPv4 -PrivateIpAddress  "192.168.0.11" -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $2019trialsqlpip.Id 
#
$NSG = Get-AzureRmNetworkSecurityGroup -Name $SecurityGrp -ResourceGroupName 2dev
#
$2019trialsqlnic = New-AzureRmNetworkInterface -Name $NICname -ResourceGroupName $groupname -Location $location -IpConfiguration $ipconfig -NetworkSecurityGroupId $nsg.Id 
###############################################################################################################
########### Create SharePoint 2019 Server virtual machine  ###########################################################
$offer ="SQL2016-WS2016"
$offer ="SQL2017-WS2016"
$offer ="SQL2019-WS2016"
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $instanceSize |
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  |
    Set-AzureRmVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer $offer -Skus "SQLDEV" -Version "latest"  |
    Set-AzureRmVMOSDisk     -Name $OSDiskName -VhdUri $OSDiskUri -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite |
    Add-AzureRmVMNetworkInterface -Id $2019trialsqlnic.Id -Verbose 
#   Set-AzureRmVMDataDisk -VM $vm -Lun 0  -DiskSizeInGB 50 -Caching ReadWrite -Verbose
New-AzureRmVM -ResourceGroupName $GroupName -Location $Location -VM $vm -Verbose
    }
}
#
###############################################################################################################
######  RDP into new SharePoint 2019 server VM    ################################################################################
# Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName  | Select IpAddress, name
$RDPIP = Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName | WHERE {$_.Name -eq $PIPname} | Select IpAddress
mstsc /v:($RDPIP.IpAddress)
#  host   TrialSP2019
#  login  azurecloud/youraccount
#  Join   DEMO.LOCAL domain
#  reboot
#  OPEN PORT 443
#  Start SharPoint 2019 Server Wizard


