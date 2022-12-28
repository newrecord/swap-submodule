#!/usr/bin/env bash

## ENV -----------------------------------------------------
VERSION="v0.1"
GIT_SHARED_MODULE='https://github.com/newrecord/auto-changelog-generate.git'
GRAY="\033[1.30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"
NC="\033[0m" #no color
CHECK="\xE2\x9C\x94"

## Main process -----------------------------------------------------

## Attach sub module
_attach_() {
    clear
    _select_branch
}

## Dettach sub module
_dettach_() {
    echo "[$1] next step pull git..."
}

## TODO: git stash
_stash_save() {
    echo -e "$CHECK Stash save current branch..."
    # git stash
}

## TODO: git stash pop
_stash_pop() {
    echo "$CHECK Stash pop current branch..."
    git stash pop
}

## TODO: git shared module pull repository
_pull_shared_module() {
    _stash_save
    _start_spinner "$CHECK [${YELLOW}$1${NC}] Pull shared module start..."
    # TODO: clone shared module
    # TODO: shared module import
    _delay_work 3
    _stop_spinner 0
}

## TODO: shared moduel import

## TODO: 1) shared module 참조된 파일 검색(toml, Dependency.kt...)
##       2) 참조된 파일에서 참조된 부분 삭제
##       3) shared module package 끼워 넣기

## TODO: load remote branch list

## Utils -----------------------------------------------------

## TODO: check already attached shared module

## TODO: check already dettached shared module

# delay work(only test)
_delay_work() {
    sleep $1
}

# Progress spinner
_spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"

    case $1 in
    start)
        # calculate the column where spinner and status msg will be displayed
        let column=$(tput cols)-${#2}-8
        # display message and position the cursor in $column column
        echo -ne ${2}
        printf "%${column}s"

        # start spinner
        i=1
        sp='\|/-'
        delay=${SPINNER_DELAY:-0.15}

        while :; do
            printf "\b${sp:i++%${#sp}:1}"
            sleep $delay
        done
        ;;
    stop)
        if [[ -z ${3} ]]; then
            echo "spinner is not running.."
            exit 1
        fi

        kill $3 >/dev/null 2>&1

        # inform the user uppon success or failure
        echo -en "\b["
        if [[ $2 -eq 0 ]]; then
            echo -en "${GREEN}${on_success}${NC}"
        else
            echo -en "${RED}${on_fail}${NC}"
        fi
        echo -e "]"
        ;;
    *)
        echo "invalid argument, try {start/stop}"
        exit 1
        ;;
    esac
}

_start_spinner() {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

_stop_spinner() {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

## Display Menu -----------------------------------------------------

# Create menu
_select_option() {

    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_option() { printf "   $1 "; }
    print_selected() { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }
    key_input() {
        read -s -n3 key 2>/dev/null >&2
        if [[ $key = $ESC[A ]]; then echo up; fi
        if [[ $key = $ESC[B ]]; then echo down; fi
        if [[ $key = "" ]]; then echo enter; fi
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
        enter) break ;;
        up)
            ((selected--))
            if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
            ;;
        down)
            ((selected++))
            if [ $selected -ge $# ]; then selected=0; fi
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

_select_opt() {
    _select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

# 2-depth sub menu
_select_branch() {
    echo "#################################"
    echo "##### SWAP SHARED SUBMODULE #####"
    echo "##### --------------------- #####"
    echo "#####                       #####"
    echo "##### Select branch         #####"
    echo "#####                  ${VERSION} #####"
    echo "#################################"
    echo ""
    branches=("main" "develop" "release/1.44.0")
    branch_options=("<- back" "${branches[@]}")
    branch_menu=$(_select_opt "${branch_options[@]}")
    case $branch_menu in
    0) __main__ ;;
    *) _pull_shared_module "${branch_options[$?]}" ;;
    esac
}

# 1-depth main menu
__main__() {
    clear
    ## intro
    echo "#################################"
    echo "##### SWAP SHARED SUBMODULE #####"
    echo "##### --------------------- #####"
    echo "#####                       #####"
    echo "##### Select menu           #####"
    echo "#####                  ${VERSION} #####"
    echo "#################################"
    echo ""
    main_options=("Attach sub module" "Dettach sub module" "Exit")
    main_menu=$(_select_opt "${main_options[@]}")
    case $main_menu in
    0) _attach_ ;;
    1) _dettach_ "$main_menu" ;;
    2) echo "Bye~!" ;;
    *) echo "Invalid menu... >> $REPLY << $main_menu" ;;
    esac
}

__main__
