function n () {
  local cmd

  if [[ "${1:0:2}" = "--" ]]; then
    cmd="__n_${1:2}"
    if [[ -z `type -t $cmd` ]]; then
      echo "Unknown command \"n $1\"" >&2
      return 1
    fi

    $cmd "${@:2}"
    return $?
  elif [[ "$1" = "-" ]]; then
    __n_prev
  elif [[ "${1:0:1}" = "-" && "${1:1}" =~ ^[0-9]+$ ]]; then
    __n_goto "${1:1}"
  elif [[ "${1:0:1}" = "-" ]]; then
    cmd="__n_${1:1}"
    if [[ -z `type -t $cmd` ]]; then
      echo "Unknown command \"n $1\"" >&2
      return 1
    fi

    $cmd "${@:2}"
    return $?
  elif [[ -n "$@" ]]; then
    __n_set "$@"
  elif [[ -z "$__n_folders" ]]; then
    echo "Usage: n folder1 [folder2 [folder3 ...]]"
    return 1
  else
    __n_next
  fi
}

function __n_help() {
  echo "Options (uses ENV variables):"
  echo "  QUIET=1 n   Do not show n-related messages."
  echo
  echo "Commands:"
  echo ""
  echo "--help, -h    Show this message."
  echo "--set \$@     Set the folders to \$@.  Default action when \$@ is given."
  echo "--curr, -c    Go back to the current folder."
  echo "--next, -n    Go to the next folder.  Default action when no arguments are given."
  echo "--prev, -p    Go to the previous folder."
  echo "--goto, -g    Go to a specific folder (0-indexed)."
  echo "-0, -1, …[n]  Alias for --goto [n]"
  echo "--reset       Go back to the \"root\" folder and reset the loop."
  echo "--save, -s    Save the current folders to .n_saved"
  echo "--recall, -r  Recall folders from .n_saved"
  echo "--shell, -i   Run an interactive shell in each folder."
  echo "--exec, -x    Run a command in each folder."
  echo "--list, -l    List the folders, one folder per line. Suitable for piping into STDOUT."
  echo "--show        Show the folders, marking the current folder and showing the --goto index."
  echo "--macro, -m   Start recording a macro.  Starts in the first folder."
  echo "--stop, -k    Stop recording a macro and execute in all folders.  Skips the first folder."
}

function __n_h {
  __n_help "$@"
}


function __n_set() {
  __n_folders=("$@")
  __n_pwd="$PWD"
  __n_i=-1
  __n_curr
}


function __n_curr() {
  cd "$__n_pwd"

  if [[ "$__n_i" -eq -1 ]]; then
    return
  fi

  cd "${__n_folders[$__n_i]}" > /dev/null
}

function __n_c {
  __n_curr "$@"
}


function __n_goto() {
  if [[ -n "$1" ]]; then
    __n_i=$1
    cd "$__n_pwd"
    cd "${__n_folders[$__n_i]}" > /dev/null
  else
    __n_list "1"
  fi

}
function __n_g {
  __n_goto "$@"
}

function __n_next() {
  cd "$__n_pwd"

  __n_i=$(($__n_i + 1))

  if [[ "$__n_i" -ge "${#__n_folders[@]}" ]]; then
    __n_i=-1
    return
  fi

  cd "${__n_folders[$__n_i]}" > /dev/null
}

function __n_n() {
  __n_next "$@"
}

function __n_prev() {
  cd "$__n_pwd"

  if [[ "$__n_i" -eq -1 ]]; then
    __n_i="${#__n_folders[@]}"
  elif [[ "$__n_i" -eq 0 ]]; then
    __n_i=-1
    return
  fi

  __n_i=$(($__n_i - 1))

  cd "${__n_folders[$__n_i]}" > /dev/null
}

function __n_p() {
  __n_prev "$@"
}

function __n_reset() {
  cd "$__n_pwd"
  __n_i=-1
}

function __n_save() {
  local folder
  local n_saved
  n_saved="$__n_pwd/.n_saved"

  if [[ -f "$n_saved" ]]; then
    rm "$n_saved"
  fi

  touch "$n_saved"
  for folder in "${__n_folders[@]}"
  do
    echo "$folder" >> "$n_saved"
  done
  cd "$__n_pwd"

  return 0
}

function __n_s() {
  __n_save "$@"
}

