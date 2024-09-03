<#
.SYNOPSIS
    A script to generate a LaTeX diff between two Git commits or branches. Version 1.2

.DESCRIPTION
    This script uses Git and LaTeX tools to create a diff of a LaTeX document between two specified commits or branches.

.PARAMETER Old
    The old commit or branch to compare from. Default is 'HEAD'.

.PARAMETER New
    The new commit or branch to compare to. Default is '--' (working directory).

.PARAMETER Main
    The main LaTeX file to use. If not specified, the script will try to detect it.

.PARAMETER NoView
    Do not open the resulting PDF file.

.PARAMETER NoBibtex
    Do not run BibTeX. By default, BibTeX is run.

.PARAMETER Output
    The output PDF file name. Default is 'diff.pdf'.

.PARAMETER TmpdirPrefix
    The prefix for the temporary directory. Default is the system's TEMP directory.

.PARAMETER Silent
    Suppress verbose output.

.PARAMETER NoCleanup
    Do not clean up temporary files.

.PARAMETER Help
    Show help information.

.PARAMETER PdfViewer
    The PDF viewer to use. Default is the system's default viewer.

.EXAMPLE
    .\git-latexdiff.ps1 -Old "commit1" -New "commit2" -Main "main.tex" -Output "diff_output.pdf"

.NOTES
    Author: Rakhul Raj
    Date: 24-08-2024
#>
[CmdletBinding()]
param (
    [Parameter(Position=0, Mandatory=$false, HelpMessage="The old commit or branch to compare from. Default is 'HEAD'.")]
    [string]$Old = "HEAD",
    
    [Parameter(Position=1, HelpMessage="The new commit or branch to compare to. Default is '--' (working directory).")]
    [string]$New = "--",
    
    [Parameter(HelpMessage="The main LaTeX file to use. If not specified, the script will try to detect it.")]
    [string]$Main,
    
    [Parameter(HelpMessage="Do not open the resulting PDF file.")]
    [switch]$NoView,
    
    [Parameter(HelpMessage="Do not run BibTeX. By default, BibTeX is run.")]
    [switch]$NoBibtex,
    
    [Parameter(HelpMessage="The output PDF file name. Default is 'diff.pdf'.")]
    [string]$Output = 'diff.pdf',
    
    [Parameter(HelpMessage="The prefix for the temporary directory. Default is the system's TEMP directory.")]
    [string]$TmpdirPrefix = "$env:TEMP",
    
    [Alias("s")]
    [Parameter(HelpMessage="Suppress verbose output.")]
    [switch]$Silent,
    
    [Parameter(HelpMessage="Do not clean up temporary files.")]
    [switch]$NoCleanup,
    
    [Alias("h")]
    [Parameter(HelpMessage="Show help information.")]
    [switch]$Help,
    
    [Parameter(HelpMessage="The PDF viewer (full path of the exe file) to use. Default is the system's default viewer.")]
    [string]$PdfViewer
)

$ErrorActionPreference = "Stop"

