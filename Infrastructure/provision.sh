#!/bin/bash

# Set variables
RESOURCE_GROUP="CloudFolioRG"
LOCATION="canadacentral"
STORAGE_ACCOUNT="cloudfoliostorage"
COSMOS_ACCOUNT="cloudfoliocosmos"
COSMOS_DATABASE="CloudFolioDB"
COSMOS_CONTAINER="Items"
FUNCTION_APP="cloudfolioapi"
CDN_PROFILE="cloudfoliocdn"
CDN_ENDPOINT="cloudfolioendpoint"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Storage Account
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --kind StorageV2 --allow-blob-public-access true
#enabling static website hosting on the storage account
az storage blob service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --static-website \
  --index-document index.html \
  --404-document 404.html

# Create Cosmos DB Account
az cosmosdb create --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --locations regionName=$LOCATION failoverPriority=0 isZoneRedundant=False

# Create Cosmos DB Database
az cosmosdb sql database create --account-name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --name $COSMOS_DATABASE

# Create Cosmos DB Container
az cosmosdb sql container create --account-name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --database-name $COSMOS_DATABASE --name $COSMOS_CONTAINER --partition-key-path "/id"

# Create Function App
az functionapp create --resource-group $RESOURCE_GROUP --consumption-plan-location $LOCATION --runtime python --functions-version 4 --name $FUNCTION_APP --storage-account $STORAGE_ACCOUNT --os-type Linux
# Configure CORS on Function App- cross-origin resource sharing(allow requests from the static website)
az functionapp cors add --name $FUNCTION_APP --resource-group $RESOURCE_GROUP --allowed-origins https://$STORAGE_ACCOUNT.z9.web.core.windows.net

# Create CDN Profile
az cdn profile create --name $CDN_PROFILE --resource-group $RESOURCE_GROUP --sku Standard_Microsoft

# Create CDN Endpoint
az cdn endpoint create --name $CDN_ENDPOINT --profile-name $CDN_PROFILE --resource-group $RESOURCE_GROUP --origin $STORAGE_ACCOUNT.blob.core.windows.net --origin-host-header $STORAGE_ACCOUNT.blob.core.windows.net
