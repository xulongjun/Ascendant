# One-time bootstrap for Ascendant remote state and the Terraform identity.
# Dry-run is the default. -Apply creates Azure resources, including a paid storage account.
# Read docs/ARCHITECTURE.md before using -Apply.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    [Parameter(Mandatory = $true)]
    [string]$GitHubOwner,
    [Parameter(Mandatory = $true)]
    [string]$GitHubOwnerId,
    [Parameter(Mandatory = $true)]
    [string]$GitHubRepo,
    [Parameter(Mandatory = $true)]
    [string]$GitHubRepoId,
    [Parameter(Mandatory = $true)]
    [string]$NameSuffix,
    [string]$Location = 'westeurope',
    [switch]$Apply,
    [string]$ConfirmSubject
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Assert-Match {
    param(
        [string]$Value,
        [string]$Pattern,
        [string]$Name
    )
    if ($Value -notmatch $Pattern) {
        throw "$Name is not in the expected form."
    }
}

function Invoke-Az {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$AzArgs
    )
    & az @AzArgs | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Azure CLI command failed.'
    }
}

Assert-Match $SubscriptionId '^[0-9a-fA-F-]{36}$' 'SubscriptionId'
Assert-Match $TenantId '^[0-9a-fA-F-]{36}$' 'TenantId'
Assert-Match $GitHubOwner '^[A-Za-z0-9_.-]+$' 'GitHubOwner'
Assert-Match $GitHubRepo '^[A-Za-z0-9_.-]+$' 'GitHubRepo'
Assert-Match $GitHubOwnerId '^[0-9]+$' 'GitHubOwnerId'
Assert-Match $GitHubRepoId '^[0-9]+$' 'GitHubRepoId'
Assert-Match $NameSuffix '^[a-z0-9]{4,8}$' 'NameSuffix'
Assert-Match $Location '^[a-z0-9]+$' 'Location'

$productionRg = 'rg-ascendant-prd'
$stateRg = 'rg-ascendant-tfstate'
$storage = "stascendant$NameSuffix"
$container = 'tfstate'
$appName = 'sp-ascendant-terraform'
$subjects = @(
    "repo:${GitHubOwner}@${GitHubOwnerId}/${GitHubRepo}@${GitHubRepoId}:environment:production"
    "repo:${GitHubOwner}/${GitHubRepo}:environment:production"
)

Write-Output 'Bootstrap plan. No Azure change has been made yet.'
Write-Output "Subscription: $SubscriptionId"
Write-Output "Tenant: $TenantId"
Write-Output "Location: $Location"
Write-Output "State resource group: $stateRg"
Write-Output "State storage account: $storage (Standard_LRS, paid)"
Write-Output "State container: $container"
Write-Output "Production resource group: $productionRg"
Write-Output "App registration: $appName"
Write-Output 'Legal OIDC subjects:'
$subjects | ForEach-Object { Write-Output "  $_" }

if (-not $Apply) {
    Write-Output 'Dry run only. After oidc-probe.yml prints a subject, re-run with -Apply -ConfirmSubject <that subject>.'
    return
}

if ([string]::IsNullOrWhiteSpace($ConfirmSubject)) {
    throw '-ConfirmSubject is required with -Apply.'
}
if ($subjects -notcontains $ConfirmSubject) {
    throw '-ConfirmSubject must be one of the two subjects printed above.'
}
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI is not on PATH.'
}

Invoke-Az account set --subscription $SubscriptionId

$stateExists = az group exists --name $stateRg -o tsv
$prodExists = az group exists --name $productionRg -o tsv
if ($LASTEXITCODE -ne 0) {
    throw 'Could not check existing resource groups.'
}
if ($stateExists -eq 'true' -or $prodExists -eq 'true') {
    throw 'A target resource group already exists. Bootstrap is one-shot. Review the partial resources before trying again.'
}

$tags = @('project=ascendant', 'environment=prod', 'managed-by=bootstrap')
Invoke-Az group create --name $stateRg --location $Location --tags $tags
Invoke-Az group create --name $productionRg --location $Location --tags $tags
Invoke-Az storage account create `
    --name $storage `
    --resource-group $stateRg `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --https-only true `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --public-network-access Enabled

Invoke-Az storage account blob-service-properties update `
    --account-name $storage `
    --resource-group $stateRg `
    --enable-delete-retention true `
    --delete-retention-days 14 `
    --enable-container-delete-retention true `
    --container-delete-retention-days 14 `
    --enable-versioning true

$storageKey = az storage account keys list --resource-group $stateRg --account-name $storage --query '[0].value' -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($storageKey)) {
    throw 'Could not read a storage account key.'
}
try {
    Invoke-Az storage container create --name $container --account-name $storage --account-key $storageKey
}
finally {
    $storageKey = $null
    Remove-Variable storageKey -ErrorAction SilentlyContinue
}

Invoke-Az storage account update --name $storage --resource-group $stateRg --allow-shared-key-access false
Invoke-Az provider register --namespace Microsoft.Web --wait

$appId = az ad app create --display-name $appName --query appId -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($appId)) {
    throw 'App registration failed.'
}
$spId = az ad sp create --id $appId --query id -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($spId)) {
    throw 'Service principal creation failed.'
}

Start-Sleep -Seconds 20

$credential = @{
    name        = 'github-env-production'
    issuer      = 'https://token.actions.githubusercontent.com'
    subject     = $ConfirmSubject
    description = 'GitHub Actions production environment'
    audiences   = @('api://AzureADTokenExchange')
}
$tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("ascendant-fic-{0}.json" -f [guid]::NewGuid())
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($tempPath, ($credential | ConvertTo-Json -Compress), $utf8)
try {
    Invoke-Az ad app federated-credential create --id $appId --parameters $tempPath
}
finally {
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
}

$storageId = az storage account show --name $storage --resource-group $stateRg --query id -o tsv
$prodId = az group show --name $productionRg --query id -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($storageId) -or [string]::IsNullOrWhiteSpace($prodId)) {
    throw 'Could not resolve resource ids for role assignment.'
}

Invoke-Az role assignment create `
    --assignee-object-id $spId `
    --assignee-principal-type ServicePrincipal `
    --role 'Storage Blob Data Contributor' `
    --scope $storageId
Invoke-Az role assignment create `
    --assignee-object-id $spId `
    --assignee-principal-type ServicePrincipal `
    --role Contributor `
    --scope $prodId

Write-Output 'Bootstrap finished.'
Write-Output "AZURE_CLIENT_ID=$appId"
Write-Output "AZURE_TENANT_ID=$TenantId"
Write-Output "AZURE_SUBSCRIPTION_ID=$SubscriptionId"
Write-Output "TF_STATE_RESOURCE_GROUP=$stateRg"
Write-Output 'infra.yml hardcodes the state resource group and the tfstate container. Store the storage account name and NAME_SUFFIX as production environment variables.'
Write-Output "TF_STATE_STORAGE_ACCOUNT=$storage"
Write-Output "NAME_SUFFIX=$NameSuffix"
Write-Output 'Import the production resource group before the first Terraform apply:'
Write-Output "terraform import azurerm_resource_group.prd $prodId"
