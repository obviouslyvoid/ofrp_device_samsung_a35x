#!/system/bin/sh
# Called by OrangeFox before a zip install unmounts /vendor.
# These services run from the real /vendor and keep it busy. Data stays usable:
# its encryption keys are already loaded in the kernel.
for s in a35x-hermes a35x-gatekeeper a35x-keymint a35x-tzts a35x-tzdaemon vendor.health-samsung; do
    [ "$(getprop init.svc.$s)" = running ] && setprop ctl.stop $s
done
n=0
while [ $n -lt 50 ]; do
    busy=0
    for s in a35x-hermes a35x-gatekeeper a35x-keymint a35x-tzts a35x-tzdaemon vendor.health-samsung; do
        [ "$(getprop init.svc.$s)" = running ] && busy=1
    done
    [ $busy -eq 0 ] && break
    sleep 0.1; n=$((n+1))
done
echo "I:a35x: vendor services stopped before /vendor unmount" >> /tmp/recovery.log
exit 0
