[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$packagePath,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$reportName
)

# Ensure the error action preference is set to the default for PowerShell3, 'Stop'
$ErrorActionPreference = 'Stop'

$appcertpath = "${env:ProgramFiles(x86)}\Windows Kits\10\App Certification Kit\appcert.exe"
Write-Verbose "appcertpath = $appcertpath"

Write-Output "Reseting App certification..."
& "$appcertpath" reset

Write-Output "Initializing output directory..."
$reportoutputdirectory = "${env:GITHUB_WORKSPACE}\wack-certification"
Write-Verbose "reportoutputdirectory = $reportoutputdirectory"
New-Item -ItemType Directory -Force -Path $reportoutputdirectory | Out-Null

Write-Output "App certification is started..."
Write-Verbose "packagepath = $packagePath"
$reportoutpath = "$reportoutputdirectory\$reportName"
Write-Output "reportPath=$reportoutpath" >> $env:GITHUB_OUTPUT
& $appcertpath test -appxpackagepath "$packagePath" -reportoutputpath $reportoutpath