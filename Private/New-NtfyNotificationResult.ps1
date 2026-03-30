function New-NtfyNotificationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$Server,

        [Parameter(Mandatory)]
        [string]$Topic,

        [Parameter(Mandatory)]
        [uri]$Uri,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Response,

        [AllowNull()]
        [object]$StatusCode,

        [AllowNull()]
        [object]$Headers
    )

    [pscustomobject]@{
        PSTypeName = 'PSNtfy.NotificationResult'
        Server     = $Server.AbsoluteUri.TrimEnd('/')
        Topic      = $Topic
        Uri        = $Uri.AbsoluteUri
        StatusCode = $StatusCode
        Id         = $Response.id
        Event      = $Response.event
        Time       = $Response.time
        Expires    = $Response.expires
        Message    = $Response.message
        Raw        = $Response
        Headers    = $Headers
    }
}
