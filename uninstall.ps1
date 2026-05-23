$ErrorActionPreference = "Stop"

$DotfilesDir = $PSScriptRoot
$IsWindowsHost = $env:OS -eq "Windows_NT"

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

    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Host "No symlink found for $Target. Skipping."
        return
    }

    $Item = Get-Item -LiteralPath $Target
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

$CurrentHooksPath = git config --global --get core.hooksPath 2>$null
if ($CurrentHooksPath -eq "$DotfilesDir/.githooks") {
    git config --global --unset core.hooksPath
    Write-Host "Unset global git hooks path ($DotfilesDir/.githooks)."
}
