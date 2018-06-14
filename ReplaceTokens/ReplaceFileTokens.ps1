function Replace-Tokens {
	[CmdletBinding()]
	param(		
		[Parameter(Mandatory=$true)]
		[string]$SourcePath,
		[Parameter()]
		[string]$DestinationPath,
		[Parameter()]
		[string]$TokenRegex
	)

	Set-StrictMode -Version Latest
	$ErrorActionPreference = "Stop"

	Write-Verbose "Validate that SourcePath is a valid path: $SourcePath" -Verbose
	if (!(Test-Path -Path $SourcePath)) {
		throw "$SourcePath is not a valid path. Please provide a valid path"
	}

	$deleteSourceFile = $false

	if (!$DestinationPath) {
		$DestinationPath = $SourcePath
		Write-Verbose "Updated DestinationPath = $DestinationPath" -Verbose
	} else {
		$deleteSourceFile = $true
	}

	if (!$TokenRegex) {
		$TokenRegex = '__([\w.]+)__'
		Write-Verbose "Updated TokenRegex = $TokenRegex" -Verbose
	}

    function Get-VariableValue {
        param(
            [string]$matchVariableName
        )

        $result = New-Object -TypeName psobject -Property @{
            Name = $matchVariableName
            Value = $null            
        }

        if (Test-Path env:$matchVariableName) {
				
			$result.Value = (get-item env:$matchVariableName).Value
		}			
		else {

            $result.Value = Get-VstsTaskVariable -Name $result.Name -Default $null
        } 

        $result
    }

	Write-Output " "
	Write-Output "Replacing tokens in file '$SourcePath'"
	Write-Output "Generating file '$DestinationPath'."

	$inputContent = Get-Content $SourcePath;
	$inputContent | ForEach-Object { 
		$line = $_
		$_ | select-string $TokenRegex -AllMatches | ForEach-Object Matches | ForEach-Object {
			$matchToken = $_.Groups[0].Value
			$matchVariableName = $_.Groups[1].Value

            $token = Get-VstsTaskVariableInfo | Where-Object { 
                $_.Name -ieq $matchVariableName
            }

            if(!$token) {                
                Write-Error "*** No variable '$matchVariableName' found for token '$_'"
            } else {                

			    Write-Host "    Updating token '$_' with variable '$($token.Name)'"
				$line = $line -replace $matchToken, $($token.Value)
			    
                if (!$token.Value) {
                    $ReleaseEnvironmentName = Get-VstsTaskVariable -Name 'Release.EnvironmentName' -Default $null
			        Write-Warning "The value for the variable '$matchVariableName' in the environment '$($ReleaseEnvironmentName)' is empty." 
                }
            }		
		}
		return $line
	} | Set-Content -Path $DestinationPath

	if( $deleteSourceFile -eq $true) {
		Write-Verbose "Deleting file: $SourcePath"
		Remove-Item -Path $SourcePath
	}	

	Write-Output "Finished replacing tokens."
}