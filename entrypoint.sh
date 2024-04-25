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
    if [ "$ROOT_PASSWORD" != '' ]; then
      echo "Changing root password" >&2
      echo "root:$ROOT_PASSWORD" | chpasswd
      unset ROOT_PASSWORD
    fi
    if [ "$APP_PASSWORD" != '' ]; then
      echo "Changing root password" >&2
      echo "app:$APP_PASSWORD" | chpasswd
      unset APP_PASSWORD
    fi
  fi

  args=("$@")

  if [ "$#" -eq "0" ]; then
    set -- supervisord -n
  fi

  exec "$@"
}


if ! _is_sourced; then
	_main "$@"
fi