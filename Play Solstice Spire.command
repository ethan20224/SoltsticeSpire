#!/bin/zsh
# Double-clickable native macOS Forward+ launcher for Solstice Spire
cd "$(dirname "$0")"
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$(pwd)"
