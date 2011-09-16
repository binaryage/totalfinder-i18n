#!/bin/bash
TOTALFINDER_RESOURCES='/Library/ScriptingAdditions/TotalFinder.osax/Contents/Resources/TotalFinder.bundle/Contents/Resources'
TOTALFINDER_RESOURCES_BACKUP='/Library/ScriptingAdditions/TotalFinder.osax/Contents/Resources/TotalFinder.bundle/Contents/ResourcesOrig'

if [ -d "$TOTALFINDER_RESOURCES" ]; then # is it a folder?
    if [ -L "$TOTALFINDER_RESOURCES" ]; then # is it a symlink?
        sudo rm "$TOTALFINDER_RESOURCES"
        sudo mv "$TOTALFINDER_RESOURCES_BACKUP" "$TOTALFINDER_RESOURCES"
        exit
    fi
fi

echo "Failed: TotalFinder is not installed or in dev mode"