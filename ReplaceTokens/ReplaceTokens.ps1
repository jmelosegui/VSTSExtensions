<#
.SYNOPSIS
    Replace tokens in a set of files
.NOTES
    Can use minimatch patter to find out the target files
#>
[CmdletBinding()]
param(
)

Trace-VstsEnteringInvocation $MyInvocation

try {		

	[string]$SourcePath = Get-VstsInput -Name SourcePath -Require
	[string]$Contents = Get-VstsInput -Name Contents -Require
	[string]$DestinationPath = Get-VstsInput -Name DestinationPath
	[string]$TokenRegex = Get-VstsInput -Name TokenRegex
	[string]$TokenPrefix = Get-VstsInput -Name TokenPrefix	

	Write-Verbose "SourcePath = $SourcePath" -Verbose
	Write-Verbose "Contents = $Contents" -Verbose
	Write-Verbose "DestinationPath = $DestinationPath" -Verbose
	Write-Verbose "TokenRegex = $TokenRegex" -Verbose
	Write-Verbose "TokenPrefix = $TokenPrefix" -Verbose

	Import-Module "./ps_modules/VstsTaskSdk/VstsTaskSdk.psm1"

	. ./ReplaceFileTokens.ps1

	$Contents.Split([Environment]::NewLine) | ForEach-Object {
		Write-Host "Processing minimatch $(Join-Path $SourcePath $_)"
		Find-Files -LegacyPattern $(Join-Path $SourcePath $_) | ForEach-Object {
			Write-Host "Calling Replace-Tokens funtion on file $_"
			Replace-Tokens $_ $DestinationPath $TokenRegex $TokenPrefix
		}
	}
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}    	



