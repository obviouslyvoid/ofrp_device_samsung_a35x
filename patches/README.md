# Source patches for a35x

These changes to OrangeFox and Android sources are required for this device
(LineageOS data decryption, flashlight, recovery password, /vendor handling).
Apply them after syncing OrangeFox `fox_12.1`, from the source root:

```sh
bash device/samsung/a35x/patches/apply.sh
```

`git am` needs a git identity (`git config --global user.name` / `user.email`).

| Folder | Project | Base commit | What it changes |
|---|---|---|---|
| `bootable_recovery` | `bootable/recovery` (OrangeFox) | `6bd902d14f754ab98a7cccc5598f7b9d135cfc38` | Starts decryption only after Samsung security services are ready; flashlight accepts a single sysfs file; `OF_PASSWORD_BACKUP_PARTITION`; `OF_KEEP_VENDOR_MOUNTED` |
| `system_vold` | `system/vold` | `a164ba05c5fef288059774a776b2e6e1119957cf` | Creates the fscrypt keyring in recovery; checks the metadata-encrypted mount |
| `system_security` | `system/security` (keystore2) | `14737db1429b8eebc15568bc748b2cd79ccad5c2` | Never upgrades (rewrites) the ROM's key blobs from recovery |
| `system_libvintf` | `system/libvintf` | `469bc3f8bd22fff598fc098abfcfd60df984c98b` | Accepts the device's meta-version 5 vendor manifest (KeyMint) |

If a newer OrangeFox sync moved a base commit, `git am --3way` usually still
applies; otherwise resolve the conflict or check out the listed base commit.
