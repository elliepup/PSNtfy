# PSNtfy

`PSNtfy` is a small PowerShell module for sending notifications to an `ntfy` server.

## Requirements

- PowerShell 7.2 or newer
- Access to an `ntfy` server such as `https://ntfy.sh` or your own self-hosted instance

## Installation

Clone the repository and import the module directly:

```powershell
Import-Module /path/to/PSNtfy/PSNtfy.psd1
```

If you keep the repository in one of PowerShell's module paths, you can import it by name:

```powershell
Import-Module PSNtfy
```

## Quick Start

Send a basic notification:

```powershell
Send-NtfyNotification `
    -Server 'https://ntfy.sh' `
    -Topic 'build-alerts' `
    -Message 'Deployment completed successfully.'
```

Add a title, tags, and priority:

```powershell
Send-NtfyNotification `
    -Server 'https://ntfy.sh' `
    -Topic 'ops' `
    -Title 'Nightly Backup' `
    -Message 'The backup finished without errors.' `
    -Tags backup,white_check_mark `
    -Priority 3
```

Use bearer-token authentication with a self-hosted server:

```powershell
$token = Get-Content ~/.config/ntfy/token.txt -Raw

Send-NtfyNotification `
    -Server 'https://notify.example.com' `
    -Topic 'private-alerts' `
    -Title 'Build Failed' `
    -Message 'Check the CI logs for details.' `
    -Token $token.Trim()
```

Pipe messages into the command:

```powershell
'api healthy', 'worker healthy', 'db healthy' |
    Send-NtfyNotification -Server 'https://ntfy.sh' -Topic 'service-status'
```

Preview the request with `-WhatIf`:

```powershell
Send-NtfyNotification `
    -Server 'https://ntfy.sh' `
    -Topic 'ops' `
    -Message 'This will not be sent.' `
    -WhatIf
```

## Supported Parameters

The module currently supports these core `ntfy` features:

- `-Title`
- `-Token`
- `-Priority`
- `-Tags`
- `-Click`
- `-Delay`
- `-Filename`
- `-Markdown`

## Design Notes

- The command returns a structured object so it can be used in scripts and CI pipelines.
- Topic names are URL-escaped before sending.
- Errors preserve HTTP status context where PowerShell exposes it.
- The module intentionally keeps the surface area small instead of wrapping every `ntfy` feature at once.

## Development

Planned repository quality checks:

- Pester tests for request construction and error handling
- `PSScriptAnalyzer` linting
- GitHub Actions validation on push and pull request

## Security

- Do not hardcode bearer tokens into scripts committed to source control.
- Prefer reading tokens from a secret store, environment variable, or local file outside the repository.
- Review your `ntfy` server's authentication and topic-permission settings before exposing it publicly.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
