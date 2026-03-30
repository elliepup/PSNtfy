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
    <#
    .SYNOPSIS
    Sends a notification to an ntfy topic.

    .DESCRIPTION
    Sends a plain-text notification to an ntfy server and returns a structured
    response object suitable for automation and CI usage.

    .PARAMETER Message
    The message body to send to the ntfy topic.

    .PARAMETER Server
    The base URI of the ntfy server.

    .PARAMETER Topic
    The topic that will receive the notification.

    .PARAMETER Title
    An optional notification title.

    .PARAMETER Token
    An optional bearer token used for authenticated servers.

    .PARAMETER Priority
    An optional ntfy priority from 1 to 5.

    .PARAMETER Tags
    Optional tags to attach to the notification.

    .PARAMETER Click
    An optional URL opened when the notification is clicked.

    .PARAMETER Delay
    An optional ntfy delay expression such as 10m or 1h.

    .PARAMETER Filename
    An optional filename presented by ntfy clients.

    .PARAMETER Markdown
    Enables Markdown rendering for supported ntfy clients.

    .EXAMPLE
    Send-NtfyNotification -Server 'https://ntfy.sh' -Topic 'ops' -Message 'Deployment completed.'

    Sends a basic notification to the ops topic.

    .EXAMPLE
    'api healthy', 'worker healthy' | Send-NtfyNotification -Server 'https://ntfy.sh' -Topic 'status'

    Sends multiple piped messages to the status topic.
    #>
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
