<#
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

$publisherName    = "MicrosoftSharePoint"
$offer            = "MicrosoftSharePointServer"
$sku              = "2013"


#>
###############################################################################################################
$LoginRmAccount   = Login-AzureRmAccount 
$locName = "East US 2"    # Set Location
# List publishers and look for Microsoft 
Get-AzureRmVMImagePublisher -Location $locName `
 | Where-Object PublisherName -like 'Microsoft*' `
 | Select -Property PublisherName 
# 
$pubName = "MicrosoftSQLServer" 
$pubName = "MicrosoftWindowsDesktop"
$pubName = "MicrosoftWindowsServer"
$pubName = "MicrosoftSharepoint" 
# List Offers
Get-AzureRmVMImageOffer -Location $locName -publisher $pubName `
 | Where-Object Offer -like 'Micro*' `
 | Select -Property Offer 
#
$offerName ="SQL2016-WS2016"
$offerName ="SQL2017-WS2016"
$offerName ="SQL2019-WS2016"
$offerName ="Windows-10"
$offerName ="WindowsServer"
$offerName ="MicrosoftSharepointServer"
# List SKU
Get-AzureRMVMImageSku -Location $locName -Publisher $pubName -Offer $offerName | Select Skus
Get-AzureRMVMImageSku -Location $locName -Publisher $pubName -Offer $offerName | Format-Table

$skuName="2019-Datacenter"
$skuName="2019-Datacenter-smalldisk"
$skuName="rs5-evd"
$skuName="rs5-pro"
$skuName="2008-R2-SP1"
$skuName="SQLDEV"
$skuName="2013"

# List Versions
Get-AzureRMVMImage -Location $locName -Publisher $pubName -Offer $offerName -Sku $skuName `
 | Select Version

write-host "location:  " $locName -ForegroundColor Yellow
write-host "publisher: " $pubName -ForegroundColor Yellow
write-host "offer:     " $offerName -ForegroundColor Yellow
write-host "skus:      " $skuName -ForegroundColor Yellow


