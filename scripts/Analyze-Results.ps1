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

    $title = "WACK ($r_arch)"
    $summary = ""

    $countSuccess = 0
    $countFailed = 0
    $countUnknow = 0

    $summary += "`n## Results"
    $summary += "`n| ID | Description | Result |"
    $summary += "`n| - | - | - |"

    if($results.Count -gt 0) {
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
                            $summary += "`n| $r_id | $r_desc | :warning: FAIL |"
                        } else {
                            $countFailed++
                            Write-Host ("::error::[FAIL][{0}] {1}" -f $r_id,$r_desc)
                            "| $r_id | $r_desc | :x: FAIL |" >> $env:GITHUB_STEP_SUMMARY
                            $summary += "`n| $r_id | $r_desc | :x: FAIL |"
                        }
                    }
                    "PASS" { 
                        $countSuccess++
                        Write-Host ("[PASS][{0}] {1}" -f $r_id,$r_desc)
                        "| $r_id | $r_desc | :white_check_mark: PASS |" >> $env:GITHUB_STEP_SUMMARY
                        $summary += "`n| $r_id | $r_desc | :white_check_mark: PASS |"
                    }
                    default { 
                        $countUnknow++
                        Write-Host ("::warning::[UNKNOW][{0}] {1}" -f $r_id,$r_desc)
                        "| $r_id | $r_desc | :grey_question: UNKNOW |" >> $env:GITHUB_STEP_SUMMARY
                        $summary += "`n| $r_id | $r_desc | :grey_question: UNKNOW |"
                    }
                }
            } else {
                "| $r_id | $r_desc | :heavy_minus_sign: IGNORED |" >> $env:GITHUB_STEP_SUMMARY
                $summary += "`n| $r_id | $r_desc | :heavy_minus_sign: IGNORED |"
            }
        }
    }

    Write-Host ("{0} WACK tests succeeded" -f $countSuccess)
    Write-Host ("{0} WACK tests in unknow state" -f $countUnknow)
    Write-Host ("{0} WACK tests failed" -f $countFailed)

    if ($countFailed -gt 0) {
        Write-Output "conclusion=failure" >> $env:GITHUB_OUTPUT
        Write-Error "Certification has failed!"
    } else {
        Write-Output "conclusion=success" >> $env:GITHUB_OUTPUT    
        Write-Host "Certification has succeed!"
    }

    # "# Windows App Certification Kit ($r_arch)" >> $env:GITHUB_STEP_SUMMARY
    # "## Summary" >> $env:GITHUB_STEP_SUMMARY
    # "__Overall Result:__ $r_result" >> $env:GITHUB_STEP_SUMMARY
    # "__Operating System:__ $r_os" >> $env:GITHUB_STEP_SUMMARY
    # "__Operating System Version:__ $r_os_version" >> $env:GITHUB_STEP_SUMMARY
    # "__Architecture:__ $r_arch" >> $env:GITHUB_STEP_SUMMARY
    # "__Application Type:__ $r_app_type" >> $env:GITHUB_STEP_SUMMARY
    # "__Application Name:__ $r_app_name" >> $env:GITHUB_STEP_SUMMARY
    # "__Application Version:__ $r_app_version" >> $env:GITHUB_STEP_SUMMARY
    # "__Generation Time:__ $r_report_time" >> $env:GITHUB_STEP_SUMMARY

    # "## Results" >> $env:GITHUB_STEP_SUMMARY
    # "| ID | Description | Result |" >> $env:GITHUB_STEP_SUMMARY
    # "| - | - | - |" >> $env:GITHUB_STEP_SUMMARY

    $preSummary = ""
    $preSummary += "`n# Windows App Certification Kit ($r_arch)"
    $preSummary += "`n## Summary"
    $preSummary += "`n__Overall Result:__ " + $(if ($countFailed -gt 0) { ":x:" } else { ":white_check_mark:" })
    $preSummary += "`n__Operating System:__ $r_os"
    $preSummary += "`n__Operating System Version:__ $r_os_version"
    $preSummary += "`n__Architecture:__ $r_arch"
    $preSummary += "`n__Application Type:__ $r_app_type"
    $preSummary += "`n__Application Name:__ $r_app_name"
    $preSummary += "`n__Application Version:__ $r_app_version"
    $preSummary += "`n__Generation Time:__ $r_report_time"

    $summary = $preSummary + $summary

    $summaryPath = (Split-Path -parent $reportPath) + "\summary.md"
    $summary | Out-File $summaryPath -Encoding utf8

    Write-Output "name=check-wack-$r_arch" >> $env:GITHUB_OUTPUT
    Write-Output "title=$title" >> $env:GITHUB_OUTPUT
    Write-Output "summaryPath=$summaryPath" >> $env:GITHUB_OUTPUT
    
}