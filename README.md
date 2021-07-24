
## Building PHH-based FlokoROM GSIs ##

To get started with building FlokoROM GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html) as well as [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory.  Clone the modified treble_experimentations repo there:

    git clone https://github.com/AndyCGYan/treble_experimentations

Create a new working directory for your FlokoROM build and navigate to it:

    mkdir floko-gsi; cd floko-gsi

Initialize your FlokoROM workspace:

    repo init -u https://github.com/FlokoROM/android.git -b 11.0

Clone the modified treble patches and this repo:

    git clone https://github.com/AndyCGYan/treble_patches -b lineage-18.1
    git clone https://github.com/FlokoROM-GSI/treble_build_floko -b 11.0

Finally, start the build script:

    bash treble_build_floko/buildbot_treble.sh

Be sure to update the cloned repos from time to time!

---

Note: A-only and VNDKLite targets are now generated from AB images - refer to [sas-creator](https://github.com/phhusson/sas-creator).
