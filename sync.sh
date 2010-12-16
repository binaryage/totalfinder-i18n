#!/bin/bash

echo "This may end in conflict, see git docs."

#point to server
read -p "Is this the first time you sync? [y/n] " -n 1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
	git remote add ba git://github.com/binaryage/totalfinder-i18n.git
	echo "Pointed!"
fi

#merge repos
git fetch ba && git merge ba/master
echo "Merged!"

#push to GitHub
read -p "Do you want to push to GitHub? This will update the online repo with any commit you made since last push. Until you do this, changes won't be in your GitHub fork. [y/n] " -n 1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
	git push
	echo "Pushed!"
fi