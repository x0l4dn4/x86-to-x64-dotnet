param(
	 [ValidateScript({
        	if (-not (Test-Path $_ -PathType Container)) {
            		throw "Directory $_ does not exist. Make sure you are on the .sln directory."
        	}
        	$true
    	})]
	[string]$SolutionPath = "."
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Backup folder for modified solution projects

$backupDir = Join-Path $SolutionPath "_backup"

if (-not (Test-Path -Path $backupDir -PathType Container))
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Log directory for any changes in the solutions files

$logDir = Join-Path $SolutionPath "_logs"
if (-not (Test-Path -Path $logDir -PathType Container))
	New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# First cleanup object and bin directories

gci -Path $SolutionPath -Recurse -Directory |
	Where-Object { $_.Name -in @("bin", "obj") } |
	ri -Recurse -Force

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

        # Relative path
        $relativePath = $_.FullName.Substring($SolutionPath.Length).TrimStart('\')

        # Backup path
        $backupPath = Join-Path $backupDir ($relativePath + "." + $timestamp + ".bak")

        # Log path
        $logPath = Join-Path $logDir ($relativePath + ".log")

        # Ensure directories exist
        New-Item -ItemType Directory -Force -Path (Split-Path $backupPath) | Out-Null
        New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

        # Backup
        Copy-Item $_.FullName $backupPath

        # Save changes
        $xml.Save($_.FullName)

        # Log entry
        $logEntry = @"
			[$(Get-Date)]
			Updated PlatformTarget x86 -> x64
			File: $($_.FullName)
			Backup: $backupPath

		   "@

        Add-Content -Path $logPath -Value $logEntry
    }
}

# TODO: Add logs of the replaced lines

