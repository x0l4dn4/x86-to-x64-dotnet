param(
	 [ValidateScript({
        	if (-not (Test-Path $_ -PathType Container)) {
            		throw "Directory $_ does not exist. Make sure you are on the .sln directory."
        	}
        	$true
    	})]
	[string]$SolutionPath = "."
)

# First cleanup object and bin directories

gci -Path $SolutionPath -Recurse -Directory |
	Where-Object { $_.Name -in @("bin", "obj") } |
	ri -Recurse -Force

# Target to x64 in project files, if you got a different file replace it
# As project files are XML documents instead of deal with them as a raw text you can treat them like a tree of elements
# Watch out! you may have profiles such as Debug with PlataformTarget set to x86 you may won't to edit them.

gci -Recurse -Include *.csproj, *.vbproj | ForEach-Object {
    [xml]$xml = Get-Content $_.FullName
    $changed = $false

    $xml.Project.PropertyGroup | ForEach-Object {
        if ($_.PlatformTarget -eq "x86") {
            $_.PlatformTarget = "x64"
            $changed = $true
        }
    }

    if ($changed) {
        $xml.Save($_.FullName)
        Write-Host "Updated: $($_.FullName)"
    }
}

# TODO: Add login of the replaced lines


# gci -Recurse -Include *.csproj, *.vbproj |  ForEach-Object { (Get-Content $_.FullName) -replace '<PlatformTarget>\s*x86\s*</PlatformTarget>', '<PlatformTarget>x64</PlatformTarget>' | Set-Content $_.FullName }

