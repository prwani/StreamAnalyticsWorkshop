
# Print Azure account details
Write-Host "Current Azure account details:"
az account show | ConvertFrom-Json | Format-List | Out-String | Write-Host

# Connect to Azure
Connect-AzAccount -UseDeviceAuthentication

# Set variables (replace with your values)
$resourceGroupName = "rg-streamanalytics-workshop"
$eventhubNamespaceName = "eventhub-sa-workshop-1234"
$eventhubName = "telemetry-data"

# Ensure Az.Accounts and Az.EventHub modules are imported
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.EventHub -ErrorAction Stop

# Authenticate to Azure if not already authenticated
if (-not (Get-AzContext)) {
    Connect-AzAccount
}

# Get Event Hub connection string
Write-Host "Attempting to retrieve Event Hub connection string..."
try {
    $keys = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -NamespaceName $eventhubNamespaceName -Name "RootManageSharedAccessKey"
    $connectionString = $keys.PrimaryConnectionString
    
    if ([string]::IsNullOrEmpty($connectionString)) {
        throw "Connection string is null or empty"
    }
    
    Write-Host "Successfully retrieved connection string"
    Write-Host "Connection string preview: $($connectionString.Substring(0, [Math]::Min(50, $connectionString.Length)))..."
}
catch {
    Write-Error "Failed to retrieve Event Hub connection string: $_"
    Write-Host "Please verify:"
    Write-Host "1. Resource group '$resourceGroupName' exists"
    Write-Host "2. Event Hub namespace '$eventhubNamespaceName' exists"
    Write-Host "3. You have proper permissions to access the Event Hub"
    Write-Host "4. You are connected to the correct Azure subscription"
    exit 1
}

# Install Event Hubs library

# Ensure Az and Event Hubs modules are installed
if (-not (Get-Module -ListAvailable -Name Az.EventHub)) {
    Install-Module -Name Az.EventHub -Force -Scope CurrentUser
}
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az.Accounts -Force -Scope CurrentUser
}

# Function to send data to Event Hub

# Alternative approach: Use Azure PowerShell cmdlets directly
function Send-EventHubMessage-PowerShell {
    param (
        [string]$resourceGroupName,
        [string]$namespaceName,
        [string]$eventHubName,
        [string]$message
    )
    
    try {
        # Create a temporary file with the message
        $tempFile = [System.IO.Path]::GetTempFileName()
        $message | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
        
        # Use Azure CLI to send event data (correct command)
        # Note: Azure CLI doesn't have a direct "send message" command for Event Hubs
        # We'll use a different approach with Azure PowerShell modules
        
        # Try using Az.EventHub PowerShell module instead
        $eventData = [System.Text.Encoding]::UTF8.GetBytes($message)
        
        # This approach uses the EventData class if available
        # For now, we'll return an error to fall back to REST API
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        throw "Azure PowerShell Event Hub sending not implemented - using REST API instead"
    }
    catch {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        throw
    }
}

# Helper function to generate a SAS token (corrected version)
function New-SasToken {
    param (
        [string]$resourceUri,
        [string]$keyName,
        [string]$key
    )
    
    $expiry = [int][double]::Parse((Get-Date -Date (Get-Date).ToUniversalTime().AddHours(1) -UFormat %s))
    $stringToSign = [System.Net.WebUtility]::UrlEncode($resourceUri) + "`n" + $expiry
    
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = [System.Text.Encoding]::UTF8.GetBytes($key)
    $signature = [Convert]::ToBase64String($hmacsha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign)))
    
    $token = "SharedAccessSignature sr=" + [System.Net.WebUtility]::UrlEncode($resourceUri) + "&sig=" + [System.Net.WebUtility]::UrlEncode($signature) + "&se=" + $expiry + "&skn=" + $keyName
    
    return $token
}

