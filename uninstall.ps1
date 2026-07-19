$ErrorActionPreference = "Stop"

$DotfilesDir = $PSScriptRoot
$IsWindowsHost = $env:OS -eq "Windows_NT"
$GitLocalConfig = Join-Path $HOME ".gitconfig.local"
$HooksPath = (Join-Path $DotfilesDir ".githooks").Replace('\', '/')

if (-not $IsWindowsHost) {
    Write-Host "This script is for Windows PowerShell. Use ./uninstall.sh on macOS."
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

function Remove-Link {
    param(
        [Parameter(Mandatory = $true)][string]$Target
    )

    $Item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($null -eq $Item) {
        Write-Host "No symlink found for $Target. Skipping."
        return
    }

    $IsReparsePoint = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

    if ($IsReparsePoint) {
        Remove-Item -LiteralPath $Target
        Write-Host "Removed $Target."
    }
    else {
        Write-Host "$Target is not a symlink. Skipping."
    }
}

foreach ($Item in $InstallTargets) {
    $TargetPath = Join-Path $HOME $Item
    Remove-Link -Target $TargetPath
}

# Remove PowerShell profile symlink
Remove-Link -Target $PROFILE

Write-Host "Dotfiles have been uninstalled."

$CurrentHooksPath = git config --file $GitLocalConfig --get core.hooksPath 2>$null
if ($CurrentHooksPath -eq $HooksPath) {
    git config --file $GitLocalConfig --unset core.hooksPath
    Write-Host "Unset global git hooks path ($HooksPath) from $GitLocalConfig."
}
