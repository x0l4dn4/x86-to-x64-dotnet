param(
	 [ValidateScript({
        	if (-not (Test-Path $_ -PathType Container)) {
            		throw "Directory $_ does not exist. Make sure you are on the .sln directory."
        	}
        	$true
    	})]
	[string]$SolutionPath = "."
)


gci $SolutionPath -r -dir | ? { $_.Name -in "bin","obj" } | ri -r -fo  # You may have other aliases I just write them cuz who likes to write more???

# gci -Path $SolutionPath -Recurse -Directory | Where-Object { $_.Name -in @("bin", "obj") } | ri -Recurse -Force
