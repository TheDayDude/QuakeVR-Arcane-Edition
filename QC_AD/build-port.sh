#!/bin/sh
# FTEQCC may be an absolute executable path or a command on PATH.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
compiler=${FTEQCC:-fteqcc}
case "$compiler" in
    /*) ;;
    */*) compiler="$(pwd)/$compiler" ;;
esac
cd "$script_dir/game"
exec "$compiler" -O2