function __n_recall() {
  local folder
  local n_saved
  n_saved=".n_saved"

  if [[ ! -f "$n_saved" ]]; then
    echo ".n_saved not found"
  else
    IFS=$'\n' __n_folders=(`cat .n_saved`)
    __n_pwd="$PWD"
    __n_i=-1
  fi

  __n_curr

  return 0
}

function __n_r() {
  __n_recall "$@"
}

function __n_shell() {
  local folder
  local i
  for folder in "${__n_folders[@]}"
  do
    i=$(($i + 1))
    if [[ -z $QUIET ]]; then
      echo -e ">>> \033[34;1min $folder\033[0m ($i of ${#__n_folders[@]}) <<<"
    fi
    (  cd "$__n_pwd/$folder" ; bash -l )
  done
  if [[ -z $QUIET ]]; then
    echo -e "<<< \033[34;1mAND WE'RE BACK\033[0m >>>"
  fi
  return 0
}

function __n_i {
  __n_shell "$@"
}

function __n_exec() {
  local folder
  local i
  local pwd="$PWD"
  for folder in "${__n_folders[@]}"
  do
    i=$(($i + 1))
    if [[ -z $QUIET ]]; then
      echo -e ">>> \033[34;1min $folder\033[0m ($i of ${#__n_folders[@]}) <<<"
    fi
    for cmd in "$@"; do
      if [[ -z $QUIET ]]; then
        cd "$__n_pwd"
        cd "$folder"
      else
        cd "$__n_pwd" 1>&2 > /dev/null
        cd "$folder"  1>&2 > /dev/null
      fi
      eval $cmd
    done
  done
  if [[ -z $QUIET ]]; then
    echo -e "<<< \033[34;1mAND WE'RE BACK\033[0m >>>"
  fi
  __n_curr
  return 0
}

function __n_x {
  __n_exec "$@"
}


function __n_show() {
  local folder
  local i
  local count
  local padding
  local indent

  i=0
  count="${#__n_folders[@]}"

  for folder in "${__n_folders[@]}"
  do
    if [[ $i -eq $__n_i ]]; then
      indent="* "
    else
      indent="  "
    fi

    if [[ $count -gt 9 && $i -lt 10 ]]; then
      padding=' '
    else
      padding=''
    fi

    echo "$indent$padding$i. $folder"
    i=$(($i + 1))
  done
  return 0
}


function __n_list() {
  if [[ -z "$__n_folders" ]]; then
    __n_recall > /dev/null
  fi

  local folder
  for folder in "${__n_folders[@]}"
  do
    echo "$__n_pwd/$folder"
  done
  return 0
}

function __n_l() {
  __n_list "$@"
}

function __n_macro() {
  __n_i=0
  __n_curr
  __n_orighist="$HISTFILE"
  __n_history="$__n_pwd/.n_history"

  history -a
  HISTFILE="$__n_pwd/.n_history"

  if [[ -f "$__n_history" ]]; then
    rm "$__n_history"
  fi

  echo "Recording history in ${HISTFILE/$HOME/'~/'}"
}

function __n_m() {
  __n_macro "$@"
}

function __n_stop() {
  if [[ ! -f "$__n_history" ]]; then
    if [[ -n "$__n_orighist" ]]; then
      echo -e "\033[31;1mABORTING\033[0m"
      HISTFILE="$__n_orighist"
      return 1
    else
      echo "No .n_history file found"
      return 1
    fi
  fi

  HISTFILE="$__n_orighist"
  history -r

  cat "$__n_history"
  local confirm
  echo
  echo -n -e "\033[1mEverything look ok?\033[0m [y]"
  read confirm
  if [[ -z "$confirm" || $confirm = "y" ]]; then
    local folder
    local i
    for folder in "${__n_folders[@]}"
    do
      cd "$__n_pwd/$folder"

      i=$(($i + 1))
      if [[ -z $QUIET ]]; then
        echo -e ">>> \033[34;1min $folder\033[0m ($i of ${#__n_folders[@]}) <<<"
      fi
      source "$__n_history"
      if [[ -z $QUIET ]]; then
        echo -e "<<< \033[34;1mDONE\033[0m >>>"
      fi
      echo -n "[press enter]"
      read
    done
    __n_curr
    if [[ -z $QUIET ]]; then
      echo -e "<<< \033[34;1mAND WE'RE BACK\033[0m >>>"
    fi
  else
    echo -e "<<< \033[31;1mABORTING\033[0m >>>"
  fi

  if [[ -f "$__n_history" ]]; then
    rm "$__n_history"
  fi

  __n_curr
  return 0

}

function __n_k() {
  __n_stop "$@"
}

export -f n
