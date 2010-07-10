# TotalFinder Internationalization ([totalfinder.binaryage.com](http://totalfinder.binaryage.com))

**TotalFinder** is a plugin for Apples's Finder.app which brings tabs, dual panels and more! This project gathers localizable resources.

<img src="http://totalfinder.binaryage.com/shared/img/totalfinder-mainshot.png">

## Do you want to translate TotalFinder into your language?

TotalFinder is not an open-source, but you should be still able to easily tweak resource files and add your preferred language.

The idea is to install TotalFinder and then sym-link its `Resources` folder to the copy of this repository where you can edit it.
When you are satisfied with your work, you should push your changes back to GitHub. I will then incorporate your work into next TotalFinder release.

## Where to start?

1. Read something about git version control system. Here is [the best place to start](http://git-scm.com/documentation).
2. Get familiar with GitHub. They have also [nice docs](http://help.github.com).
3. Create GitHub user and don't forget to [setup your local git user](http://help.github.com/git-email-settings) so your commits are linked to your GitHub account.
4. See how others are working on [TotalFinder localization](http://github.com/binaryage/totalfinder-i18n/network).

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

1. push to github and send a pull request to [darwin](http://github.com/darwin) (please don't try to send pull requests to binaryage - it is an organisation)
2. (optional) run `./undev.sh` to return to unaltered TotalFinder state (this won't delete your files, it will [just unlink](totalfinder-i18n/blob/master/undev.sh) sym-linked folder)

## Questions?

### I want to modify the UI. How can I compile XIB files?
> Please make sure you have the latest XCode from Apple. Download and compile [ShortcutRecorder project](http://wafflesoftware.net/shortcut). It will give you an Interface Builder plugin for ShortcurRecorder control. No you can open XIB and modify it. TotalFinder uses nibs, to compile them please run `./compile.sh`.

### May I alter dimensions in the UI to fit my language?
> Although it is possible to copy XIB into language folder and make it language-specific I prefer to keep one shared XIB file for all languages. I'm using technique for defining flexible areas to fit different languages as [described here](http://code.google.com/p/google-toolbox-for-mac/wiki/UILocalization). Please see the `TotalFinder.xib` where it is already used on several places in the Preferences Window.

## Thank you!

Each contributor in [http://github.com/binaryage/totalfinder-i18n/contributors](http://github.com/binaryage/totalfinder-i18n/contributors) will get a free TotalFinder license. Please note that you will appear there with delay and only if your commits are properly recognized as authored by your github's account. You have to [setup your local git user](http://help.github.com/git-email-settings) properly.

**To be clear. Please note that:**

1. I may not accept changes in your fork
2. You are contributing your work under [MIT license](totalfinder-i18n/raw/master/license.txt)
3. You may want to explore [Network Graph](http://github.com/binaryage/totalfinder-i18n/network) to see if someone has not already been working on your language

#### License: [MIT-Style](totalfinder-i18n/raw/master/license.txt)