
function n () {
  if [[ -n "$1" && "${1:0:2}" = "--" ]]; then
    cmd="__n_${1:2}"
    $cmd "${@:2}"
    return $?
  elif [[ -n "$1" && "${1:0:1}" = "-" ]]; then
    cmd="__n_${1:1}"
    $cmd "${@:2}"
    return $?
  elif [[ -n "$@" ]]; then
    __n_set "$@"
  elif [[ -z "$__n_folders" ]]; then
    echo "Usage: n folder1 [folder2 [folder3 ...]]"
    return 1
  else
    # if [[ "$0" ]]
    echo "$0"
    __n_next
  fi
}

function __n_set() {
  __n_folders=("$@")
  __n_pwd="$PWD"
  __n_i=0
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

function __n_0() {
  __n_reset "$@"
}

function __n_save() {
  local folder
  local n_saved
  n_saved="$__n_pwd/.n_saved"

  if [[ -f "$n_saved" ]]; then
    rm "$n_saved"
  fi

  for folder in "${__n_folders[@]}"
  do
    echo "$folder" >> "$n_saved"
  done

  return 0
}

function __n_s() {
  __n_save "$@"
}

function __n_recall() {
  local folder
  local n_saved
  n_saved="$PWD/.n_saved"

  if [[ ! -f "$n_saved" ]]; then
    echo ".n_saved not found"
  else
    __n_folders=(`cat .n_saved`)
    __n_pwd="$PWD"
    __n_i=0
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
    echo -e ">>> \033[34;1min $folder\033[0m ($i of ${#__n_folders[@]}) <<<"
    (  cd "$__n_pwd/$folder" ; bash -l )
  done
  echo -e "<<< \033[34;1mAND WE'RE BACK\033[0m >>>"
  return 0
}

function __n_i {
  __n_shell "$@"
}

function __n_exec() {
  local folder
  local i
  for folder in "${__n_folders[@]}"
  do
    i=$(($i + 1))
    echo -e ">>> \033[34;1min $folder\033[0m ($i of ${#__n_folders[@]}) <<<"
    for cmd in "$@"; do
      cd "$__n_pwd/$folder"
      eval $cmd
    done
  done
  echo -e "<<< \033[34;1mAND WE'RE BACK\033[0m >>>"
  __n_curr
  return 0
}

function __n_x {
  __n_exec "$@"
}

function __n_list() {
  local folder
  local i
  local indent
  echo "${__n_pwd/$HOME/~}"
  i=0
  for folder in "${__n_folders[@]}"
  do
    indent="  "
    if [[ $i -eq $__n_i ]]; then
      indent="* "
    fi
    echo "$indent $folder"
    i=$(($i + 1))
  done
  return 0
}

function __n_l() {
  __n_list "$@"
}

export -f n