function Send-EventHubMessage {
    param (
        [string]$connectionString,
        [string]$eventHubName,
        [string]$message
    )
    
    # Parse connection string
    $parts = @{}
    foreach ($part in $connectionString.Split(';')) {
        if ($part -match '=' -and $part.Trim() -ne '') {
            $splitIndex = $part.IndexOf('=')
            $k = $part.Substring(0, $splitIndex).Trim()
            $v = $part.Substring($splitIndex + 1).Trim()
            $parts[$k] = $v
        }
    }
    
    # Validate required parts
    if (-not $parts.ContainsKey('Endpoint')) {
        throw "Connection string missing Endpoint"
    }
    if (-not $parts.ContainsKey('SharedAccessKeyName')) {
        throw "Connection string missing SharedAccessKeyName"
    }
    if (-not $parts.ContainsKey('SharedAccessKey')) {
        throw "Connection string missing SharedAccessKey"
    }
    
    # Extract namespace from endpoint and construct proper HTTPS URL
    $endpoint = $parts['Endpoint'].TrimEnd('/')
    $namespace = $endpoint.Replace('sb://','').Replace('https://','')
    $keyName = $parts['SharedAccessKeyName']
    $key = $parts['SharedAccessKey']
    
    Write-Host "Debug: Extracted namespace: $namespace"
    
    # Create resource URI for SAS token (use the original sb:// format for SAS)
    $resourceUriForSas = $endpoint + "/" + $eventHubName
    $token = New-SasToken -resourceUri $resourceUriForSas -keyName $keyName -key $key
    
    # Create the Event Hubs REST API endpoint (use HTTPS)
    $uri = "https://$namespace/$eventHubName/messages"
    
    Write-Host "Debug: Sending to URI: $uri"
    Write-Host "Debug: SAS Resource URI: $resourceUriForSas"
    
    $headers = @{ 
        'Authorization' = $token
        'Content-Type' = 'application/json'
    }
    
    try {
        # Use Invoke-WebRequest for better error handling
        $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $message -ContentType 'application/json' -UseBasicParsing
        Write-Host "Debug: Response Status: $($response.StatusCode)"
        return $response
    }
    catch {
        Write-Host "Debug: REST API failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $responseBody = ""
            try {
                $responseBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
                Write-Host "Debug: Response Body: $responseBody"
            } catch {}
            Write-Host "Debug: HTTP Status: $($_.Exception.Response.StatusCode)"
        }
        throw
    }
}


# Test connectivity before starting the main loop
Write-Host "Testing Event Hub connectivity..."
$testMessage = @"
{
    "deviceId": "test-device",
    "timestamp": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')",
    "temperature": 25.0,
    "humidity": 50.0,
    "pressure": 1013.25,
    "location": {
        "lat": 47.6062,
        "lon": -122.3321
    }
}
"@

# Use REST API method (Azure CLI doesn't have direct Event Hub message sending)
$useAzureCLI = $false
Write-Host "Using REST API method to send messages..."

try {
    Send-EventHubMessage -connectionString $connectionString -eventHubName $eventhubName -message $testMessage
    Write-Host "✓ Test message sent successfully using REST API! Event Hub is reachable." -ForegroundColor Green
}
catch {
    Write-Error "✗ Test message failed: $_"
    Write-Host "Please check your Event Hub configuration and network connectivity."
    exit 1
}

Write-Host "`nStarting continuous data generation (Ctrl+C to stop)..."

# Loop to generate and send sample data every 5 seconds
while ($true) {
    $sampleData = @"
{
    "deviceId": "device-$('{0:D3}' -f (Get-Random -Minimum 1 -Maximum 101))",
    "timestamp": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')",
    "temperature": $(Get-Random -Minimum 20 -Maximum 40),
    "humidity": $(Get-Random -Minimum 30 -Maximum 80),
    "pressure": $(Get-Random -Minimum 1000 -Maximum 1100),
    "location": {
        "lat": 47.6062,
        "lon": -122.3321
    }
}
"@
    Write-Output "Sample telemetry data:"
    Write-Output $sampleData
    try {
        Send-EventHubMessage -connectionString $connectionString -eventHubName $eventhubName -message $sampleData
        Write-Host "Sent to Event Hub at $(Get-Date)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to send message: $_"
    }
    Start-Sleep -Seconds 5
}

