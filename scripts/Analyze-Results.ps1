[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$reportPath,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$ignoreRules,

    [Parameter(Mandatory=$false, Position=2)]
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

    $name = "WACK ($r_arch)"
    $title = "Windows App Certification Kit ($r_arch)"
    $summary = ""

    $countSuccess = 0
    $countFailed = 0
    $countUnknow = 0

    $summary += "`n## Results"
    $summary += "`n| ID | Description | Optional | Result | Time |"
    $summary += "`n| - | - | - | - | - |"

    if($results.Count -gt 0) {
        foreach($result in $results) {
            $r_id = $result.Node.Index
            $r_desc = $result.Node.Description
            $r_time = $result.Node.EXECUTIONTIME
            $r_optional = $result.Node.OPTIONAL
            if ($IgnoreRules -notcontains $result.Node.Index) {
                switch($result.Node.Result.InnerText) {
                    "FAIL" { 
                        if ($ThreatAsWarningRules -contains $r_id) {
                            $countUnknow++
                            Write-Host ("::warning::[FAIL][{0}] {1}" -f $r_id,$r_desc)
                            $summary += "`n| $r_id | $r_desc | $r_optional | :warning: FAIL | $r_time |"
                        } else {
                            $countFailed++
                            Write-Host ("::error::[FAIL][{0}] {1}" -f $r_id,$r_desc)
                            $summary += "`n| $r_id | $r_desc  | $r_optional | :x: FAIL | $r_time |"
                        }
                    }
                    "PASS" { 
                        $countSuccess++
                        Write-Host ("[PASS][{0}] {1}" -f $r_id,$r_desc)
                        $summary += "`n| $r_id | $r_desc  | $r_optional | :white_check_mark: PASS | $r_time |"
                    }
                    default { 
                        $countUnknow++
                        Write-Host ("::warning::[UNKNOW][{0}] {1}" -f $r_id,$r_desc)
                        $summary += "`n| $r_id | $r_desc  | $r_optional | :grey_question: UNKNOW | $r_time |"
                    }
                }
            } else {
                $summary += "`n| $r_id | $r_desc  | $r_optional | :heavy_minus_sign: IGNORED | $r_time |"
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

    $preSummary = ""
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

    Write-Output "name=$name" >> $env:GITHUB_OUTPUT
    Write-Output "title=$title" >> $env:GITHUB_OUTPUT
    Write-Output "summaryPath=$summaryPath" >> $env:GITHUB_OUTPUT
    
} else {

    Write-Output "conclusion=failure" >> $env:GITHUB_OUTPUT 

    Write-Host "::warning::Unable to find a valid WACK execution report to analyze!"

}