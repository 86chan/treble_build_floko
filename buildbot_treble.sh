#!/bin/bash
echo ""
echo "FlokoROM v4 Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
#echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
#sleep 5

export LANG=C
export LC_ALL=C.UTF-8
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export CCACHE_DIR=~/ccache
export USE_CCACHE=1

# Abort early on error
set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
BL=$PWD/treble_build_floko

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/manifest.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

rm -rf vendor/seedvault/

repopick 289372 # Messaging: Add "Mark as read" quick action for message notifications

echo "Reverting LOS FOD implementation"
cd frameworks/base
git am $BL/patches/F0001-Squashed-revert-of-LOS-FOD-implementation.patch
cd ../..
cd frameworks/native
git revert 381416d540ea92dca5f64cd48fd8c9dc887cac7b --no-edit # surfaceflinger: Add support for extension lib
cd ../..
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
bash generate.sh lineage
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches
echo ""

echo "Applying universal patches"
cd build/make
git am $BL/patches/0001-Make-broken-copy-headers-the-default.patch
cd ../..
cd frameworks/base
#git am $BL/patches/0001-UI-Revive-navbar-layout-tuning-via-sysui_nav_bar-tun.patch
git am $BL/patches/0001-UI-Disable-wallpaper-zoom.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
cd ../..
cd lineage-sdk
git am $BL/patches/0001-sdk-Invert-per-app-stretch-to-fullscreen.patch
cd ..
#cd packages/apps/Jelly
#git am $BL/patches/0001-Jelly-MainActivity-Restore-applyThemeColor.patch
#cd ../../..
cd packages/apps/LineageParts
git am $BL/patches/0001-LineageParts-Invert-per-app-stretch-to-fullscreen.patch
cd ../../..
cd packages/apps/Trebuchet
git am $BL/patches/0001-Trebuchet-Move-clear-all-button-to-actions-view.patch
cd ../../..
cd vendor/lineage
git am $BL/patches/0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd bootable/recovery
git revert 0e369f42b82c4d12edba9a46dd20bee0d4b783ec --no-edit # recovery: Allow custom bootloader msg offset in block misc
cd ../..
cd build/make
git am $BL/patches/0001-build-Don-t-handle-apns-conf.patch
git revert 78c28df40f72fdcbe3f82a83828060ad19765fa1 --no-edit # mainline_system: Exclude vendor.lineage.power@1.0 from artifact path requirements
cd ../..
cd device/phh/treble
#git revert 82b15278bad816632dcaeaed623b569978e9840d --no-edit # Update lineage.mk for LineageOS 16.0
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-treble-Add-overlay-lineage.patch
git am $BL/patches/0001-treble-Don-t-specify-config_wallpaperCropperPackage.patch
git am $BL/patches/0001-treble-Don-t-handle-apns-conf.patch
git am $BL/patches/0001-add-offline-charger-sepolicy.patch
cd ../../..
cd frameworks/av
git revert 5a5606dbd92f01de322c797a7128fce69902d067 --no-edit # camera: Allow devices to load custom CameraParameter code
cd ../..
cd frameworks/native
git revert 581c22f979af05e48ad4843cdfa9605186d286da --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd packages/apps/Bluetooth
git revert 4ceb47e32c1be30640e40f81b6f741942f8598ed --no-edit # Bluetooth: Reset packages/apps/Bluetooth to upstream
cd ../../..
cd system/core
git am $BL/patches/F0001-Revert-init-Add-vendor-specific-initialization-hooks.patch
git am $BL/patches/0001-Panic-into-recovery-rather-than-bootloader.patch
git am $BL/patches/F0001-Restore-sbin-for-Magisk-compatibility.patch
git am $BL/patches/0001-fix-offline-charger-v7.patch
cd ../..
cd system/hardware/interfaces
git revert cb732f9b635b5f6f79e447ddaf743ebb800b8535 --no-edit # system_suspend: start early
cd ../../..
cd system/sepolicy
git am $BL/patches/0001-Revert-sepolicy-Relabel-wifi.-properties-as-wifi_pro.patch
cd ../..
cd vendor/lineage
#git am $BL/patches/0001-build_soong-Disable-generated_kernel_headers.patch
git am $BL/patches/F0001-Fix-changelog-error.patch
git am $BL/patches/F0002-Remove-su.patch
cd ../..
echo ""

echo "CHECK PATCH STATUS NOW!"
#sleep 5
echo ""

export WITHOUT_CHECK_API=true
export WITH_SU=false
mkdir -p ~/build-output/

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    mv $OUT/system.img ~/build-output/FlokoROM-v4-$BUILD_DATE-UNOFFICIAL-${1}.img
}

#buildVariant treble_arm_bvS
#buildVariant treble_a64_bvS
buildVariant treble_arm64_bvN
ls ~/build-output | grep 'FlokoROM'

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
