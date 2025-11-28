# Created by newuser for 5.9
eval "$(starship init zsh)"

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Aliases

alias connectmusic="~/.config/hypr/Scripts/speakerconnect.sh"
alias swapaudiooutput="~/.config/hypr/Scripts/swapAudioOutput.sh"


# Only show Neofetch on local interactive terminals
if [ -t 1 ] && [ -z "$SSH_CONNECTION" ]; then
  neofetch
fi

PROMPT='%F{3}[%D{%H:%M}]%f %F{2}🐸 %F{7}%~%f %F{2}❯ %f'

qrcode() {
    if [ -z "$1" ]; then
        echo "Error: Please provide a URL or text to encode."
        echo "Usage: qrcode <text_or_url>"
    else
        curl "qrenco.de/$1"
    fi
}
