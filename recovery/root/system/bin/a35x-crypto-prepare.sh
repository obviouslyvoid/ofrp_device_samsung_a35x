#!/system/bin/sh
# Only mount existing filesystems. Never format, repair, or generate keys.
[ "$(getprop a35x.crypto.ready)" = 1 ] && exit 0
fail() { echo "a35x crypto: $*"; setprop a35x.crypto.error "$*"; exit 1; }
mounted() { awk -v p="$1" '$2 == p { found=1 } END { exit !found }' /proc/mounts; }
mount_ro() {
    mounted "$2" && return 0
    [ -L "$2" ] && rm "$2"
    mkdir -p "$2"
    mount -t erofs -o ro "$1" "$2" || fail "Cannot mount $2"
}
mount_ro /dev/block/mapper/vendor /vendor
mount_ro /dev/block/mapper/odm /odm
mkdir -p /mnt/vendor/efs
mounted /mnt/vendor/efs || mount -t ext4 -o ro,noload /dev/block/by-name/efs /mnt/vendor/efs || fail "Cannot mount EFS read-only"
# Security properties must describe the installed ROM, not the recovery build.
mkdir -p /tmp/a35x-system
mount_ro /dev/block/mapper/system /tmp/a35x-system
prop() { sed -n "s/^$1=//p" "$2" | head -n 1; }
sp=/tmp/a35x-system/system/build.prop
[ -f "$sp" ] || sp=/tmp/a35x-system/build.prop
vp=/vendor/build.prop
for key in ro.build.version.release ro.build.version.sdk ro.build.version.security_patch; do
    value=$(prop "$key" "$sp")
    [ -n "$value" ] || fail "Missing ROM security property"
    /sbin/resetprop -n "$key" "$value" || fail "Cannot set ROM security property"
done
for key in ro.vendor.build.security_patch ro.vendor.build.version.sdk; do
    value=$(prop "$key" "$vp")
    [ -z "$value" ] || /sbin/resetprop -n "$key" "$value"
done
/sbin/resetprop -n ro.product.first_api_level 34
/sbin/resetprop -n ro.crypto.dm_default_key.options_format.version 2
setprop ctl.start servicemanager
setprop ctl.start a35x-tzdaemon
n=0
until [ "$(getprop vendor.tzdaemon)" = Ready ]; do
    n=$((n+1)); [ "$n" -lt 20 ] || fail "TrustZone did not become ready"
    sleep 1
done
[ ! -e /proc/iccc_ready ] || echo 1 > /proc/iccc_ready
setprop ctl.start a35x-tzts
setprop ctl.start a35x-keymint
setprop ctl.start a35x-gatekeeper
n=0
until service check android.hardware.security.keymint.IKeyMintDevice/default 2>/dev/null | grep -q ': found'; do
    n=$((n+1)); [ "$n" -lt 20 ] || fail "KeyMint did not register"
    sleep 1
done
setprop a35x.crypto.ready 1
n=0
until service check android.system.keystore2.IKeystoreService/default 2>/dev/null | grep -q ': found'; do
    n=$((n+1)); [ "$n" -lt 20 ] || fail "Keystore did not register"
    sleep 1
done
# Weaver's backing directory becomes accessible after DE keys are installed.
(
    n=0
    until [ -d /data/system_de/0/spblob ]; do
        n=$((n+1))
        [ "$n" -lt 90 ] || { echo 'Weaver: DE storage did not unlock'; exit 1; }
        sleep 1
    done
    setprop ctl.start a35x-hermes
) >> /tmp/a35x-hermes-start.log 2>&1 &
echo 'a35x crypto: security services ready; starting existing-data unlock'
exit 0
