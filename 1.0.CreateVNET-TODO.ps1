﻿<#
    .SYNOPSIS
        Walk thru creating IaaS Trial SharePoint 2019 Server
    .DESCRIPTION
        Create IaaS SharePoint Server VM usnig Trial bits
    .AUTHOR
        Michael Wharton
    .DATE
        01/01/2019
    .PARAMETER
        none
    .EXAMPLE
        live demo
    .INPUTS
        none
    .OUTPUTS
        none
    .NOTES
        Make sure that VMs are running for AD

  Azure Setup with VNET, Storage, AD Server VM, SQL Server VM and SharePoint Server VM
#>
$LoginRmAccount   = Login-AzureRmAccount 
$cred             = Get-Credential -UserName 'mawharton' -Message 'Enter Password'   # Highplace4-9
$adminUser        = "mawharton"
$adminPass        = "Mountain9999"
#
$GroupName        = "wcc2019trialsp"
$DomainName       = "wcc2dev.local"
$VNETname         = "wcc2VNET"
#
$containerName    = "vhds"
$Location         = "East US 2"
$skuName          = "Standard_LRS"
$instanceSize     = "Standard_D2"
# 
# Get-AzureRoleSize | where {$_.Cores -eq 2 -and $_.MemoryInMB -gt 4000 -and $_.MemoryInMB -lt 9000 } | select instance_size, rolesizelabel
#
$SecurityGrp      = "wcc2Security"
#Select-AzureSubscription -SubscriptionName $RmAccount.Context.Subscription.Name | Get-AzureNetworkSecurityGroup -Name $SecurityGrp
#Get-AzureNetworkSecurityGroup -Name $SecurityGrp -Profile
#
$NICname          = "wcc2nic"
$addressPreFix    = "192.168.0.0/16"
$addressVNET      = "192.168.0.0/8"
$subnetName0      = "wcc2subnet"      # wcc2dev
$subnetName1      = "demosubnet"      # wcc2demo
$subnetName2      = "LAB1subnet"      # wcc2lab
#
$vmAD             = "wcc2016AD"       # do not change
$vmSQL            = "wcc2019trialsql" # usng wcc2016sql for sharepoint configureation 
$vmSP             = "wcc2019trialsp"
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
########### Sharepoint 2019 Server Trial VM   ########################################################################
$vmName           = "wcc2019trialsp"          #  using SharePoint 2019 trial as Active Directory
$storageName      = "wcc2019trialspstorage"   # NOTE: must be lowercase 
$vmExists = Get-AzureRmVM -VMName $vmName -ResourceGroupName $GroupName -ErrorAction SilentlyContinue

if ($vmExists)  
{
Write-Host "  OK - Skip Creating Trial SharePoint 2019 Server VM $vmName  "  -BackgroundColor Green -ForegroundColor Blue
}
else
{  # 13 minutes 25 seconds
Measure-Command {
Write-Host "  Creating Trial SharePoint 2019 Server VM $vmName  "  -BackgroundColor Yellow -ForegroundColor Blue
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

$OSDiskName       = "wcc2019trialOS" 
$DataDiskName     = "wcc2019trialData1" 
$StorageAccount   =  Get-AzureRmStorageAccount -ResourceGroupName $GroupName -Name $storageName
$OSDiskUri        = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$DataDiskUri      = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName  + ".vhd"
###############################################################################################################
############# Create PIP Address or Public IP address for SharePoint Server VM #######################################
# Note: Get-module -ListAvailable  --- If prompt for Login-AzureRmAccount, it may be because multiple version of azure
$PIPname = "wcc2019trialsppip"
#$wcc2019trialsppipName = $PIPname 
$wcc2019trialsppip = New-AzureRmPublicIpAddress `
  -ResourceGroupName $GroupName  `
  -Location $Location `
  -AllocationMethod Static `
  -Name $PIPname -Verbose
###############################################################################################################
############## Create network interface card for SharePoint Server VM    #############################################
$NICname      = "wcc2019trialspnic"
#$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $GroupName  -Name $VNETname  # doesnt exist
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName "wcc2dev" -Name $VNETname   # using prod VNET
#
$IPConfig = New-AzureRmNetworkInterfaceIpConfig -Name $NICname -PrivateIpAddressVersion IPv4 -PrivateIpAddress "192.168.0.10" -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $wcc2019trialsppip.Id 
#
$NSG = Get-AzureRmNetworkSecurityGroup -Name $SecurityGrp -ResourceGroupName wcc2dev
#
$wcc2019trialspnic = New-AzureRmNetworkInterface -Name $NICname -ResourceGroupName $groupname -Location $location -IpConfiguration $ipconfig -NetworkSecurityGroupId $nsg.Id 
#
###############################################################################################################
########### Create SharePoint 2019 Server virtual machine  ###########################################################
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $instanceSize |
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate  |
    Set-AzureRmVMSourceImage -PublisherName "MicrosoftSharePoint" -Offer "MicrosoftSharePointServer" -Skus "2019" -Version "latest"  |
    Set-AzureRmVMOSDisk     -Name $OSDiskName -VhdUri $OSDiskUri -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite |
    Add-AzureRmVMNetworkInterface -Id $wcc2019trialspnic.Id -Verbose
#   Set-AzureRmVMDataDisk -VM $vm -Lun 0  -DiskSizeInGB 50 -Caching ReadWrite -Verbose
New-AzureRmVM -ResourceGroupName $GroupName -Location $Location -VM $vm -Verbose
    }
}
#
###############################################################################################################
######  RDP into new SharePoint 2019 server VM    ################################################################################
# Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName  | Select IpAddress, name
$RDPIP = Get-AzureRmPublicIpAddress -ResourceGroupName $GroupName | WHERE {$_.Name -eq $trialsp2019pipName} | Select IpAddress
mstsc /v:($RDPIP.IpAddress)
#  host   TrialSP2019
#  login  azurecloud/mawharton
#  Join   WCC2DEMO.LOCAL domain
#  reboot
#  OPEN PORT 443
#  Start SharPoint 2019 Server Wizard

