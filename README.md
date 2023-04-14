# Portable MSITools
Building a portable msitools for linux to avoid conflicts, problems and requirements.

![My Workflow](https://github.com/gxgl/portable_msitools/actions/workflows/main.yml/badge.svg)

## About
This repo and the result of its code came out for my need to have the msitools availabe on the closed systems where I can't install packages due to lack of root access.

The "build_portable_msitools" script and the build action in this repo is using:
- [GNOME/msitools (readonly repo)](https://github.com/GNOME/msitools)
- [AppImageCrafters/appimage-builder](https://github.com/AppImageCrafters/appimage-builder)
- The msitools.png icon is used from [msi.png](https://www.softicons.com/system-icons/imageboard-filetype-icons-by-lopagof/file-msi-icon)

All the rights on used software and icon goes to their respective owners.

## Tested on:
- :ballot_box_with_check: Linux Mint
- :ballot_box_with_check: Amazon Linux 2
- :ballot_box_with_check: Arch and Manjaro Linux
- :ballot_box_with_check: Ubuntu Linux
- :white_large_square: Alpine Linux
- :negative_squared_cross_mark: Mac OS X (WIP)

> Please let me know if you tested this successfully on other OS to add them in the list

> Also there is WIP for multi linux os version of build_portable_msitools.sh

### Made with :heart: from :romania: