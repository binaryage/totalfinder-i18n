#!/bin/bash

# xib -> nib
for xib in `ls -d plugin/*.xib`; do echo "Compiling $xib ..."; ibtool --errors --warnings --notices --output-format human-readable-text --compile "`echo $xib | cut -d'.' -f1`.nib" "$xib"; done