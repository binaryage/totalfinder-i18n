# TotalFinder Internationalization ([totalfinder.binaryage.com](http://totalfinder.binaryage.com))

**TotalFinder** is a plugin for Apples's Finder.app which brings tabs, dual panels and more! This project gathers localizable resources.

<img src="http://totalfinder.binaryage.com/shared/img/totalfinder-mainshot.png">

## Do you want to translate TotalFinder into your language?

TotalFinder is not an open-source, but you should be still able to easily tweak resource files and add your preferred language.

The idea is to install TotalFinder and then sym-link its `Resources` folder to the copy of this repository where you can edit it.
When you are satisfied with your work, you should push your changes back to GitHub. I will then incorporate your work into next TotalFinder release.

## The Workflow

### Initial step

1. fork this project on GitHub
2. clone your fork (let's assume you have it in `~/totalfinder-i18n`)
3. make sure you have installed latest TotalFinder version
4. `cd ~/totalfinder-i18n` and run `./dev.sh`

### Development

1. edit files
2. use `./restart.sh` to restart TotalFinder to reflect your changes
3. commit if needed
4. goto 1

### Final step

1. push to github and send a pull request to [darwin](http://github.com/darwin)
2. (optional) run `./undev.sh` to return to unaltered TotalFinder state (this won't delete your files, it will [just unlink](totalfinder-i18n/blob/master/undev.sh) sym-linked folder)

## Thank you!

Each contributor in [http://github.com/binaryage/totalfinder-i18n/contributors](http://github.com/binaryage/totalfinder-i18n/contributors) will get a free TotalFinder license.

**To be clear. Please note that:**

1. I may not accept changes in your fork
2. You are contributing your work under [MIT license](totalfinder-i18n/raw/master/license.txt)
3. You may want to explore [Network Graph](http://github.com/binaryage/totalfinder-i18n/network) to see if someone has not already been working on your language

#### License: [MIT-Style](totalfinder-i18n/raw/master/license.txt)