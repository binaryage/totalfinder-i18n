#!/bin/bash

# quit Finder
osascript -e "tell application \"Finder\" to quit"

# compile xibs
./compile.sh

# start TotalFinder agan
open /Applications/TotalFinder.app