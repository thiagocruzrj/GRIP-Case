param([string]$storageAccountRG,
    [string]$storageAccountName,
    [string]$SubscriptionId,
    [string]$sourceDirectory,
    [string]$storageContainerName = 'html')

# Select right Azure Subscription
Select-AzSubscription -SubscriptionId $SubscriptionId
 
# Get Storage Account Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -AccountName $storageAccountName).Value[0]

# Set AzStorageContext
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

if (Get-AzStorageContainer -Name $storageContainerName -Context $destinationContext -ErrorAction SilentlyContinue) {  
    Write-Host -ForegroundColor Magenta $storageContainerName "- container already exists."  
}  
else {  
    Write-Host -ForegroundColor Magenta $storageContainerName "- container does not exist."   
    Write-Host -ForegroundColor Magenta "Creating " $storageContainerName " container..."
    ## Create a new Azure Storage Account  
    New-AzStorageContainer -Name $storageContainerName -Context $destinationContext -Permission Container  
}       
 
# Generate SAS URI
$containerSASToken = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds(3600) -Name $storageContainerName -Permission rw

Write-Host -ForegroundColor Yellow $containerSASToken

$target = "https://$storageAccountName.blob.core.windows.net/$storageContainerName/$containerSASToken"

azcopy.exe copy $sourceDirectory $target --recursive=true
