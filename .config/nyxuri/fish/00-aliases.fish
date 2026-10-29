# =============================================================================
# 常用别名（移植自 ~/.dotfiles/zsh/aliass.zsh 与 path.zsh）
# =============================================================================

# 编辑器：zsh 的 path.zsh 里 export 的 EDITOR，fish 之前是空的
set -gx EDITOR nvim
set -gx VISUAL nvim

# 常用命令
alias n nvim
alias y yazi
alias c clear
alias cl claude
alias cld 'claude --dangerously-skip-permissions'

# ls 变体（ls 本身已在 config.fish 里指向 eza --icons=auto）
alias l 'ls -l'
alias lla 'ls -la'
alias lt 'ls --tree'
