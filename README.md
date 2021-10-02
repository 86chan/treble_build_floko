
## Building PHH-based FlokoROM GSIs ##

To get started with building FlokoROM GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html), and set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/redfin/build) (mainly "Install the build packages") and [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory.  Clone the modified treble_experimentations repo there:

    git clone https://github.com/AndyCGYan/treble_experimentations

Hint ! If you want to use this customized repository:

    git clone https://github.com/AndyCGYan/treble_experimentations

Create a new working directory for your FlokoROM build and navigate to it:

    mkdir floko-gsi; cd floko-gsi

Initialize your FlokoROM workspace:

    repo init -u https://github.com/FlokoROM/manifesto.git -b 11.0

Clone both this and the patches repos:

    git clone https://github.com/FlokoROM-GSI/treble_build_floko -b 11.0-unified
    git clone https://github.com/FlokoROM-GSI/lineage_patches_unified -b 11.0-unified

Hint ! If you want to use this customized repository:

    git clone https://github.com/86chan/treble_build_floko.git -b 11.0
    git clone https://github.com/FlokoROM-GSI/lineage_patches_unified -b 11.0-unified


Finally, start the build script - for example, to build for all supported archs:

    bash treble_build_floko/buildbot_unified.sh treble 64B

Be sure to update the cloned repos from time to time!

---

Note: A-only and VNDKLite targets are generated from AB images instead of source-built - refer to [sas-creator](https://github.com/AndyCGYan/sas-creator).

---

This script is also used to make device-specific and/or personal builds. To do so, understand the script, and try the `device` and `personal` keywords.

---

## How to make ROM-specific patch? ##

Sometimes you have to create patch to fix conflict.  
Step to create patch:

1. Manually patch
```
    BL=$PWD/treble_build_floko  
    cd frameworks/base  
    git am $BL/patches/F0001-Squashed-revert-of-LOS-FOD-implementation.patch
```
2. When patch error happens, you can re-apply patch by this command. If you want to manually apply changes, skip this.
```
    patch -p1 < .git/rebase-apply/patch
```
3. Fix conflict and commit

4. Make a patch:
```
    git format-patch -n HEAD^
```
5. Move the patch to treble_build_floko/patches and replace patch file name in buildbot_treble.sh
