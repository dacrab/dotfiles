# Setup fzf
# ---------
if [[ ! "$PATH" == */home/dacrab/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/dacrab/.fzf/bin"
fi

eval "$(fzf --bash)"
