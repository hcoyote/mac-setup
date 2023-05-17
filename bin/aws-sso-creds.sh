#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title aws-sso-creds
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName AWS SSO Creds

# Documentation:
# @raycast.description get aws sso creds into clipboard
# @raycast.author Travis Campbell

source $HOME/.defaults
export AWS_PROFILE

# make sure we can restore clipboard
(
  old=$(pbpaste)
   if osascript -e return >/dev/null 2>&1; then
	   osascript -e 'display notification "Reseting clipboard in 30 seconds" with title "raycast aws-sso-creds restore Clipboard"'
   fi
   sleep "${seconds}"
   echo "${old}" | pbcopy
) &

# make sure we temporarily disable history recording when we paste on the other side
(echo "set +o history"; aws-sso-creds export ; echo "set -o history")| pbcopy
