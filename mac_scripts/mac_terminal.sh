#!/bin/sh
osascript <<EOF
tell application "Terminal"
  do script "$*; osascript -e 'tell application \"Wish\" to activate'; exit 0"
  activate
end tell
EOF

