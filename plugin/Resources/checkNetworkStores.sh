#!/bin/sh
STATUS=`defaults read com.apple.desktopservices DSDontWriteNetworkStores`
if [ "$STATUS" == "true" ]; then
    exit 1
fi
exit 0
