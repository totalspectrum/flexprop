#!/bin/sh
osascript <<EOF
tell application "Terminal"
  do script "$*; osascript -e 'tell application \"flexprop.mac\" to activate'; exit 0"
  activate
end tell
EOF

