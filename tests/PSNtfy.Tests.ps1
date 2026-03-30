BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'PSNtfy.psd1'
    Import-Module $modulePath -Force
}

Describe 'Send-NtfyNotification' {
    It 'builds the expected request and returns a structured response' {
        InModuleScope PSNtfy {
            Mock Invoke-RestMethod {
                [pscustomobject]@{
                    id      = 'abc123'
                    event   = 'message'
                    time    = 1234567890
                    expires = 1234567999
                    message = 'Deployment completed successfully.'
                }
            }

            $result = Send-NtfyNotification `
                -Server 'https://ntfy.example.com/' `
                -Topic 'ops alerts' `
                -Message 'Deployment completed successfully.' `
                -Title 'Deploy Status' `
                -Priority 4 `
                -Tags 'deploy', 'success' `
                -Click 'https://example.com/build/123' `
                -Delay '10m' `
                -Filename 'build.log' `
                -Markdown

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                $Method -eq 'POST' -and
                $Uri.AbsoluteUri -eq 'https://ntfy.example.com/ops%20alerts' -and
                $Headers.Authorization -eq $null -and
                $Headers.Title -eq 'Deploy Status' -and
                $Headers.Priority -eq '4' -and
                $Headers.Tags -eq 'deploy,success' -and
                $Headers.Click -eq 'https://example.com/build/123' -and
                $Headers.Delay -eq '10m' -and
                $Headers.Filename -eq 'build.log' -and
                $Headers.Markdown -eq 'yes' -and
                $Body -eq 'Deployment completed successfully.' -and
                $ContentType -eq 'text/plain; charset=utf-8'
            }

            $result.PSTypeNames | Should -Contain 'PSNtfy.NotificationResult'
            $result.Topic | Should -Be 'ops alerts'
            $result.Id | Should -Be 'abc123'
            $result.Message | Should -Be 'Deployment completed successfully.'
        }
    }

    It 'does not send a request when WhatIf is used' {
        InModuleScope PSNtfy {
            Mock Invoke-RestMethod {}

            $null = Send-NtfyNotification `
                -Server 'https://ntfy.example.com' `
                -Topic 'ops' `
                -Message 'Skipped message' `
                -WhatIf

            Should -Invoke Invoke-RestMethod -Times 0 -Scope It
        }
    }

    It 'surfaces request failures to callers' {
        InModuleScope PSNtfy {
            Mock Invoke-RestMethod {
                throw [System.Exception]::new('boom')
            }

            {
                Send-NtfyNotification `
                    -Server 'https://ntfy.example.com' `
                    -Topic 'ops' `
                    -Message 'This should fail' `
                    -ErrorAction Stop
            } | Should -Throw
        }
    }

    It 'does not emit a result object when the request fails' {
        InModuleScope PSNtfy {
            Mock Invoke-RestMethod {
                throw [System.Exception]::new('boom')
            }

            $result = @(Send-NtfyNotification `
                -Server 'https://ntfy.example.com' `
                -Topic 'ops' `
                -Message 'This should fail' 2>&1)

            ($result | Where-Object {
                $_.PSObject.TypeNames -contains 'PSNtfy.NotificationResult'
            }) | Should -BeNullOrEmpty
        }
    }
}
