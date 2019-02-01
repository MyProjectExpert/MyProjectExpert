<#
    .SYNOPSIS
        Update Azure VM to override Remote Login fail
    .DESCRIPTION
        Update Azure VM to override Remote Login fail
    .AUTHOR
        Michael Wharton
    .DATE
        01/01/2019
    .PARAMETER
        Update values in constants below
    .EXAMPLE
        live demo
    .NOTES
        Make sure that VMs are running for AD 
  Azure Setup with VNET, Storage, AD Server VM, SQL Server VM and SharePoint Server VM
#>
###############################################################################################################
$LoginRmAccount   = Login-AzureRmAccount 
$GroupName        = "2019trialsp"         
$Location         = "East US 2"
$vmName           = "2019trialsp"
$StorageAccount   = "2019trialspstorage"
#
Get-AzureRmVMExtension -ResourceGroupName $groupname -VMName $vmName -Name bginfo   # VM extension exists
#
# Create RDPrescure file
$myString = @"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SecurityLayer" -value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -value 0
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "fAllowSecProtocolNegotiation" -value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
"@
# Create a file and call it MyScript.ps1
Set-Content "C:\temp\RDPRescue.ps1" -Value $myString 
#
Type "C:\temp\RDPRescue.ps1" 
# 
$ctx = $StorageAccount.Context
$sc = Get-AzureStorageContainer -Context $ctx  -Name "vhds" 
# Move file up-to-storage
Set-AzureStorageBlobContent -file "C:\temp\RDPRescue.ps1" `
    -Container $sc.name -Context $ctx -Blob "tRDPRescue.ps1"  
#
# Get-AzureStorageBlob -Container $SC.Name -Context $CTX | SELECT name
#
# Get-AzureStorageBlobContent -blob "RDPRescue.ps1" -Container $sc.name -Context $ctx -Destination "c:\temp\testrescue.ps1"
#
Get-AzureRmVMExtension -ResourceGroupName $groupname -VMName $vm.Name -Name "RDPRescue"

