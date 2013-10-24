#!/bin/bash

pushd . > /dev/null
cd "$(dirname "$0")"
cd ..

# quit Finder
osascript -e "tell application \"Finder\" to quit"

killall -SIGINT TotalFinderCrashWatcher

# start TotalFinder again
sleep 1
osascript -e "tell application \"Finder\" to «event BATFinit»"

popd > /dev/null
