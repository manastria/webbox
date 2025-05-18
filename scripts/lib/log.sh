#!/bin/bash

# --- Détection : activer les couleurs uniquement si sortie vers un terminal
if [[ -t 1 ]]; then
    COLOR_RESET="\033[0m"
    COLOR_BOLD="\033[1m"
    COLOR_GREEN="\033[1;32m"
    COLOR_BLUE="\033[1;34m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_RED="\033[1;31m"
    COLOR_DIM="\033[2m"
else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_GREEN=""
    COLOR_BLUE=""
    COLOR_YELLOW=""
    COLOR_RED=""
    COLOR_DIM=""
fi

log() {
    local type="$1"; shift
    local message="$*"

    case "$type" in
        INFO)
            echo -e "${COLOR_BOLD}[=]${COLOR_RESET} $message"
            ;;
        OK)
            echo -e "${COLOR_GREEN}[✔]${COLOR_RESET} $message"
            ;;
        STEP)
            echo -e "${COLOR_BLUE}[+]${COLOR_RESET} $message"
            ;;
        WARN)
            echo -e "${COLOR_YELLOW}[!]${COLOR_RESET} $message"
            ;;
        ERROR)
            echo -e "${COLOR_RED}[✘]${COLOR_RESET} $message" >&2
            ;;
        DEBUG)
            echo -e "${COLOR_DIM}[~] $message${COLOR_RESET}"
            ;;
        *)
            echo -e "[?] $message"
            ;;
    esac
}
