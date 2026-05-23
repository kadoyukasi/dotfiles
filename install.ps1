$ErrorActionPreference = "Stop"

$DotfilesDir = $PSScriptRoot
$IsWindowsHost = $env:OS -eq "Windows_NT"

if (-not $IsWindowsHost) {
    Write-Host "This script is for Windows PowerShell. Use ./install.sh on macOS."
    exit 0
}

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "ERROR: This script requires Administrator privileges."
    Write-Host "Open PowerShell as Administrator and run: pwsh -File .\install.ps1"
    Write-Host "Do not use 'sudo' - it hides all output by spawning a separate window."
    exit 1
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

$LinkErrors = [System.Collections.Generic.List[string]]::new()

function Link-File {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-Path -LiteralPath $Target) {
        Write-Host "File $Target already exists in home directory. Skipping."
        return
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        Write-Host "Linked $Source to home directory."
    }
    catch {
        Write-Host "ERROR: Failed to link $Source -> $Target : $($_.Exception.Message)"
        $script:LinkErrors.Add($Target)
    }
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

try {
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

    # Link PowerShell profile (target path differs from simple $HOME/<name> pattern)
    $ProfileSource = Join-Path $DotfilesDir "profile.ps1"
    if (Test-Path -LiteralPath $ProfileSource) {
        $ProfileDir = Split-Path -Parent $PROFILE
        if (-not (Test-Path -LiteralPath $ProfileDir)) {
            New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
        }
        Link-File -Source $ProfileSource -Target $PROFILE
    }

    if ($LinkErrors.Count -gt 0) {
        Write-Host "WARNING: $($LinkErrors.Count) symlink(s) failed to create:"
        $LinkErrors | ForEach-Object { Write-Host "  - $_" }
        Write-Host "Hint: run with 'sudo pwsh -File .\install.ps1' for elevated privileges."
        exit 1
    }

    Write-Host "Dotfiles have been linked to your home directory."

    git config --global core.hooksPath "$DotfilesDir/.githooks"
    Write-Host "Global git hooks path has been set to $DotfilesDir/.githooks."

    $Scoop = Get-Command scoop -ErrorAction SilentlyContinue
    if (-not $Scoop) {
        Write-Host "Scoop is not installed. Installing Scoop..."
        $ErrorActionPreference = "Continue"
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        $ErrorActionPreference = "Stop"
        $Scoop = Get-Command scoop -ErrorAction SilentlyContinue
        if (-not $Scoop) {
            Write-Host "Scoop installation failed. Skipping package installation."
            exit 1
        }
        Write-Host "Scoop installed successfully."
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

    # Install distill CLI (@samuelfaj/distill via npm + build native binary from source if needed)
    # Migration note: when @samuelfaj/distill-win32-x64 is published to npm,
    #   simply re-run: npm install -g @samuelfaj/distill
    #   npm will install the official platform package, overwriting the locally built binary.
    $Npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($Npm) {
        Write-Host "Installing @samuelfaj/distill..."
        & npm install -g @samuelfaj/distill
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to install @samuelfaj/distill. Continuing."
        }
        else {
            # Check if the native binary is available (win32-x64 may not be on npm yet)
            $null = & distill --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Native binary @samuelfaj/distill-win32-x64 not found on npm. Building from source..."

                $Bun = Get-Command bun -ErrorAction SilentlyContinue
                if (-not $Bun) {
                    Write-Host "Installing bun (required to build distill)..."
                    Invoke-Scoop -Arguments @("install", "bun") -FailureMessage "Failed to install bun. Cannot build distill native binary."
                    $Bun = Get-Command bun -ErrorAction SilentlyContinue
                }

                if ($Bun) {
                    $TmpDir = Join-Path $env:TEMP "distill-build-$(Get-Random)"
                    try {
                        Write-Host "Cloning samuelfaj/distill..."
                        & git clone --depth=1 https://github.com/samuelfaj/distill.git $TmpDir
                        if ($LASTEXITCODE -ne 0) { throw "git clone failed" }

                        Push-Location $TmpDir
                        Write-Host "Installing dependencies..."
                        & bun install
                        if ($LASTEXITCODE -ne 0) { throw "bun install failed" }

                        Write-Host "Compiling distill.exe for win32-x64..."
                        & bun run build:bins
                        if ($LASTEXITCODE -ne 0) { throw "bun run build:bins failed" }

                        # Place the binary where bin/distill.js expects @samuelfaj/distill-win32-x64
                        $NpmRoot = (& npm root -g).Trim()
                        $BinDest = Join-Path $NpmRoot "@samuelfaj\distill-win32-x64\bin"
                        New-Item -ItemType Directory -Force -Path $BinDest | Out-Null
                        Copy-Item (Join-Path $TmpDir ".dist\bun-windows-x64\distill.exe") -Destination $BinDest -Force
                        Write-Host "distill.exe installed to $BinDest"
                        Write-Host "@samuelfaj/distill ready. Run 'distill' to complete onboarding."
                        Write-Host "Migration: when @samuelfaj/distill-win32-x64 is on npm, run: npm install -g @samuelfaj/distill"
                    }
                    catch {
                        Write-Host "Failed to build distill from source: $_. Continuing."
                    }
                    finally {
                        Pop-Location
                        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
                    }
                }
                else {
                    Write-Host "bun not available. Cannot build distill native binary. Continuing."
                }
            }
            else {
                Write-Host "@samuelfaj/distill installed. Run 'distill' to complete onboarding."
            }
        }
    }
    else {
        Write-Host "npm not found. Skipping distill installation. Install Node.js and run: npm i -g @samuelfaj/distill"
    }

    # Install VS Code extensions (source of truth: vscode entries in Brewfile)
    $VSCode = Get-Command code -ErrorAction SilentlyContinue
    if ($VSCode) {
        $BrewfilePath = Join-Path $DotfilesDir "Brewfile"
        if (Test-Path -LiteralPath $BrewfilePath) {
            $Extensions = Get-Content -LiteralPath $BrewfilePath |
                ForEach-Object { if ($_ -match '^vscode "(.+)"') { $Matches[1] } } |
                Where-Object { $_ }
            foreach ($Ext in $Extensions) {
                Write-Host "Installing VS Code extension: $Ext"
                & code --install-extension $Ext 2>&1 | Out-Null
            }
            Write-Host "VS Code extensions have been installed."
        }
    }
    else {
        Write-Host "VS Code (code) not found in PATH. Skipping extension installation."
    }

    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
