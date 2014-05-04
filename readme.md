# TotalFinder Internationalization

**[TotalFinder](http://totalfinder.binaryage.com)** is a plugin for Apple's Finder.app which brings tabs, dual panels and more! This project gathers localizable resources.

<img width="500" src="http://totalfinder.binaryage.com/images/showcase/showcase-dual-mode.png">

## Do you want to translate TotalFinder into your language?

You can tweak resource files and add your preferred language.

The idea is to install TotalFinder and then symlink its `Resources` folder to the copy of this repository where you can edit it.
You should push your changes back to GitHub and I will then incorporate your work into [next TotalFinder release](http://totalfinder.binaryage.com/beta-changes).

You may want to read [TotalFinder opened for localization](http://blog.binaryage.com/totalfinder-localization/) blog post.

## Where to start?

1. Read something about git version control system. Here is [the best place to start](http://git-scm.comhttp://totalfinder.binaryage.com/about).
2. Get familiar with GitHub. They have also [nice docs](http://help.github.com).
3. Create GitHub user and don't forget to [setup your local git](http://help.github.com/mac-set-up-git) so your commits are linked to your GitHub account.
4. See how others are working on [TotalFinder localization](http://github.com/binaryage/totalfinder-i18n/network).

## The Workflow

### Initial step

1. [fork this project](http://help.github.com/fork-a-repo) on GitHub
2. [clone your fork](http://help.github.com/remotes) (let's assume you have it in `~/totalfinder-i18n`)
3. make sure you have [installed latest TotalFinder](http://totalfinder.binaryage.com/beta-changes) version
4. `cd ~/totalfinder-i18n` and run `./bin/dev.sh`

### Development

1. edit files
2. validate your changes with `rake validate` (before first run execute `sudo gem install cmess colored mg` to install supporting library)
3. use `./bin/restart.sh` to restart TotalFinder to reflect your changes
4. commit if needed - you can `./bin/commit.sh`
5. goto 1

### Final step

1. [push to github](http://help.github.com/remotes) and send a [pull request](http://help.github.com/pull-requests)
2. (optional) run `./bin/undev.sh` to return to unaltered TotalFinder state (this won't delete your files, it will [just unlink](totalfinder-i18n/blob/master/undev.sh) sym-linked folder)

## Questions?

### What encoding should I use for my files?
> Please always use UTF-8. Other encodings will probably fail to load or you will see wrong characters. Run `rake validate` task to check your files.

### I have created MYLANGUAGE.lproj and modified string files.<br>I've restarted the Finder.app, but I don't see my localization. What's wrong?
> And do you see Finder.app in MYLANGUAGE?
>
> First, double check you have MYLANGUAGE as top-most language in the `System Preferences > Language & Text > Language` list.
>
> Second, please note that TotalFinder is a plugin for Finder.app and it inherits preferred language from Finder.app. Finder.app does not pick MYLANGUAGE if `/System/Library/CoreServices/Finder.app/Contents/Resources/MYLANGUAGE.lproj` does not exist. You may create empty folder by hand or you may fix this by running `sudo rake normalize` task, which will create missing folders in `/System/Library/CoreServices/Finder.app/Contents/Resources` according to language folders available in TotalFinder's Resources.

## Thank you!

Every contributor in [http://github.com/binaryage/totalfinder-i18n/contributors](http://github.com/binaryage/totalfinder-i18n/contributors) will get a free TotalFinder license. Please note that you will appear there with delay and only if your commits are properly recognized as authored by your github's account. You have to [setup your local git user](http://help.github.com/git-email-settings) properly.

**To be clear. Please note that:**

1. I may not accept changes in your fork
2. You are contributing your work under [MIT license](totalfinder-i18n/raw/master/license.txt)
3. You may want to explore [Network Graph](http://github.com/binaryage/totalfinder-i18n/network) to see if someone has been already working on your language

#### License: [MIT-Style](https://raw.github.com/binaryage/totalfinder-i18n/master/license.txt)
