$ErrorActionPreference = "Stop"

$DotfilesDir = $PSScriptRoot
$IsWindowsHost = $env:OS -eq "Windows_NT"
$GitLocalConfig = Join-Path $HOME ".gitconfig.local"
$HooksPath = (Join-Path $DotfilesDir ".githooks").Replace('\', '/')

if (-not $IsWindowsHost) {
    Write-Host "This script is for Windows PowerShell. Use ./uninstall.sh on macOS."
    exit 0
}

. (Join-Path $DotfilesDir "install_targets.ps1")

function Remove-Link {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-LinkedParent $Target) { return }
    $Item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($Item.LinkType -eq "SymbolicLink") {
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
}

foreach ($Item in Get-DotfileTargets) {
    if ($Item.Mode -eq "link") {
        Remove-Link -Source $Item.Source -Target $Item.Target
    }
}

$LocalConfig = Get-Item -LiteralPath $GitLocalConfig -Force -ErrorAction SilentlyContinue
if ($LocalConfig -and -not $LocalConfig.LinkType) {
    $CurrentHooksPath = @(git config --file $GitLocalConfig --get-all core.hooksPath)
    if ($CurrentHooksPath.Count -eq 1 -and
        $CurrentHooksPath[0].Replace('\', '/').TrimEnd('/') -eq $HooksPath.TrimEnd('/')) {
        git config --file $GitLocalConfig --unset core.hooksPath
        if ($LASTEXITCODE -ne 0) { throw "Failed to unset core.hooksPath in $GitLocalConfig." }
        Write-Host "Unset global Git hooks from $GitLocalConfig."
    }
}

if (Test-Path -LiteralPath (Join-Path $DotfilesDir ".git")) {
    $Filter = git -C $DotfilesDir config --local --get filter.codex-config.clean
    if ($Filter -eq ".githooks/clean-codex-config") {
        git -C $DotfilesDir config --local --remove-section filter.codex-config
        if ($LASTEXITCODE -ne 0) { throw "Failed to remove the Codex config filter." }
        Write-Host "Removed the repository-local Codex config filter."
    }
}
