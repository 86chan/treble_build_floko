#!/bin/bash
echo ""
echo "LineageOS 18.x Unified Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
# sleep 5

export LANG=C
export LC_ALL=C.UTF-8
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export CCACHE_DIR=~/ccache
export USE_CCACHE=1

BUILD_OUT=../build-output

if [ $# -lt 2 ]
then
    echo "Not enough arguments - exiting"
    echo ""
    exit 1
fi

MODE=${1}
if [ ${MODE} != "device" ] && [ ${MODE} != "treble" ]
then
    echo "Invalid mode - exiting"
    echo ""
    exit 1
fi

PERSONAL=false
if [ ${!#} == "personal" ]
then
    PERSONAL=true
fi

# Abort early on error
#set -eE
#trap '(\
#echo;\
#echo \!\!\! An error happened during script execution;\
#echo \!\!\! Please check console output for bad sync,;\
#echo \!\!\! failed patch application, etc.;\
#echo\
#)' ERR

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
WITHOUT_CHECK_API=true
WITH_SU=false

echo "Preparing local manifests"
mkdir -p .repo/local_manifests
if [ ${MODE} == "device" ]
then
    rm -rf .repo/local_manifests/manifest.xml
fi
cp ./treble_build_floko/local_manifests_${MODE}/*.xml .repo/local_manifests
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
pwd
exit
mkdir -p $BUILD_OUT
echo ""

rm -rf vendor/seedvault/

apply_patches() {
    echo "Applying patch group ${1}"
    bash ../treble_experimentations/apply-patches.sh ./lineage_patches_unified/${1}
}

apply_my_patches() {
    echo "Applying my patch"
    bash ../treble_experimentations/apply-patches.sh ./treble_build_floko/patches
}

prep_device() {
    :
}

prep_treble() {
    apply_patches patches_treble_prerequisite
    apply_patches patches_treble_phh
}

finalize_device() {
    :
}

finalize_treble() {
    rm -f device/*/sepolicy/common/private/genfs_contexts
    cd device/phh/treble
    git clean -fdx
    bash generate.sh lineage
    cd ../../..
}

build_device() {
    brunch ${1}
    mv $OUT/FlokoROM-*.zip $BUILD_OUT/FlokoROM-v4-$BUILD_DATE-UNOFFICIAL-${1}$($PERSONAL && echo "-personal" || echo "").zip
}

build_treble() {
    case "${1}" in
        ("32B") TARGET=treble_arm_bvN;;
        ("A64B") TARGET=treble_a64_bvN;;
        ("64B") TARGET=treble_arm64_bvN;;
        (*) echo "Invalid target - exiting"; exit 1;;
    esac
    lunch ${TARGET}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    mv $OUT/system.img $BUILD_OUT/FlokoROM-v4-$BUILD_DATE-UNOFFICIAL-${TARGET}$(${PERSONAL} && echo "-personal" || echo "").img
}

if [ ${MODE} != "device" ]
then
    echo "*****Applying patches*****"
    prep_${MODE}
    apply_patches patches_platform
    apply_patches patches_${MODE}
    apply_my_patches
    if ${PERSONAL}
    then
        apply_patches patches_platform_personal
        apply_patches patches_${MODE}_personal
    fi
fi
finalize_${MODE}
echo ""

for var in "${@:2}"
do
    if [ ${var} == "personal" ]
    then
        continue
    fi
    echo "Starting $(${PERSONAL} && echo "personal " || echo "")build for ${MODE} ${var}"
    build_${MODE} ${var}
done
ls $BUILD_OUT | grep 'lineage' || true

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
