#!/bin/sh
osascript <<EOF
tell application "Terminal"
  do script "$*; exit 0"
  activate
end tell
EOF

