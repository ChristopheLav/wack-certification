[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$reportPath,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$ignoreRules,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$threatAsWarning
)

# Ensure the error action preference is set to the default for PowerShell3, 'Stop'
$ErrorActionPreference = 'Stop'

# Generate the exclusion rules list
$IgnoreRules = $ignoreRules -split ',' -replace '^\s+|\s+$' | ForEach-Object { $_ }
$ThreatAsWarningRules = $threatAsWarning -split ',' -replace '^\s+|\s+$' | ForEach-Object { $_ }

$results = Select-Xml -XPath "//TEST" -Path $reportPath
if($results) { 
    "## Metadata" >> $env:GITHUB_STEP_SUMMARY
    $metadata = Select-Xml -XPath "//REPORT" -Path $reportPath
    "__Overall Result:__ ${metadata[0].OVERALL_RESULT}" >> $env:GITHUB_STEP_SUMMARY
    "__Operating System:__ ${metadata[0].OS}" >> $env:GITHUB_STEP_SUMMARY
    "__Operating System Version:__ ${metadata[0].VERSION}" >> $env:GITHUB_STEP_SUMMARY
    "__Architecture:__ ${metadata[0].TOOLSET_ARCHITECTURE}" >> $env:GITHUB_STEP_SUMMARY
    "__Application Type:__ ${metadata[0].APP_TYPE}" >> $env:GITHUB_STEP_SUMMARY
    "__Application Name:__ ${metadata[0].APP_NAME}" >> $env:GITHUB_STEP_SUMMARY
    "__Application Version:__ ${metadata[0].APP_VERSION}" >> $env:GITHUB_STEP_SUMMARY
    "__Generation Time:__ ${metadata[0].ReportGenerationTime}" >> $env:GITHUB_STEP_SUMMARY

    "## Certification Results" >> $env:GITHUB_STEP_SUMMARY
    "| ID | Description | Result |" >> $env:GITHUB_STEP_SUMMARY
    "| - | - | - |" >> $env:GITHUB_STEP_SUMMARY
    if($results.Count -gt 0) {
        $countSuccess = 0
        $countFailed = 0
        $countUnknow = 0

        foreach($result in $results) {
            if ($IgnoreRules -notcontains $result.Node.Index) {
                switch($result.Node.Result.InnerText) {
                    "FAIL" { 
                        if ($ThreatAsWarningRules -contains $result.Node.Index) {
                            $countUnknow++
                            Write-Host ("::warning::[FAIL][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                            "| ${result.Node.Index} | ${result.Node.Description} | :warning: FAIL |" >> $env:GITHUB_STEP_SUMMARY
                        } else {
                            $countFailed++
                            Write-Host ("::error::[FAIL][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                            "| ${result.Node.Index} | ${result.Node.Description} | :x: FAIL |" >> $env:GITHUB_STEP_SUMMARY
                        }
                    }
                    "PASS" { 
                        $countSuccess++
                        Write-Host ("[PASS][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                        "| ${result.Node.Index} | ${result.Node.Description} | :white_check_mark: PASS |" >> $env:GITHUB_STEP_SUMMARY
                    }
                    default { 
                        $countUnknow++
                        Write-Host ("::warning::[UNKNOW][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                        "| ${result.Node.Index} | ${result.Node.Description} | :grey_question: UNKNOW |" >> $env:GITHUB_STEP_SUMMARY
                    }
                }
            } else {
                "| ${result.Node.Index} | ${result.Node.Description} | :heavy_minus_sign: IGNORED |" >> $env:GITHUB_STEP_SUMMARY
            }
        }

        Write-Host ("{0} WACK tests succeeded" -f $countSuccess)
        if ($countUnknow -gt 0) {
            Write-Host ("::warning::{0} WACK tests in unknow state" -f $countUnknow)
        } else {
            Write-Host ("{0} WACK tests in unknow state" -f $countUnknow)
        }
        if ($countFailed -gt 0) {
            Write-Host ("::error::{0} WACK tests failed" -f $countFailed)
            Write-Error "Certification has failed!"
        } else {
            Write-Host ("{0} WACK tests failed" -f $countFailed)
            Write-Host "Certification has succeed!"
        }
    }
}