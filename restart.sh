#!/bin/bash

# quit Finder
osascript -e "tell application \"Finder\" to quit"

killall -SIGINT TotalFinderCrashWatcher

# compile xibs - skip this for now
# it depends on custom plugin I had
# Failure Reason: Could not determine the location of the plug-in with the identifier net.wafflesoftware.ShortcutRecorder.IB.Leopard
# ./compile.sh

# start TotalFinder agan
open /Applications/TotalFinder.app