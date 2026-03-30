$publicPath = Join-Path $PSScriptRoot 'Public'
$privatePath = Join-Path $PSScriptRoot 'Private'

foreach ($path in @($privatePath, $publicPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }

    foreach ($file in Get-ChildItem -Path $path -Filter '*.ps1' | Sort-Object Name) {
        . $file.FullName
    }
}

Export-ModuleMember -Function 'Send-NtfyNotification'
