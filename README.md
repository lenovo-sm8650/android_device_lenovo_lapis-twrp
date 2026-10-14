# TWRP device tree for Lenovo Yoga Tab Plus (lapis)

| Codename | Device |
| -------- | ------ |
| lapis | Lenovo Yoga Tab Plus / Yoga Pad Pro (TB520FU), SM8650 |

Based on ZUI 17.5.10.362 (Android 16). Landscape theme.

## Features

- [x] Boot (main screen in ~3 s)
- [x] Display, touch, brightness
- [x] Decryption (FBE + metadata, PIN)
- [x] Internal storage
- [x] ADB
- [x] Battery / CPU temperature
- [x] AVB: signed with AOSP `testkey_rsa4096`, rollback index 1
- [ ] Password / pattern decryption
- [ ] Backup / restore
- [ ] Flashing
- [ ] MTP
- [ ] Sideload
- [ ] Fastbootd
- [ ] USB-OTG

## Build it yourself

- [TWRP-Test/platform_manifest_twrp_aosp](https://github.com/TWRP-Test/platform_manifest_twrp_aosp) (`twrp-16.0`)
- `.repo/local_manifests/lapis.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="lenovo-sm8650" fetch="https://github.com/lenovo-sm8650" />

  <remove-project name="android_bootable_recovery" />

  <project name="android_device_lenovo_lapis-twrp" path="device/lenovo/lapis" remote="lenovo-sm8650" revision="twrp-16.0" />
  <project name="android_bootable_recovery" path="bootable/recovery" remote="lenovo-sm8650" revision="android-16.0" />
</manifest>
```

```bash
source build/envsetup.sh
lunch twrp_lapis-bp2a-eng
mka recoveryimage
```

The locked bootloader only boots it when `vbmeta` chains `recovery` to `testkey_rsa4096` (testkey-resigned firmware).
