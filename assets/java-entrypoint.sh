#!/usr/bin/env bash
set -e

if [[ "$GOSU_USER" ]]; then
  exec gosu $GOSU_USER /ubuntu-entrypoint.sh "$@"
else
  exec /ubuntu-entrypoint.sh "$@"
fi
