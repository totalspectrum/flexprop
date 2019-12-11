#!/bin/sh
osascript <<EOF
tell application "Terminal"
  do script "$*"
end tell
EOF
osascript -e 'tell application "Terminal" to activate'
