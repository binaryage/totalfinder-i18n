#!/bin/bash
TOTALFINDER_RESOURCES='/Applications/TotalFinder.app/Contents/Resources/TotalFinder.bundle/Contents/Resources'
TOTALFINDER_RESOURCES_BACKUP='/Applications/TotalFinder.app/Contents/Resources/TotalFinder.bundle/Contents/ResourcesOrig'

# need absolute path of the repo's root
dir=`dirname $0`
pushd "$dir" > /dev/null
ROOT=$PWD
popd > /dev/null

if [ ! -d "$TOTALFINDER_RESOURCES" ]; then # is it a folder?
    echo "Please install TotalFinder. Folder '$TOTALFINDER_RESOURCES' not found".
    exit
fi

if [ -L "$TOTALFINDER_RESOURCES" ]; then # is is a symlink?
    echo "TotalFinder is already in dev mode. Folder '$TOTALFINDER_RESOURCES' is a symlink! Exiting.".
    exit
fi

# ok, we should be safe to do the replacement
sudo mv "$TOTALFINDER_RESOURCES" "$TOTALFINDER_RESOURCES_BACKUP"
sudo ln -s "$ROOT/plugin" "$TOTALFINDER_RESOURCES"
sudo cp "$TOTALFINDER_RESOURCES_BACKUP/"*.nib "$TOTALFINDER_RESOURCES" # steal compiled nibs from production