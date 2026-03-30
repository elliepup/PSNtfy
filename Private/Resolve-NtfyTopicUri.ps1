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
