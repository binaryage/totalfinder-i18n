#!/bin/sh

$1 || system_profiler

echo "==== Checking TotalFinder.app"
ls -l /Applications | grep TotalFinder
$1 || ls -lR /Applications/TotalFinder.app

echo "==== Checking TotalFinder.osax"
ls -l "/Library/ScriptingAdditions" | grep TotalFinder
$1 || ls -lR "/Library/ScriptingAdditions/TotalFinder.osax"

echo "==== Checking TotalFinder.kext"
ls -l /System/Library/Extensions | grep TotalFinder
$1 || ls -lR /System/Library/Extensions/TotalFinder.kext

echo "==== Checking system config"
sw_vers
echo "Ruby version: `/usr/bin/ruby -v`"

$1 || echo
$1 || echo "Environment:"
$1 || env

