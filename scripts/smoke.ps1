param(
    [Parameter(Mandatory = $true)]
    [string]$Url
)

$ErrorActionPreference = 'Stop'

if ($Url -notmatch '^https://') {
    throw 'Smoke URL must use https.'
}

$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $true
$client = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout = [TimeSpan]::FromSeconds(30)
try {
    $response = $client.GetAsync($Url).GetAwaiter().GetResult()
    $final = $response.RequestMessage.RequestUri
    if ($final.Scheme -ne 'https') {
        throw 'Smoke request left https.'
    }
    if ([int]$response.StatusCode -ne 200) {
        throw "Expected HTTP 200 and received $([int]$response.StatusCode)."
    }
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    if ($body -notmatch '<title>Ascendant</title>') {
        throw 'Published page is missing the placeholder title.'
    }
}
finally {
    $client.Dispose()
    $handler.Dispose()
}

Write-Output "Smoke passed for $Url"
