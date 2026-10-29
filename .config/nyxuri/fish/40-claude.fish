# =============================================================================
# Claude Code 环境清理（移植自 ~/.dotfiles/zsh/claude.zsh）
# =============================================================================
# emacsclient 建新窗口时会把调用方的整套环境变量交给 Emacs 服务端，Emacs 存进全局的
# process-environment 后不清理。于是 claude 会话的 CLAUDECODE=1 等标记会一直留在
# Emacs 里，再由 ghostel 传给子 shell —— claude 见到这些标记会误判为「嵌套会话」，
# 而嵌套会话不写历史记录，表现就是 ghostel 里 claude -r 空空如也。
#
# 用通配而不是逐个列举，是为了不漏掉 claude 以后新增的变量。
if set -q INSIDE_EMACS; or set -q EMACS_SOCKET_NAME
    for v in (set --names | string match 'CLAUDE*')
        set -e $v
    end
    set -e AI_AGENT
end

# 兜底：万一还是被误判成嵌套会话，也强制落盘 transcript
set -gx CLAUDE_CODE_FORCE_SESSION_PERSISTENCE 1
