function Get-NtfyErrorRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $exception = $ErrorRecord.Exception
    $responseBody = $null
    $statusCode = $null

    if ($ErrorRecord.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        $responseBody = $ErrorRecord.ErrorDetails.Message.Trim()
    }

    if ($exception.PSObject.Properties.Name -contains 'Response' -and $null -ne $exception.Response) {
        $statusCode = [int]$exception.Response.StatusCode

        if (-not $responseBody -and $exception.Response.Content) {
            try {
                $responseBody = $exception.Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            }
            catch {
                $responseBody = $null
            }
        }
    }

    $details = if ($responseBody -and $statusCode) {
        "ntfy request failed with status code $statusCode. Response: $responseBody"
    }
    elseif ($responseBody) {
        "ntfy request failed. Response: $responseBody"
    }
    elseif ($statusCode) {
        "ntfy request failed with status code $statusCode."
    }
    else {
        "ntfy request failed. $($exception.Message)"
    }

    $record = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'NtfyRequestFailed',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null
    )
    $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($details)

    return $record
}
