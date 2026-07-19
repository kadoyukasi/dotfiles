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
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    $Item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($null -eq $Item) {
        Write-Host "No symlink found for $Target. Skipping."
        return
    }

    $IsReparsePoint = ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

    if ($IsReparsePoint) {
        $LinkTarget = @($Item.Target)[0]
        if ([string]::IsNullOrWhiteSpace($LinkTarget)) {
            Write-Host "$Target has no readable symlink target. Skipping."
            return
        }

        if (-not [System.IO.Path]::IsPathRooted($LinkTarget)) {
            $LinkTarget = Join-Path (Split-Path -Parent $Target) $LinkTarget
        }

        $ExpectedPath = [System.IO.Path]::GetFullPath($Source).TrimEnd('\', '/')
        $ActualPath = [System.IO.Path]::GetFullPath($LinkTarget).TrimEnd('\', '/')
        if ([string]::Equals($ActualPath, $ExpectedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $Target
            Write-Host "Removed $Target."
        }
        else {
            Write-Host "$Target points outside this dotfiles clone. Skipping."
        }
    }
    else {
        Write-Host "$Target is not a symlink. Skipping."
    }
}

foreach ($Item in $InstallTargets) {
    $SourcePath = Join-Path $DotfilesDir $Item
    $TargetPath = Join-Path $HOME $Item
    Remove-Link -Source $SourcePath -Target $TargetPath
}

# Remove PowerShell profile symlink
$ProfileSource = Join-Path $DotfilesDir "profile.ps1"
Remove-Link -Source $ProfileSource -Target $PROFILE

Write-Host "Dotfiles have been uninstalled."

$CurrentHooksPath = git config --file $GitLocalConfig --get core.hooksPath 2>$null
$NormalizedCurrentHooksPath = "$CurrentHooksPath".Replace('\', '/').TrimEnd('/')
$NormalizedHooksPath = $HooksPath.TrimEnd('/')
if ([string]::Equals($NormalizedCurrentHooksPath, $NormalizedHooksPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    git config --file $GitLocalConfig --unset core.hooksPath
    Write-Host "Unset global git hooks path ($HooksPath) from $GitLocalConfig."
}

git -C $DotfilesDir config --remove-section filter.codex-config 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Removed the repository-local Codex config filter."
}
