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
    $metadata = Select-Xml -XPath "//REPORT" -Path $reportPath
    $r_arch = $metadata[0].Node.TOOLSET_ARCHITECTURE
    $r_os = $metadata[0].Node.OS
    $r_os_version = $metadata[0].Node.VERSION
    $r_result = $metadata[0].Node.OVERALL_RESULT
    $r_result_icon = if ($r_result -ieq "PASS") { ":white_check_mark:" } else { ":x:" }
    $r_app_type = $metadata[0].Node.APP_TYPE
    $r_app_name = $metadata[0].Node.APP_NAME
    $r_app_version = $metadata[0].Node.APP_VERSION
    $r_report_time = $metadata[0].Node.ReportGenerationTime

    "# Windows App Certification Kit ($r_arch)" >> $env:GITHUB_STEP_SUMMARY
    "## Certification Summary" >> $env:GITHUB_STEP_SUMMARY
    "__Overall Result:__ $r_result" >> $env:GITHUB_STEP_SUMMARY
    "__Operating System:__ $r_os" >> $env:GITHUB_STEP_SUMMARY
    "__Operating System Version:__ $r_os_version" >> $env:GITHUB_STEP_SUMMARY
    "__Architecture:__ $r_arch" >> $env:GITHUB_STEP_SUMMARY
    "__Application Type:__ $r_app_type" >> $env:GITHUB_STEP_SUMMARY
    "__Application Name:__ $r_app_name" >> $env:GITHUB_STEP_SUMMARY
    "__Application Version:__ $r_app_version" >> $env:GITHUB_STEP_SUMMARY
    "__Generation Time:__ $r_report_time" >> $env:GITHUB_STEP_SUMMARY

    "## Certification Results" >> $env:GITHUB_STEP_SUMMARY
    "| ID | Description | Result |" >> $env:GITHUB_STEP_SUMMARY
    "| - | - | - |" >> $env:GITHUB_STEP_SUMMARY
    if($results.Count -gt 0) {
        $countSuccess = 0
        $countFailed = 0
        $countUnknow = 0

        foreach($result in $results) {
            $r_id = $result.Node.Index
            $r_desc = $result.Node.Description
            if ($IgnoreRules -notcontains $result.Node.Index) {
                switch($result.Node.Result.InnerText) {
                    "FAIL" { 
                        if ($ThreatAsWarningRules -contains $r_id) {
                            $countUnknow++
                            Write-Host ("::warning::[FAIL][{0}] {1}" -f $r_id,$r_desc)
                            "| $r_id | $r_desc | :warning: FAIL |" >> $env:GITHUB_STEP_SUMMARY
                        } else {
                            $countFailed++
                            Write-Host ("::error::[FAIL][{0}] {1}" -f $r_id,$r_desc)
                            "| $r_id | $r_desc | :x: FAIL |" >> $env:GITHUB_STEP_SUMMARY
                        }
                    }
                    "PASS" { 
                        $countSuccess++
                        Write-Host ("[PASS][{0}] {1}" -f $r_id,$r_desc)
                        "| $r_id | $r_desc | :white_check_mark: PASS |" >> $env:GITHUB_STEP_SUMMARY
                    }
                    default { 
                        $countUnknow++
                        Write-Host ("::warning::[UNKNOW][{0}] {1}" -f $r_id,$r_desc)
                        "| $r_id | $r_desc | :grey_question: UNKNOW |" >> $env:GITHUB_STEP_SUMMARY
                    }
                }
            } else {
                "| $r_id | $r_desc | :heavy_minus_sign: IGNORED |" >> $env:GITHUB_STEP_SUMMARY
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