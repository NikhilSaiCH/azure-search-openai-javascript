# Set these two values first
$resourceGroup = ""
$subscriptionId = ""
$envName = "ragproject"

# STEP 1: Get latest SUCCESSFUL ARM template deployment ONLY
$deploymentName = az deployment group list `
  --resource-group $resourceGroup `
  --query "[?starts_with(name, 'Microsoft.Template') && properties.provisioningState=='Succeeded'] | sort_by(@,&properties.timestamp) | [-1].name" `
  -o tsv

if ([string]::IsNullOrWhiteSpace($deploymentName)) {
  throw "No valid ARM template deployment found."
}

Write-Host "Using deployment: $deploymentName"

# STEP 2: Get outputs from that deployment
$outputs = az deployment group show `
  --resource-group $resourceGroup `
  --name $deploymentName `
  --query "properties.outputs" `
  -o json | ConvertFrom-Json

if (-not $outputs) {
  throw "No outputs found in deployment $deploymentName"
}

# STEP 3: Create/select azd environment
azd env select $envName 2>$null
if ($LASTEXITCODE -ne 0) {
  azd env new $envName | Out-Null
}

# Helper function (fixes your earlier error)
function Set-AzdEnvValue {
  param(
    [string]$Name,
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw "Missing value for $Name"
  }

  azd env set "$Name=$Value" | Out-Null
}

# STEP 4: Set all environment variables
Set-AzdEnvValue "AZURE_RESOURCE_GROUP" $resourceGroup
Set-AzdEnvValue "AZURE_SUBSCRIPTION_ID" $subscriptionId
Set-AzdEnvValue "AZURE_LOCATION" $outputs.AZURE_LOCATION.value
Set-AzdEnvValue "AZURE_OPENAI_SERVICE" $outputs.AZURE_OPENAI_SERVICE.value
Set-AzdEnvValue "AZURE_SEARCH_SERVICE" $outputs.AZURE_SEARCH_SERVICE.value
Set-AzdEnvValue "AZURE_STORAGE_ACCOUNT" $outputs.AZURE_STORAGE_ACCOUNT.value
Set-AzdEnvValue "AZURE_CONTAINER_REGISTRY_NAME" $outputs.AZURE_CONTAINER_REGISTRY_NAME.value
Set-AzdEnvValue "AZURE_CONTAINER_REGISTRY_ENDPOINT" $outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT.value
Set-AzdEnvValue "AZURE_SEARCH_INDEX" $outputs.AZURE_SEARCH_INDEX.value
Set-AzdEnvValue "AZURE_OPENAI_CHATGPT_DEPLOYMENT" $outputs.AZURE_OPENAI_CHATGPT_DEPLOYMENT.value
Set-AzdEnvValue "AZURE_OPENAI_CHATGPT_MODEL" $outputs.AZURE_OPENAI_CHATGPT_MODEL.value
Set-AzdEnvValue "AZURE_OPENAI_EMBEDDING_DEPLOYMENT" $outputs.AZURE_OPENAI_EMBEDDING_DEPLOYMENT.value
Set-AzdEnvValue "AZURE_OPENAI_EMBEDDING_MODEL" $outputs.AZURE_OPENAI_EMBEDDING_MODEL.value
Set-AzdEnvValue "AZURE_SEARCH_SERVICE_SKU" "standard"
Set-AzdEnvValue "BACKEND_URI" $outputs.BACKEND_URI.value
Set-AzdEnvValue "WEBAPP_URI" $outputs.WEBAPP_URI.value

Write-Host ""
Write-Host " Environment setup complete"
Write-Host " Web App URL: $($outputs.WEBAPP_URI.value)"
Write-Host " Backend URL: $($outputs.BACKEND_URI.value)"