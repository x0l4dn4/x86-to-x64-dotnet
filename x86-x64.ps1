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

if (-not (Test-Path -Path $backupDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

# Log directory for any changes in the solutions files

$logDir = Join-Path $SolutionPath "_logs"
if (-not (Test-Path -Path $logDir -PathType Container)) {
	New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

# First cleanup object and bin directories

gci -Path $SolutionPath -Recurse -Directory |
	Where-Object { $_.Name -in @("bin", "obj") } |
	ri -Recurse -Force

########################################################################################################################################
# Watch out! The current implementation overwrites ALL PropertyGroups you may intentionally mix targets such as Debug x86, Release x64 #
########################################################################################################################################

# TODO:  Create a menu giving the choice to overwrite every <PropertyGroup> or choosen ones.

gci -Path $SolutionPath -Recurse -Include *.csproj, *.vbproj -File | ForEach-Object {

    [xml]$xml = Get-Content $_.FullName
    $changed = $false

   $xml.Project.PropertyGroup | ForEach-Object {

        # PlatformTarget
        if ($_.PlatformTarget -eq "x86") {
            $_.PlatformTarget = "x64"
            $changed = $true
        }

        # Prefer32Bit
        if ($_.Prefer32Bit -and $_.Prefer32Bit -ne "false") {
            $_.Prefer32Bit = "false"
            $changed = $true
        }

        # Condition
        if ($_.Condition -and $_.Condition -match "x86") {
            $_.Condition = $_.Condition -replace "x86", "x64"
            $changed = $true
        }

        # OutputPath
        if ($_.OutputPath -and $_.OutputPath -match "x86") {
            $_.OutputPath = $_.OutputPath -replace "\\x86\\", "\x64\"
            $changed = $true
        }
        # Platform
        if ($_.Platform -eq "x86") {
            $_.Platform = "x64"
            $changed = $true
        }

        # IntermediateOutputPath
        if ($_.IntermediateOutputPath -and $_.IntermediateOutputPath -match "x86") {
            $_.IntermediateOutputPath = $_.IntermediateOutputPath -replace "\\x86\\", "\x64\"
            $changed = $true
        }

        # BaseOutputPath
        if ($_.BaseOutputPath -and $_.BaseOutputPath -match "x86") {
            $_.BaseOutputPath = $_.BaseOutputPath -replace "\\x86\\", "\x64\"
            $changed = $true
        }
}

   if ($changed) {

        # Relative path
        $relativePath = Resolve-Path $_.FullName | ForEach-Object {
    		$_.Path.Substring((Resolve-Path $SolutionPath).Path.Length).TrimStart('\')
	}

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