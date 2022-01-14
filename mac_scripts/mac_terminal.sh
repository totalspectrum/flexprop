#!/bin/sh
osascript <<EOF
tell application "Terminal"
  do script "$*; osascript -e 'tell application \"flexprop\" to activate'; exit 0"
  activate
end tell
EOF

