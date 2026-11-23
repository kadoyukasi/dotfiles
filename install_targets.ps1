function Get-DotfileTargets {
    $ConfigDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }
    $CodexDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
    $GhDir = if ($env:GH_CONFIG_DIR) { $env:GH_CONFIG_DIR }
        elseif ($env:XDG_CONFIG_HOME) { Join-Path $ConfigDir "gh" }
        elseif ($env:APPDATA) { Join-Path $env:APPDATA "GitHub CLI" }
        else { Join-Path $ConfigDir "gh" }
    $MiseDir = if ($env:MISE_CONFIG_DIR) { $env:MISE_CONFIG_DIR } else { Join-Path $ConfigDir "mise" }
    $SheldonDir = if ($env:SHELDON_CONFIG_DIR) { $env:SHELDON_CONFIG_DIR } else { Join-Path $ConfigDir "sheldon" }

    foreach ($Line in Get-Content -LiteralPath (Join-Path $PSScriptRoot "install_targets.txt")) {
        $Mode, $Item = $Line -split " ", 2
        $Destination = switch -Wildcard ($Item) {
            ".codex/*"     { Join-Path $CodexDir $Item.Substring(7); break }
            ".config/gh/*" { Join-Path $GhDir $Item.Substring(11); break }
            ".config/mise/config.toml" {
                if ($env:MISE_GLOBAL_CONFIG_FILE) { $env:MISE_GLOBAL_CONFIG_FILE }
                else { Join-Path $MiseDir "config.toml" }
                break
            }
            ".config/sheldon/plugins.toml" {
                if ($env:SHELDON_CONFIG_FILE) { $env:SHELDON_CONFIG_FILE }
                else { Join-Path $SheldonDir "plugins.toml" }
                break
            }
            ".config/starship.toml" {
                if ($env:STARSHIP_CONFIG) { $env:STARSHIP_CONFIG }
                else { Join-Path $ConfigDir "starship.toml" }
                break
            }
            ".config/*"    { Join-Path $ConfigDir $Item.Substring(8); break }
            default        { Join-Path $HOME $Item }
        }
        [pscustomobject]@{ Mode = $Mode; Source = Join-Path $PSScriptRoot $Item; Target = $Destination }
    }

    [pscustomobject]@{ Mode = "link"; Source = Join-Path $PSScriptRoot "Scoopfile"; Target = Join-Path $HOME "Scoopfile" }
    [pscustomobject]@{ Mode = "link"; Source = Join-Path $PSScriptRoot "profile.ps1"; Target = $PROFILE }
}

function Test-LinkedParent {
    param([string]$Target)

    $Parent = Split-Path -Parent $Target
    while ($Parent -and $Parent -ne $HOME) {
        $Item = Get-Item -LiteralPath $Parent -Force -ErrorAction SilentlyContinue
        if ($Item.LinkType -in @("SymbolicLink", "Junction")) {
            Write-Warning "Skipping ${Target}: parent directory $Parent is a link."
            return $true
        }
        $Parent = Split-Path -Parent $Parent
    }
    return $false
}
