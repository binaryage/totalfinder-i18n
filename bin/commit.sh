#!/bin/bash

pushd . > /dev/null
cd "$(dirname "$0")"
cd ..

echo "Committing last changes..."
echo "Note you maybe have to manually add new files you changed ('git add mynewfile.ext')"

#ask for a message
read -p "Write a commit message to identify this commit and its changes and press ENTER: "
git commit -a -m "$REPLY"

read -p "Succesfully commited! Do you want to push? [y/n] " -n 1
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git push
  echo "Pushed!"
fi

popd > /dev/null
