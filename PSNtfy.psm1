function Resolve-NtfyTopicUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$Server,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Topic
    )

    $builder = [System.UriBuilder]::new($Server)
    $basePath = $builder.Path.TrimEnd('/')
    $escapedTopic = [System.Uri]::EscapeDataString($Topic)

    if ([string]::IsNullOrEmpty($basePath) -or $basePath -eq '/') {
        $builder.Path = "/$escapedTopic"
    }
    else {
        $builder.Path = "$basePath/$escapedTopic"
    }

    return $builder.Uri
}

function Get-NtfyErrorRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $exception = $ErrorRecord.Exception
    $responseBody = $null
    $statusCode = $null

    if ($exception.PSObject.Properties.Name -contains 'Response' -and $null -ne $exception.Response) {
        $statusCode = [int]$exception.Response.StatusCode

        if ($exception.Response.Content) {
            $responseBody = $exception.Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        }
    }

    $details = if ($responseBody) {
        "ntfy request failed with status code $statusCode. Response: $responseBody"
    }
    elseif ($statusCode) {
        "ntfy request failed with status code $statusCode."
    }
    else {
        "ntfy request failed. $($exception.Message)"
    }

    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $exception,
        'NtfyRequestFailed',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null
    )
    $errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($details)

    return $errorRecord
}

function Send-NtfyNotification {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [uri]$Server,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Topic,

        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [ValidateRange(1, 5)]
        [int]$Priority,

        [ValidateNotNullOrEmpty()]
        [string[]]$Tags,

        [uri]$Click,

        [ValidateNotNullOrEmpty()]
        [string]$Delay,

        [ValidateNotNullOrEmpty()]
        [string]$Filename,

        [switch]$Markdown
    )

    process {
        $uri = Resolve-NtfyTopicUri -Server $Server -Topic $Topic
        $target = $uri.AbsoluteUri
        $statusCode = $null
        $responseHeaders = $null

        if (-not $PSCmdlet.ShouldProcess($target, 'Send ntfy notification')) {
            return
        }

        $headers = @{}

        if ($PSBoundParameters.ContainsKey('Token')) {
            $headers['Authorization'] = "Bearer $Token"
        }
        if ($PSBoundParameters.ContainsKey('Title')) {
            $headers['Title'] = $Title
        }
        if ($PSBoundParameters.ContainsKey('Priority')) {
            $headers['Priority'] = [string]$Priority
        }
        if ($PSBoundParameters.ContainsKey('Tags')) {
            $headers['Tags'] = ($Tags -join ',')
        }
        if ($PSBoundParameters.ContainsKey('Click')) {
            $headers['Click'] = $Click.AbsoluteUri
        }
        if ($PSBoundParameters.ContainsKey('Delay')) {
            $headers['Delay'] = $Delay
        }
        if ($PSBoundParameters.ContainsKey('Filename')) {
            $headers['Filename'] = $Filename
        }
        if ($Markdown.IsPresent) {
            $headers['Markdown'] = 'yes'
        }

        $request = @{
            Method                  = 'POST'
            Uri                     = $uri
            Headers                 = $headers
            Body                    = $Message
            ContentType             = 'text/plain; charset=utf-8'
            StatusCodeVariable      = 'statusCode'
            ResponseHeadersVariable = 'responseHeaders'
            ErrorAction             = 'Stop'
        }

        try {
            $response = Invoke-RestMethod @request
        }
        catch {
            $PSCmdlet.WriteError((Get-NtfyErrorRecord -ErrorRecord $_))
            return
        }

        [pscustomobject]@{
            PSTypeName = 'PSNtfy.NotificationResult'
            Server     = $Server.AbsoluteUri.TrimEnd('/')
            Topic      = $Topic
            Uri        = $target
            StatusCode = $statusCode
            Id         = $response.id
            Event      = $response.event
            Time       = $response.time
            Expires    = $response.expires
            Message    = $response.message
            Raw        = $response
            Headers    = $responseHeaders
        }
    }
}

Export-ModuleMember -Function Send-NtfyNotification
