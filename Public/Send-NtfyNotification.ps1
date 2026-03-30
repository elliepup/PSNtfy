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
        $statusCode = $null
        $responseHeaders = $null

        if (-not $PSCmdlet.ShouldProcess($uri.AbsoluteUri, 'Send ntfy notification')) {
            return
        }

        $headers = New-NtfyRequestHeaders `
            -Title $Title `
            -Token $Token `
            -Priority $Priority `
            -Tags $Tags `
            -Click $Click `
            -Delay $Delay `
            -Filename $Filename `
            -Markdown:$Markdown `
            -BoundParameters $PSBoundParameters

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

        New-NtfyNotificationResult `
            -Server $Server `
            -Topic $Topic `
            -Uri $uri `
            -Response $response `
            -StatusCode $statusCode `
            -Headers $responseHeaders
    }
}
