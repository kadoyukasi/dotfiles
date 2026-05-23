$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$IsWindowsHost = $env:OS -eq "Windows_NT"

if (-not $IsWindowsHost) {
    Write-Host "This script is for Windows PowerShell. Use ./install.sh on macOS."
    exit 0
}

$InstallTargets = @(
    ".config",
    ".codex",
    ".copilot",
    ".ssh",
    ".zsh",
    ".bc",
    ".editorconfig",
    ".gitconfig",
    ".gitignore",
    ".zshenv",
    ".zshrc",
    "Scoopfile"
)

function Link-File {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-Path -LiteralPath $Target) {
        Write-Host "File $Target already exists in home directory. Skipping."
        return
    }

    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "Linked $Source to home directory."
}

function Invoke-Scoop {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    & scoop @Arguments
    if ($LASTEXITCODE -ne 0) {
        Write-Host $FailureMessage
    }
}

foreach ($Item in $InstallTargets) {
    $SourcePath = Join-Path $DotfilesDir $Item
    $TargetPath = Join-Path $HOME $Item

    if (Test-Path -LiteralPath $SourcePath) {
        Link-File -Source $SourcePath -Target $TargetPath
    }
    else {
        Write-Host "File or directory $Item not found in dotfiles directory. Skipping."
    }
}

Write-Host "Dotfiles have been linked to your home directory."

git config --global core.hooksPath "$DotfilesDir/.githooks"
Write-Host "Global git hooks path has been set to $DotfilesDir/.githooks."

$Scoop = Get-Command scoop -ErrorAction SilentlyContinue
if (-not $Scoop) {
    Write-Host "Scoop is not installed. Skipping package installation."
    exit 0
}

$Scoopfile = Join-Path $DotfilesDir "Scoopfile"
if (-not (Test-Path -LiteralPath $Scoopfile)) {
    Write-Host "Scoopfile not found. Skipping package installation."
    exit 0
}

Get-Content -LiteralPath $Scoopfile | ForEach-Object {
    $Entry = $_.Trim()

    if ([string]::IsNullOrWhiteSpace($Entry) -or $Entry.StartsWith("#")) {
        return
    }

    if ($Entry.StartsWith("bucket ")) {
        $BucketName = $Entry.Substring(7).Trim()
        if (-not [string]::IsNullOrWhiteSpace($BucketName)) {
            Invoke-Scoop -Arguments @("bucket", "add", $BucketName) -FailureMessage "Failed to add bucket $BucketName. Continuing."
        }
        return
    }

    Invoke-Scoop -Arguments @("install", $Entry) -FailureMessage "Failed to install $Entry. Continuing."
}

Write-Host "Scoop packages have been installed."
