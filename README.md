# git-latexdiff_ps

## Overview

This repository contains a PowerShell script, `git-latexdiff.ps1`, designed to generate a LaTeX diff between two Git commits or branches (i.e generate a pdf containing the difference between two commits or branches in a tex repository). The script leverages Git and LaTeX tools to create a visual diff of a LaTeX document, highlighting changes between the specified versions. The script should be run from the repository directory.

## Features

- Compare LaTeX documents between two Git commits or branches.
- Automatically detects the main LaTeX file if not specified.
- Supports BibTeX integration.
- Customizable output PDF file name.
- Option to suppress verbose output and clean up temporary files.
- Compatible with the system's default PDF viewer or a specified viewer.

## Requirements

- Git
- Perl
- `latexpand`
- `latexdiff`
- (Optional) BibTeX

These tools should be installed and accessible from the console. If you use MiKTeX for compiling TeX files, `latexpand` and `latexdiff` can be easily installed from the MiKTeX console. To install perl search for strawberry perl and install it (confirm that perl.exe is acessable from the powershell console by running the command `perl -v`). And you will not be needing this script if you dont have Git installed in your system

### Note on BibTeX

If BibTeX is not available, you should use the `-NoBibtex` flag while running the script to skip the BibTeX step.

## Comparison with Existing Tools

There is already a `git-latexdiff` tool available [here](https://gitlab.com/git-latexdiff/git-latexdiff), but it only runs in Bash and does not have a standalone executable for Windows. This PowerShell version, while less featured, gets the task done on natively in Windows systems.

## Parameters

- **Old**: The old commit or branch to compare from. Default is `HEAD`.
- **New**: The new commit or branch to compare to. Default is `--` (working directory).
- **Main**: The main LaTeX file to use. If not specified, the script will try to detect it.
- **NoView**: Do not open the resulting PDF file.
- **NoBibtex**: Do not run BibTeX. By default, BibTeX is run.
- **Output**: The output PDF file name. Default is `diff.pdf`.
- **TmpdirPrefix**: The prefix for the temporary directory. Default is the system's TEMP directory.
- **Silent**: Suppress verbose output.
- **NoCleanup**: Do not clean up temporary files.
- **Help**: Show help information.
- **PdfViewer**: The PDF viewer to use. Default is the system's default viewer.

## Usage

To use the script, run the following command in PowerShell:

```powershell
.\git-latexdiff.ps1 -Old "commit1" -New "commit2" -Main "main.tex" -Output "diff_output.pdf"
```
This command compares the LaTeX document `main.tex` between `commit1` and `commit2`, and outputs the diff to `diff_output.pdf`. The `commit1` and `commit2` can the hashes of the corresponding commits, branch names or the pointer to a commit such as `HEAD~1`, `HEAD~2`etc.

## Additional Setup

To use this script, add the directory containing `git-latexdiff.ps1` to the system PATH and set the execution policy in PowerShell by executing the following command as an administrator:

```powershell
Set-ExecutionPolicy RemoteSigned
```

## Notes

- Author: Rakhul Raj
- Date: "24-08-2024"

## License

I do not know much about licensing, i made this script for my personal use since i like to use powershell to get things done. You can do whatever you want with the script unless its something illegal. I will not be responsable for anything you do with this script and this does not come with any guaranties.