param(
	 [ValidateScript({
        	if (-not (Test-Path $_ -PathType Container)) {
            		throw "Directory $_ does not exist. Make sure you are on the .sln directory."
        	}
        	$true
    	})]
	[string]$SolutionPath = "."
)

# Backup folder for modified solution projects

$BackupProjectDirectory = Join-Path $SolutionPath "_backup"
New-Item -ItemType Directory -Force -Path $BackupProjectDirectory | Out-Null


# First cleanup object and bin directories

gci -Path $SolutionPath -Recurse -Directory |
	Where-Object { $_.Name -in @("bin", "obj") } |
	ri -Recurse -Force

# Target to x64 in project files, if you got a different file replace it
# As project files are XML documents instead of deal with them as a raw text you can treat them like a tree of elements

########################################################################################################################################
# Watch out! The current implementation overwrites ALL PropertyGroups you may intentionally mix targets such as Debug x86, Release x64 #
########################################################################################################################################

# TODO:  Create a menu giving the choice to overwrite every <PropertyGroup> or choosen ones.

gci -Path $SolutionPath -Recurse -Include *.csproj, *.vbproj | ForEach-Object {

    [xml]$xml = Get-Content $_.FullName
    $changed = $false

    $xml.Project.PropertyGroup | ForEach-Object {
        if ($_.PlatformTarget -eq "x86") {
            $_.PlatformTarget = "x64"
            $changed = $true
        }
    }

    if ($changed) {
        $BackupProjectDirectory = "$($_.FullName).bak"

    if ($changed) {
        $xml.Save($_.FullName)
        Write-Host "Updated: $($_.FullName)"
    }
}

# TODO: Add login of the replaced lines


# gci -Recurse -Include *.csproj, *.vbproj |  ForEach-Object { (Get-Content $_.FullName) -replace '<PlatformTarget>\s*x86\s*</PlatformTarget>', '<PlatformTarget>x64</PlatformTarget>' | Set-Content $_.FullName }

