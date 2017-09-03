#!/usr/bin/env zsh

# Copy me into any mix project directory as `.tmux.zsh` and `cd2project <that dir>` Will Just Work ™
export session_home_dir="$(dirname $0)"
export session_name="$(basename ${session_home_dir})"

source $Lab42MyZsh/tools/tmux.zsh

function init_new_session {

    new_window mainvim 'vip git .'

    new_window 'vi lib' "vip lib lib/{.,$session_name}"

    new_window 'mix test'

    new_window 'vi test' "vip spec test/{.,$session_name}"
    new_window console 'iex -S mix'
    new_window etc
}

attach_or_create
