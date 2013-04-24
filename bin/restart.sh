#!/bin/bash

pushd . > /dev/null
cd "$(dirname "$0")"
cd ..

# quit Finder
osascript -e "tell application \"Finder\" to quit"

killall -SIGINT TotalFinderCrashWatcher

# start TotalFinder agan
open /Applications/TotalFinder.app

popd > /dev/null
