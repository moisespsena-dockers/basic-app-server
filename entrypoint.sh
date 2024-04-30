#!/bin/bash

set -Eeo pipefail

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_main() {
  if [ $(id -u) -eq 0 ]; then
    local ROOT_PASSWORD="${ROOT_PASSWORD:-}"
    local APP_PASSWORD="${APP_PASSWORD:-}"

    if [ "$ROOT_PASSWORD" != '' ]; then
      echo "Changing 'root' password" >&2
      echo "root:$ROOT_PASSWORD" | chpasswd
      unset ROOT_PASSWORD
    fi
    if [ "$APP_PASSWORD" != '' ]; then
      echo "Changing 'app' password" >&2
      echo "app:$APP_PASSWORD" | chpasswd
      unset APP_PASSWORD
    fi
  fi

  args=("$@")

  if [ "$#" -eq "0" ]; then
    set -- main.sh
  fi

  for var in "$@"
  do
      echo "=> $var"
  done

  if [ ! -e /data/.initialized ]; then
    setup.sh || return $?
    touch /data/.initialized
  fi

  exec "$@"
}


if ! _is_sourced; then
	_main "$@"
fi