# Run this in the PowerShell window if you get an error about this file not being digitally signed
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$host.ui.RawUI.ForegroundColor = "White" # Reset the colors
$ErrorActionPreference = "Stop"

# This is the "Grip - Non Prod" subscription for the non prob environment. You may need to change this for a new environment
$TENANT_ID = "d8976bcc-d5c3-4d7d-90af-e5ac6cab2df6"
$SUBSCRIPTION_ID = "95f5a267-ee2c-49be-9222-b46dc8be7447"
$SUBSCRIPTION_NAME = "Grip - Non Prod"

$RESOURCE_GROUP_NAME = "rg-infra" # This must be unique to the Subscription
$STORAGE_ACCOUNT_NAME = "nfranonprod" # This must be unique globally
$LOCATION = "East US"

# This will open up a browser tab, where you will be asked to sign in
Write-Host "Signing into Azure" -ForegroundColor Cyan
az login --tenant $TENANT_ID
az account set --subscription=$SUBSCRIPTION_ID

# Create resource group
# ------------------------------------------------------
# This will create the infrastructure resource group for the subscription. We'll have one per Azure Subscription, but it may contain
# files (such as terraform state files) for multiple environments
Write-Host "Creating Resource Group - $RESOURCE_GROUP_NAME" -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
# ------------------------------------------------------
# As mentioned above, this storage account will contain tfstate files for multiple environments
Write-Host "Creating Infrastructure Storage Account" -ForegroundColor Cyan

az storage account create `
  --resource-group $RESOURCE_GROUP_NAME `
  --name $STORAGE_ACCOUNT_NAME `
  --sku Standard_LRS `
  --encryption-services blob `
  --https-only true

# Get storage account key
$STORAGE_ACCOUNT_KEY = $(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Now create the storage container that will contain the .tfstate files per environment (e.g. prod.tfstate)
Write-Host "Creating container for tfstate files" -ForegroundColor Cyan
az storage container create `
  --name terraform-state `
  --account-name $STORAGE_ACCOUNT_NAME `
  --account-key $STORAGE_ACCOUNT_KEY

# Creating developer groups
# ------------------------------------------------------
# We need to create these to put our developers into. The Application IDs (Client IDs) of these groups should
# be placed into the kv_developer_object_ids value in terraform config
Write-Host "Creating developer groups"  -ForegroundColor Cyan
az ad group create --display-name "Grip - Developers" --mail-nickname "GripDevelopers"
az ad group create --display-name "Grip - External Developers" --mail-nickname "GripExternalDevelopers"


# Create Azure DevOps (ADO) Service Connections
# ------------------------------------------------------
# Azure DevOps Service Connections allow us to run terraform and deploy our apps into the Azure Subscription
# from Azure DevOps Pipelines

$ADO_SERVICE_PRINCIPAL_URI = "http://ado-service-connection"
$ADO_SERVICE_PRINCIPAL_NAME = "$SUBSCRIPTION_NAME - ADO Service Connection"

# We can generate a new one in Azure DevOps
$ADO_PAT = "63w5r6evtom7b7d3brnlythamjma24wjbfsgrmbwhbkv5wkawvlq"

Write-Host "Creating Service Principal for Azure DevOps Service Connection" -ForegroundColor Cyan
$ADO_SERVICE_PRINCIPAL_PASSWORD = $(az ad sp create-for-rbac --name $ADO_SERVICE_PRINCIPAL_URI --role Contributor --query password --output tsv)
$ADO_SERVICE_PRINCIPAL_ID = $(az ad sp show --id $ADO_SERVICE_PRINCIPAL_URI --query appId --output tsv)

# We also need to give the Service Principal the User Access Administrator role, since it needs to assign roles in terraform
az role assignment create --assignee $ADO_SERVICE_PRINCIPAL_ID --role "User Access Administrator"

# We should give the Service Principal a nicer name so it's easy to find in Azure Portal
Write-Host "Renaming Service Principal for Azure DevOps Service Connection" -ForegroundColor Cyan
az ad app update --id $ADO_SERVICE_PRINCIPAL_ID --display-name "$ADO_SERVICE_PRINCIPAL_NAME"

# Now we need to connect to the Azure DevOps API to create the connection to our Azure Subscription
Write-Host "Creating Azure DevOps Service Connection to our Service Principal" -ForegroundColor Cyan
$url = "https://dev.azure.com/grip-tools/Grip/_apis/serviceendpoint/endpoints?api-version=5.1-preview.2"
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($ADO_PAT)"))
$body = @"
{
  "authorization": {
    "parameters": {
      "tenantid": "$TENANT_ID",
      "serviceprincipalid": "$ADO_SERVICE_PRINCIPAL_ID",
      "authenticationType": "spnKey",
      "serviceprincipalkey": "$ADO_SERVICE_PRINCIPAL_PASSWORD"
    },
    "scheme": "ServicePrincipal"
  },
  "data": {
    "subscriptionId": "$SUBSCRIPTION_ID",
    "subscriptionName": "$SUBSCRIPTION_NAME",
    "environment": "AzureCloud",
    "scopeLevel": "Subscription"
  },
  "name": "$SUBSCRIPTION_NAME - ADO Service Connection",
  "type": "azurerm",
  "url": "https://management.azure.com/"
}
"@

Invoke-RestMethod -Uri $url -Headers @{Authorization = "Basic $token" } -Method Post -Body $Body -ContentType application/json

Write-Host "Finished setting up environment" -ForegroundColor Cyan