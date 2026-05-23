# PSReadLine: syntax highlighting, autosuggestions, history substring search
# Mirrors zsh-syntax-highlighting + zsh-autosuggestions + zsh-history-substring-search
Import-Module PSReadLine -ErrorAction SilentlyContinue

Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -Colors @{
    Command   = 'Cyan'
    Parameter = 'DarkCyan'
    String    = 'Yellow'
    Operator  = 'DarkYellow'
    Variable  = 'Green'
    Number    = 'DarkGreen'
    Comment   = 'DarkGray'
    Error     = 'Red'
}

# Ctrl+P/N: history substring search (mirrors zsh-history-substring-search)
Set-PSReadLineKeyHandler -Key Ctrl+p -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key Ctrl+n -Function HistorySearchForward

# eza: modern ls/tree replacement (mirrors eza on macOS)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Alias -Name ls -ErrorAction SilentlyContinue
    function ls { eza $args }
    function ll { eza -l $args }
    function la { eza -la $args }
    function lt { eza --tree $args }
}

# zoxide: smart cd with frecency history (mirrors autojump + enhancd on macOS)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# starship: cross-platform prompt (mirrors pure prompt on macOS)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
