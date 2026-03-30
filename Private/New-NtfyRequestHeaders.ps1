function New-NtfyRequestHeaders {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Token,
        [int]$Priority,
        [string[]]$Tags,
        [uri]$Click,
        [string]$Delay,
        [string]$Filename,
        [switch]$Markdown,
        [hashtable]$BoundParameters
    )

    $headers = @{}

    if ($BoundParameters.ContainsKey('Token')) {
        $headers['Authorization'] = "Bearer $Token"
    }
    if ($BoundParameters.ContainsKey('Title')) {
        $headers['Title'] = $Title
    }
    if ($BoundParameters.ContainsKey('Priority')) {
        $headers['Priority'] = [string]$Priority
    }
    if ($BoundParameters.ContainsKey('Tags')) {
        $headers['Tags'] = ($Tags -join ',')
    }
    if ($BoundParameters.ContainsKey('Click')) {
        $headers['Click'] = $Click.AbsoluteUri
    }
    if ($BoundParameters.ContainsKey('Delay')) {
        $headers['Delay'] = $Delay
    }
    if ($BoundParameters.ContainsKey('Filename')) {
        $headers['Filename'] = $Filename
    }
    if ($Markdown.IsPresent) {
        $headers['Markdown'] = 'yes'
    }

    return $headers
}