function Write-Verbose-Custom {
    param([string]$Message)
    if (-not $Silent) {
        Write-Host $Message
    }
}
function Cleanup{
	if ($NoCleanup) {
		Write-Verbose-Custom "Keeping all generated files in $TmpDir"
	} else {       
		Write-Verbose-Custom "Cleaning up all files"
		Remove-Item -Recurse -Force $TmpDir
	}
}
# Display help if the Help switch is set
if ($Help) {
    Get-Help -Full $MyInvocation.MyCommand.Path
    exit
}
try{
	# Store the current directory
	$originalDir = Get-Location

	# Detect PDF Viewer if not specified
	if (-not $PdfViewer) {
		$PdfViewer = "start"  # Default to Windows' default program
		# if (Test-Path "C:\Program Files (x86)\Foxit Software\Foxit PDF Editor\FoxitPDFEditor.exe") {
			# $PdfViewer = "C:\Program Files (x86)\Foxit Software\FoxitPDFEditor.exe"
		# }
	}

	# Create temporary directories

	if (-not (Test-Path -Path $TmpdirPrefix)) {
		Write-Verbose-Custom "crat"
		New-Item -ItemType Directory -Path $TmpdirPrefix | Out-Null
		Write-Verbose-Custom "Directory created: $TmpdirPrefix"
	} else {
		Write-Verbose-Custom "Directory already exists: $TmpdirPrefix"
	}
	$TmpdirPrefix = Convert-Path $TmpdirPrefix
	$TmpDir = Join-Path $TmpdirPrefix "git-latexdiff-$([Guid]::NewGuid().ToString())"
	New-Item -ItemType Directory -Path $TmpDir | Out-Null
	$OldDir = Join-Path $TmpDir "old"
	$NewDir = Join-Path $TmpDir "new"
	New-Item -ItemType Directory -Path $OldDir, $NewDir | Out-Null

	Write-Verbose-Custom "Temporary directories created: $OldDir and $NewDir"

	# Determine main file if not specified
	if (-not $Main) {
		Set-Location $originalDir
		$Main = git grep -l '^\s*\\documentclass' | Select-Object -First 1
		if (-not $Main) {
			throw "No main file specified and couldn't detect one. Please use -Main parameter."
		}
		Write-Verbose-Custom "Detected main file: $Main"
	}

	$MainBase = [System.IO.Path]::GetFileNameWithoutExtension($Main)
	$MainDir = [System.IO.Path]::GetDirectoryName($Main)

	# Change back to the original directory before running git commands
	Set-Location $originalDir

	try {
		# Checkout old and new versions
		# Create tar files in the original directory
		git archive --format=tar $Old -o "$TmpDir\old.tar"

		if ($New -eq "--") {
			git ls-files | tar -cf "$TmpDir\new.tar" -T -
		} else {
			git archive --format=tar $New -o "$TmpDir\new.tar"
		}

		# Extract tar files
		Set-Location $OldDir
		tar -xf "$TmpDir\old.tar"

		Set-Location $NewDir
		tar -xf "$TmpDir\new.tar"
		
	} catch {
		Write-Error "Error checking out old and new versions: $_"
		exit 1
	}

	Set-Location $TmpDir
	
	$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
	
	try {
		# Flatten documents
		Write-Verbose-Custom "Flattening documents with latexpand"
		$oldContent = latexpand "$OldDir\$Main"
		[System.IO.File]::WriteAllLines("$TmpDir\old-$MainBase-fl.tex", $oldContent, $Utf8NoBomEncoding)
		
		$newContent = latexpand "$NewDir\$Main"
		[System.IO.File]::WriteAllLines("$TmpDir\new-$MainBase-fl.tex", $newContent, $Utf8NoBomEncoding)
		
	} catch {
		Write-Error "Error flattening documents: $_"
		exit 1
	}

	try {
		# Run latexdiff
		Write-Verbose-Custom "Running latexdiff"
		$Content = latexdiff "old-$MainBase-fl.tex" "new-$MainBase-fl.tex"
		[System.IO.File]::WriteAllLines("$TmpDir\diff.tex", $Content, $Utf8NoBomEncoding)
	} catch {
		Write-Error "Error running latexdiff: $_"
		exit 1
	}

	Move-Item -Force "$TmpDir\diff.tex" "$NewDir\diff.tex"

	# Compile result
	Write-Verbose-Custom "Compiling result"
	Set-Location "$NewDir\$MainDir"
	pdflatex "diff"
	if ($NoBibtex) {
		pdflatex "diff"
	} else {
		bibtex "diff"
		pdflatex "diff"
		pdflatex "diff"
	}

	$PdfFile = "$NewDir\$MainDir\diff.pdf"

	if (-not (Test-Path $PdfFile)) {
		throw "No PDF file generated."
	}

	if ((Get-Item $PdfFile).Length -eq 0) {
		throw "PDF file generated is empty."
	}

	Set-Location $originalDir

	if ($Output) {
		Move-Item -Force $PdfFile $Output
		$PdfFile = $Output
		Write-Host "Output written to $PdfFile"
	}

	# View PDF
	if (-not $NoView) {
		& $PdfViewer $PdfFile
	}
} finally{
	Set-Location $originalDir
	# Cleanup
	Cleanup
}
