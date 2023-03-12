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
$IgnoreRules = $ignoreRules -split ',' -replace '^\s+|\s+$' | ForEach-Object { "$_" }
$ThreatAsWarningRules = $threatAsWarning -split ',' -replace '^\s+|\s+$' | ForEach-Object { "$_" }

$results = Select-Xml -XPath "//TEST" -Path $reportPath
if($results) { 
    if($results.Count -gt 0) {
        $countSuccess = 0
        $countFailed = 0
        $countUnknow = 0

        foreach($result in $results) {
            if ($IgnoreRules -NotContains $result.Node.Index) {
                switch($result.Node.Result.InnerText) {
                    "FAIL" { 
                        if ($ThreatAsWarningRules -Contains $result.Node.Index) {
                            $countUnknow++
                            Write-Host ("::warning::[FAIL][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                        } else {
                            $countFailed++
                            Write-Host ("::error::[FAIL][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                        }
                    }
                    "PASS" { 
                        $countSuccess++
                        Write-Host ("[PASS][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                    }
                    default { 
                        $countUnknow++
                        Write-Host ("::warning::[UNKNOW][{0}] {1}" -f $result.Node.Index,$result.Node.Description)
                    }
                }
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