#!/bin/sh
echo -ne '\033c\033]0;Gravity Changer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/AstroRaider.x86_64" "$@"
