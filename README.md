# TWRP device tree for Lenovo Yoga Tab Plus (lapis)

| Codename | Device |
| -------- | ------ |
| lapis | Lenovo Yoga Tab Plus / Yoga Pad Pro (TB520FU), SM8650 |

TWRP 3.7.1 (twrp-14.1), based on ZUI 17.5.10.362 (Android 16). Landscape theme.
For the current build see the [`twrp-16.0`](https://github.com/lenovo-sm8650/android_device_lenovo_lapis-twrp/tree/twrp-16.0) branch.

## Features

- [x] Decryption (FBE + metadata, PIN / password / pattern)
- [x] ADB
- [x] MTP
- [x] USB-OTG
- [x] Display, touch, brightness
- [x] Battery / CPU temperature
- [x] AVB: signed with AOSP `testkey_rsa4096`, rollback index 1

## Build it yourself

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

  <remove-project name="android_bootable_recovery" />
  <remove-project name="android_system_vold" />

  <project name="android_device_lenovo_lapis-twrp" path="device/lenovo/lapis" remote="lenovo-sm8650" revision="twrp-14.1" />
  <project name="android_bootable_recovery" path="bootable/recovery" remote="lenovo-sm8650" />
  <project name="android_system_vold" path="system/vold" remote="lenovo-sm8650" />
</manifest>
```

The fastboot HAL VINTF fragment must be a `framework` fragment, otherwise
servicemanager drops the framework manifest and keystore2 never registers:

```bash
sed -i 's/type="device"/type="framework"/' \
    hardware/interfaces/fastboot/aidl/default/android.hardware.fastboot-service.example.xml
```

Build and sign:

```bash
source build/envsetup.sh
lunch twrp_lapis-ap2a-eng
mka recoveryimage

python3 external/avb/avbtool.py add_hash_footer \
    --image out/target/product/lapis/recovery.img \
    --partition_name recovery --partition_size 104857600 \
    --algorithm SHA256_RSA4096 \
    --key external/avb/test/data/testkey_rsa4096.pem \
    --rollback_index 1 \
    --prop com.android.build.recovery.fingerprint:Lenovo/TB520FU/TB520FU:14/UKQ1.240826.001/ZUI_17.5.10.362_260719_ROW:user/release-keys
```

On an incremental build, remove `out/target/product/lapis/recovery` first.
The locked bootloader only boots it when `vbmeta` chains `recovery` to `testkey_rsa4096` (testkey-resigned firmware).

## Credits

- [TeamWin](https://github.com/TeamWin) and [minimal-manifest-twrp](https://github.com/minimal-manifest-twrp)
- [polygraphene](https://github.com/polygraphene): TB321FU / TB322FC device
  trees, which this tree is based on, and the minuitwrp DRM backend
- TWRP gerrit changes 7723, 8742, 8744
