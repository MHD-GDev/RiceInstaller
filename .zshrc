#              __             
#  ____  _____/ /_  __________
# /_  / / ___/ __ \/ ___/ ___/
#  / /_(__  ) / / / /  / /__  
# /___/____/_/ /_/_/   \___/  
#
# AUTHOR = MHD

# llama.cpp

# Starts Starship
export STARSHIP_CONFIG="$HOME/.config/wayland/zsh/starship.toml"
eval "$(starship init zsh)"

# Vars
export VISUAL="${EDITOR}"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BROWSER='firefox'
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"
export SUDO_PROMPT="Password : "
export BAT_THEME="base16"

# Wayland Fix
export QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=hyprland
export XDG_SESSION_DESKTOP=hyprland
export XDG_CURRENT_SESSION_TYPE=wayland
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1

# fcitx vars
export GTK_IM_MODULE='fcitx'
export QT_IM_MODULE='fcitx'
export SDL_IM_MODULE='fcitx'
export XMODIFIERS='@im=fcitx'

if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

# Create ZSH config directory if it doesn't exist
[[ ! -d ~/.config/wayland/zsh ]] && mkdir -p ~/.config/wayland/zsh

# Waiting dots animation
expand-or-complete-with-dots() {
  echo -n "\e[31m…\e[0m"
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

# History configuration
HISTFILE=~/.config/wayland/zsh/.histfile
HISTSIZE=10000
SAVEHIST=50000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt inc_append_history

# zsh options
setopt beep
setopt PROMPT_SUBST        # enable command substitution in prompt
setopt MENU_COMPLETE       # Automatically highlight first element of completion menu
setopt LIST_PACKED		   # The completion menu takes less space.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
bindkey -v

# Compinit Engine
autoload -Uz compinit
for dump in ~/.config/wayland/zsh/zcompdump(N.mh+24); do
  compinit -d ~/.config/wayland/zsh/zcompdump
done

compinit -C -d ~/.config/wayland/zsh/zcompdump

autoload -Uz add-zsh-hook
autoload -Uz vcs_info
precmd () { vcs_info }
_comp_options+=(globdots)

zstyle ':completion:*' verbose true
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} 'ma=48;5;197;1'
zstyle ':completion:*' matcher-list \
		'm:{a-zA-Z}={A-Za-z}' \
		'+r:|[._-]=* r:|=*' \
		'+l:|=*'
zstyle ':completion:*:warnings' format "%B%F{red}No matches for:%f %F{magenta}%d%b"
zstyle ':completion:*:descriptions' format '%F{yellow}[-- %d --]%f'
zstyle ':vcs_info:*' formats ' %B%s-[%F{magenta}%f %F{yellow}%b%f]-'

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Changes the terminal titles based on users location
function xterm_title_precmd () {
	print -Pn -- '\e]2;%n@%m %~\a'
	[[ "$TERM" == 'screen'* ]] && print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-}\e\\'
}

function xterm_title_preexec () {
	print -Pn -- '\e]2;%n@%m %~ %# ' && print -n -- "${(q)1}\a"
	[[ "$TERM" == 'screen'* ]] && { print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-} %# ' && print -n -- "${(q)1}\e\\"; }
}

if [[ "$TERM" == (kitty*|tmux*|screen*|xterm*) ]]; then
	add-zsh-hook -Uz precmd xterm_title_precmd
	add-zsh-hook -Uz preexec xterm_title_preexec
fi

# Wrong input message
command_not_found_handler() {
    echo " \n 😮 Huh!! \n"
    return 127
}

#     ___    ___           
#    /   |  / (_)___ ______
#   / /| | / / / __ `/ ___/
#  / ___ |/ / / /_/ (__  ) 
# /_/  |_/_/_/\__,_/____/  

alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias cat="bat --theme=base16"
alias ls='eza --icons=always --color=always -a'
alias vi='nvim'
alias fastfetch='fastfetch -c ~/.config/wayland/fastfetch/config.jsonc'
alias tmux='tmux -f ~/.config/wayland/tmux/tmux.conf'
alias reflector='sudo reflector --protocol https --latest 5 --sort rate --country Japan --save /etc/pacman.d/mirrorlist'
alias update="~/.config/wayland/scripts/Updates"
alias todo="~/.config/wayland/scripts/todo"
alias mpv='sh ~/.config/wayland/scripts/mpv-tui'
alias programmer='sh ~/.config/wayland/scripts/programmer-info'
alias icat='kitten icat'

#     ___         __       _____ __             __ 
#    /   | __  __/ /_____ / ___// /_____ ______/ /_
#   / /| |/ / / / __/ __ \\__ \/ __/ __ `/ ___/ __/
#  / ___ / /_/ / /_/ /_/ /__/ / /_/ /_/ / /  / /_  
# /_/  |_\__,_/\__/\____/____/\__/\__,_/_/   \__/  

# opencode
export PATH=/home/mhd/.opencode/bin:$PATH
