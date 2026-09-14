#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
exec "${GODOT_BIN:-godot}" --path . "$@"
