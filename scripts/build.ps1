$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$site = Join-Path $root 'site'
$dist = Join-Path $root 'dist'
$schemaPath = Join-Path $root 'contracts\profile.schema.json'

if (Test-Path $dist) {
    Remove-Item $dist -Recurse -Force
}
New-Item -ItemType Directory -Path $dist | Out-Null
Copy-Item -Path (Join-Path $site '*') -Destination $dist -Recurse

$indexPath = Join-Path $dist 'index.html'
$index = Get-Content -Path $indexPath -Raw -Encoding utf8
if ($index -notmatch '<title>Ascendant</title>') {
    throw 'Placeholder title is missing.'
}
if ($index -notmatch 'name="robots"\s+content="noindex"') {
    throw 'Placeholder must stay noindex until a profile is published.'
}
if ($index -match 'Cloud Architect') {
    throw 'Placeholder must not carry a role claim.'
}

$configPath = Join-Path $dist 'staticwebapp.config.json'
$config = Get-Content -Path $configPath -Raw -Encoding utf8 | ConvertFrom-Json
if ($null -eq $config.globalHeaders.'X-Content-Type-Options') {
    throw 'Security headers are missing from staticwebapp.config.json.'
}

$schema = Get-Content -Path $schemaPath -Raw -Encoding utf8 | ConvertFrom-Json
$roles = @($schema.properties.identity.properties.roleLabels.items.enum)
$expected = @('Senior .NET Developer', 'Azure Developer', 'DevOps Engineer')
$drift = Compare-Object -ReferenceObject $expected -DifferenceObject $roles
if ($null -ne $drift) {
    throw 'Profile role labels drifted from the approved set.'
}

$forbidden = Get-ChildItem -Path $dist -Recurse -File | Where-Object {
    $_.Name -eq '.env' -or $_.Extension -in @('.tfstate', '.tfvars', '.pem', '.pfx', '.key')
}
if ($forbidden) {
    throw "Refusing to publish: $($forbidden.Name -join ', ')"
}

Write-Output "Built $dist"
