# TWRP device tree for Lenovo Yoga Tab Plus (lapis)

TWRP 3.7.1 (twrp-14.1) for the Lenovo Yoga Tab Plus (model **TB520FU**, codename lapis,
Snapdragon 8 Gen 3 / SM8650 "pineapple"), built against ZUI 17.5.10.362
(Android 16). Landscape theme.

| | |
|---|---|
| SoC | SM8650 (pineapple), A/B, virtual A/B |
| Firmware base | ZUI 17.5.10.362 (Android 16; vendor frozen at Android 14, `UKQ1.240826.001`) |
| Kernel | none in recovery.img (boot header v4, the ABL uses the kernel from `boot`); `prebuilt/kernel` (stock GKI 6.1) is only used for the build's VINTF check |
| Panel | 2944×1840 dual-DSI, natively landscape |
| Touch | Novatek, module loaded from `vendor_boot` (`modules.load.recovery`) |
| Encryption | FBE v2 + metadata encryption (`wrappedkey_v0`), QTEE keymint V3 / gatekeeper |
| recovery partition | `recovery_a` / `recovery_b`, 104857600 bytes |
| AVB | signed with the AOSP `testkey_rsa4096`, rollback index 1 (see [Signing](#signing)) |

## Status

Almost everything works:
- `/data` decryption (FBE + metadata) and mount, internal storage, including
  PIN / password / pattern (AIDL GateKeeper, HIDL fallback)
- ADB, MTP
- USB OTG
- display (DRM atomic, split planes over both DSI halves), touch, brightness
- battery / CPU temperature in the status bar
- etc.

SELinux is enforcing. Only the `recovery` domain (TWRP itself and the vendor
services it starts from the ramdisk) is permissive: backup / restore must
touch every file type on `/data`, which the AOSP neverallow rules forbid for
an enforcing domain. logd, kernel, fastboot and init run enforcing with no
denials (`sepolicy/twrp_recovery.te`). `su` is AOSP's own adb-root shell
domain of `eng` builds.

## Build

Any recent x86_64 Linux (Ubuntu 22.04 / 24.04 tested) with ~16 GB RAM and
~100 GB free disk.

### 1. Packages and repo

```bash
sudo apt install bc bison build-essential ccache curl flex g++-multilib gcc-multilib \
    git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev \
    liblz4-tool lz4 libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools xsltproc zip unzip zlib1g-dev \
    python3 python-is-python3 openjdk-11-jdk-headless binutils file cpio \
    erofs-utils e2fsprogs android-sdk-libsparse-utils device-tree-compiler openssl
mkdir -p ~/bin && curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo && chmod +x ~/bin/repo
export PATH=~/bin:$PATH
```

Optional ccache. The Android 14 build sandbox makes everything outside
`out/` read-only, so keep the cache inside `out/`:

```bash
export USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=~/twrp/out/.ccache
```

### 2. Sources

```bash
mkdir -p ~/twrp && cd ~/twrp
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1 --git-lfs
mkdir -p .repo/local_manifests
# save the manifest below as .repo/local_manifests/lapis.xml
repo sync -c -j8 --force-sync --no-clone-bundle --no-tags
```

`.repo/local_manifests/lapis.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="lenovo-sm8650" fetch="https://github.com/lenovo-sm8650" revision="android-14.1" />

  <!-- Replaced by the forks below -->
  <remove-project name="android_bootable_recovery" />
  <remove-project name="android_hardware_interfaces" />
  <remove-project name="android_system_vold" />

  <project name="android_device_lenovo_lapis-twrp" path="device/lenovo/lapis" remote="lenovo-sm8650" revision="twrp-14.1" />
  <project name="android_bootable_recovery" path="bootable/recovery" remote="lenovo-sm8650" />
  <project name="android_hardware_interfaces" path="hardware/interfaces" remote="lenovo-sm8650" />
  <project name="android_system_vold" path="system/vold" remote="lenovo-sm8650" />
</manifest>
```

### 3. Build

```bash
cd ~/twrp
source build/envsetup.sh
lunch twrp_lapis-ap2a-eng
mka recoveryimage
```

On an incremental build, remove `out/target/product/lapis/recovery` first: TWRP
copies libraries into the recovery ramdisk only when that directory is
created, so it would otherwise ship stale copies.

### 4. Sign

```bash
python3 external/avb/avbtool.py add_hash_footer \
    --image out/target/product/lapis/recovery.img \
    --partition_name recovery --partition_size 104857600 \
    --algorithm SHA256_RSA4096 \
    --key external/avb/test/data/testkey_rsa4096.pem \
    --rollback_index 1 \
    --prop com.android.build.recovery.fingerprint:Lenovo/TB520FU/TB520FU:14/UKQ1.240826.001/ZUI_17.5.10.362_260719_ROW:user/release-keys
```

## Source changes

twrp-14.1 does not build with `TW_INCLUDE_CRYPTO` on Android 14 as-is, and
this device needs a few runtime fixes. They are commits in the
[lenovo-sm8650](https://github.com/lenovo-sm8650) forks (`android-14.1`), which
the local manifest above puts in place of the TeamWin projects:

| Fork | Changes |
|---|---|
| `android_bootable_recovery` | Android 14 AIDL module names (gerrit 8742), libtar compile-time fscrypt policy (gerrit 7723), no legacy FDE calls (gerrit 8744), static libvold link deps; atomic split-plane DRM backend for the 2944 px panel (from polygraphene's TB322FC tree); metadata decryption `zoned_device` argument; theme reload after Restore Defaults; removable storage size updates and uevent driven USB OTG / microSD hotplug; landscape A/B "Wipe Dalvik" button; AIDL GateKeeper |
| `android_system_vold` | AIDL GateKeeper (HIDL fallback) so PIN / password / pattern decryption works (TWRP-Test twrp-16.0) |
| `android_hardware_interfaces` | fastboot HAL VINTF fragment as `framework`: a `device` fragment made servicemanager drop the framework manifest, so keystore2 never registered |

## Signing

Stock TB520FU firmware is signed with Lenovo's own AVB key. This recovery is
signed with the public AOSP `testkey_rsa4096` (sha1 `2597c218…`), using the
same footer layout as the stock recovery: `SHA256_RSA4096`, rollback index 1,
partition size 104857600, recovery fingerprint property.

- **Locked bootloader:** the installed `vbmeta` must chain `recovery`
  (rollback index location 1) to `testkey_rsa4096`, e.g. a testkey-resigned
  firmware. Otherwise the device will not boot this image.
- **Unlocked bootloader:** boots with any vbmeta (orange state).


## Installation

Back up your current `recovery_a` / `recovery_b` first.

- fastboot (unlocked):
  ```bash
  fastboot flash recovery_a TWRP-3.7.1_14-lapis-<date>-landscape.img
  fastboot flash recovery_b TWRP-3.7.1_14-lapis-<date>-landscape.img
  ```
- EDL: flash `recovery_a` / `recovery_b` (LUN 4) with your EDL tool of choice.

Boot it with `adb reboot recovery`.

## Updating the vendor blobs

`recovery/root/vendor` holds the QTEE / keymint / gatekeeper blobs, their init
rc and VINTF files, and the touch firmware, taken from ZUI 17.5.10.362. For
another firmware version, copy the same files from the stock `vendor`,
`vendor_dlkm` and `odm` images.

## Credits

- [TeamWin](https://github.com/TeamWin) and [minimal-manifest-twrp](https://github.com/minimal-manifest-twrp)
- [polygraphene](https://github.com/polygraphene): TB321FU / TB322FC device
  trees, which this tree is based on, and the minuitwrp DRM backend
- TWRP gerrit changes 7723, 8742, 8744
- TWRP-Test twrp-16.0 (AIDL GateKeeper)
