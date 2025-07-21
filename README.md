# c1crop
Capture One: Crop Images from EXIF Metadata

## Description
As of version 16.5.0, [Capture One](https://www.captureone.com) still does not consider the digital crop information embedded in certain camera RAW files (such as aspect ratios, "digital zoom" etc.).

This script integrates with Capture One (Mac version only!) to add the missing image crop after images have been imported.

## Prerequisites
This script requires the freeware tool `exiftool` for extracting EXIF metadata from raw image files.

Please install `exiftool` on your Mac before proceeding further. An easy way to do this is via [Homebrew](https://brew.sh) (`brew install exiftool`).

## Installation
* Launch Capture One on your Mac.
* In Capture One, select the menu item _Scripts_ -> _Open Scripts Folder_.
* Copy the script `Crop from Metadata.applescript` from this repository to the scripts folder.
* In Capture One, select the menu item _Scripts_ -> _Update Scripts Menu_. A new entry named _Crop from Metadata_ should now appear in the menu.

## Usage
* In Capture One, select one or multiple images you wish to crop.
* Select the menu item _Scripts_ -> _Crop from Metadata_.

## Effects
* Images for which crop information has been found in the raw file's metadata will be cropped accordingly.
* Images without recognizable crop information will be left unaffected.
* A progress bar will appear while each image is being processed.

## Tested Cameras
I have tested this script with the following cameras so far:
* **Leica SL2-S** (APS-C mode = 1.5x crop on/off)
* **Fujifilm X100VI** (crop via "Digital Teleconverter" feature)
* **Fujifilm GFX 50R, GFX 100, GFX 100RF** (crop via "Aspect Ratio" feature)
* **Sony Alpha 7C II** (does not require this script since Capture One natively crops images in ARW files from this camera)
