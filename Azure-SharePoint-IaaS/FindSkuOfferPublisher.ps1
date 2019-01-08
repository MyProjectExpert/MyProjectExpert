<<<<<<< HEAD
﻿<#
    .SYNOPSIS
        Tool for finding SKU, OFFER and 
    .DESCRIPTION
        Tool for finding SKU, OFFER and 
    .AUTHOR
        Michael Wharton
    .DATE
        01/01/2019
    .PARAMETER
        Update values in constants below
    .EXAMPLE
        live demo
    .NOTES
#>
###############################################################################################################
$LoginRmAccount   = Login-AzureRmAccount 
$locName = "East US 2"    # Set Location
# List publishers and look for Microsoft 
Get-AzureRmVMImagePublisher -Location $locName `
 | Where-Object PublisherName -like 'Microsoft*' `
 | Select -Property PublisherName 
# 
$pubName = "MicrosoftSharepoint" 
$pubName = "MicrosoftSQLServer" 
$pubName = "MicrosoftWindowsDesktop"
$pubName = "MicrosoftWindowsServer"
# List Offers
Get-AzureRmVMImageOffer -Location $locName -publisher $pubName `
 | Where-Object Offer -like 'SQL*' `
 | Select -Property Offer 
#
$offerName ="MicrosoftSharepoint"
$offerName ="SQL2016-WS2016"
$offerName ="SQL2017-WS2016"
$offerName ="SQL2019-WS2016"
$offerName ="WindowsServer"
# List SKU
Get-AzureRMVMImageSku -Location $locName -Publisher $pubName -Offer $offerName | Select Skus
$skuName="SQLDEV"
$skuName="2019-Datacenter"
$skuName="2019-Datacenter-smalldisk"
# List Versions
Get-AzureRMVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName `
 | Select Version

write-host "location:  " $locName -ForegroundColor Yellow
write-host "publisher: " $pubName -ForegroundColor Yellow
write-host "offer:     " $offerName -ForegroundColor Yellow
write-host "skus:      " $skuName -ForegroundColor Yellow


=======
﻿<#
    .SYNOPSIS
        Tool for finding SKU, OFFER and 
    .DESCRIPTION
        Tool for finding SKU, OFFER and 
    .AUTHOR
        Michael Wharton
    .DATE
        01/01/2019
    .PARAMETER
        Update values in constants below
    .EXAMPLE
        live demo
    .NOTES
#>
###############################################################################################################
$LoginRmAccount   = Login-AzureRmAccount 
$locName = "East US 2"    # Set Location
# List publishers and look for Microsoft 
Get-AzureRmVMImagePublisher -Location $locName `
 | Where-Object PublisherName -like 'Microsoft*' `
 | Select -Property PublisherName 
# 
$pubName = "MicrosoftSharepoint" 
$pubName = "MicrosoftSQLServer" 
$pubName = "MicrosoftWindowsDesktop"
$pubName = "MicrosoftWindowsServer"
# List Offers
Get-AzureRmVMImageOffer -Location $locName -publisher $pubName `
 | Where-Object Offer -like 'SQL*' `
 | Select -Property Offer 
#
$offerName ="MicrosoftSharepoint"
$offerName ="SQL2016-WS2016"
$offerName ="SQL2017-WS2016"
$offerName ="SQL2019-WS2016"
$offerName ="WindowsServer"
# List SKU
Get-AzureRMVMImageSku -Location $locName -Publisher $pubName -Offer $offerName | Select Skus
$skuName="SQLDEV"
$skuName="2019-Datacenter"
$skuName="2019-Datacenter-smalldisk"
# List Versions
Get-AzureRMVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName `
 | Select Version

write-host "location:  " $locName -ForegroundColor Yellow
write-host "publisher: " $pubName -ForegroundColor Yellow
write-host "offer:     " $offerName -ForegroundColor Yellow
write-host "skus:      " $skuName -ForegroundColor Yellow


>>>>>>> d9846c5976cd62bf7006b9e00df00208d8c55923
