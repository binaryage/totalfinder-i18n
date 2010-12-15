#!/bin/bash

echo "This may end in conflict, see git docs."

#point to server
git remote add ba git://github.com/binaryage/totalfinder-i18n.git

#merge repos
git fetch ba && git merge ba/master

echo "Synced!"