# OrangeFox Recovery device tree for Samsung Galaxy A35 5G (SM-A356E, a35x)

OrangeFox R12.0 (`fox_12.1`) for the Exynos 1380 Galaxy A35 5G.
Maintainer: obviouslyvoid

Based on the TeamWin TWRP tree
[android_device_samsung_a35x](https://github.com/TeamWin/android_device_samsung_a35x).

## Status

Tested on SM-A356E with LineageOS 24 (Android 17):

- Boots, display, touch, ADB, MTP (after data is decrypted)
- Data decryption (FBE + metadata encryption, wrapped keys) with the lockscreen PIN
- Settings saved in `/sdcard/Fox`; OrangeFox recovery password works before data is decrypted
- Flashlight (Power + Volume Up), screenshots (Power + Volume Down, saved to `/sdcard/Fox/screenshots`)
- Normal charging speed in recovery
- Power off from recovery, then power on, boots Android (not recovery)

Not tested yet: backup/restore, zip installs/OTA, decryption on One UI.

## How to build

1. Sync OrangeFox `fox_12.1` ([OrangeFox sync](https://gitlab.com/OrangeFox/sync)):

   ```sh
   git clone https://gitlab.com/OrangeFox/sync.git ~/OrangeFox_sync
   cd ~/OrangeFox_sync
   ./orangefox_sync.sh --branch 12.1 --path ~/fox_12.1
   ```

2. Clone this tree and apply the required source patches:

   ```sh
   cd ~/fox_12.1
   git clone https://github.com/obviouslyvoid/ofrp_device_samsung_a35x -b fox_12.1 device/samsung/a35x
   bash device/samsung/a35x/patches/apply.sh
   ```

   The patches (OrangeFox recovery, vold, keystore2, libvintf) are needed for
   data decryption and the other fixes; see [patches/README.md](patches/README.md).

3. Build:

   ```sh
   export FOX_BUILD_DEVICE=a35x
   source build/envsetup.sh
   lunch twrp_a35x-eng
   mka recoveryimage
   ```

Output in `out/target/product/a35x/`:
`OrangeFox-R12.0-Unofficial-a35x.img`, `.img.tar` (Odin, contains `recovery.img`) and `.zip`.

## Device-specific notes

- `vendorsetup.sh` holds all OrangeFox build variables.
- `recovery/root/system/bin/a35x-crypto-prepare.sh` and `init.a35x.crypto.rc`
  start the Samsung TEE, KeyMint, Gatekeeper and Weaver (hermesd) services
  from the real `/vendor` for decryption.
- `a35-normal-boot` (source in `tools/a35-normal-boot/`) clears Samsung's saved
  recovery boot selection (PARAM `REBOOT_MODE` 4 -> 0) at recovery start, so a
  cold power-on after "Power off" boots Android.
- `mkbootimg/` keeps the recovery's embedded AVB block that the bootloader
  accepts on this device.

## Kernel

Prebuilt kernel `5.15.153-physwizz` by [Physwizz](https://github.com/physwizz)
(`prebuilt/Image`, `dtb.img`, `dtbo.img`). Kernel source: see Physwizz's
A35 kernel repository.

## Credits

- [TeamWin](https://github.com/TeamWin) and SavedByLight - original TWRP device tree
- [OrangeFox Recovery](https://gitlab.com/OrangeFox) team
- [Physwizz](https://github.com/physwizz) - kernel
- [Ravindu644](https://github.com/ravindu644) - permissive kernel
- [111hav0c](https://github.com/111hav0c), [drnightshadow](https://github.com/drnightshadow) - testing of the original tree
