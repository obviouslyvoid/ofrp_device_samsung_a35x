#!/usr/bin/bash
# Main A35 kernel: upstream "clean" recipe + stock-looking version + Samsung hypervisor protections off
# (so KernelSU can be loaded as a module from a patched init_boot). Usage: build.sh [make targets]
set -euo pipefail
# Layout: $R/kernel = https://github.com/TheBizarreAbhishek/android_kernel_samsung_s5e8835
#         (commit ae05d00bd5c70cf806df5ab89d5fa438488bd241), $R/toolchain/clang-r450784d,
#         output in $R/out. Apply 0001-extract-cert-*.patch only if your host OpenSSL
#         has no ENGINE support (it affects a build tool, not the kernel).
R=${A35_KERNEL_ROOT:-$(pwd)}; K=$R/kernel; T=$R/toolchain
export PATH=$T/clang-r450784d/bin:$PATH
export DTC_FLAGS="-@" PLATFORM_VERSION=16 ANDROID_MAJOR_VERSION=t TARGET_SOC=s5e8835 DEPMOD=depmod
# same identity fields a stock build shows in /proc/version
export KBUILD_BUILD_USER=dpi KBUILD_BUILD_HOST=SWDK6223
cd $K
if [ ! -f .a35-patched ]; then
  patch -p1 --forward < scripts/patches/kernel/0002-bbrv3-android13-5.15.patch
  patch -p1 --forward < scripts/patches/kernel/0003-ntsync-android13-5.15.patch
  find . -name '*.rej' -delete 2>/dev/null || true
  touch .a35-patched
fi
C=arch/arm64/configs/custom.config; : > $C; cfg(){ ./scripts/config --file $C "$@"; }
# upstream defaults for every variant
cfg --enable CONFIG_SLUB_DEBUG --disable CONFIG_SCHED_AUTOGROUP --enable CONFIG_LRU_GEN_ENABLED --enable CONFIG_ZSMALLOC --enable CONFIG_ZRAM --enable CONFIG_ZRAM_MULTI_COMP
cfg --disable CONFIG_CPU_FREQ_GOV_ENERGYAWARE --enable CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
cfg --enable CONFIG_TCP_CONG_BBR3 --enable CONFIG_DEFAULT_BBR3 --set-str CONFIG_DEFAULT_TCP_CONG bbr3 --enable CONFIG_NET_SCH_DEFAULT --enable CONFIG_DEFAULT_FQ --set-str CONFIG_DEFAULT_NET_SCH fq
cfg --enable CONFIG_TMPFS_XATTR --enable CONFIG_BBG
# stock-looking release string: 5.15.220-android13-3-33470412 (stock DZH1 is 5.15.189-android13-3-33470412)
cfg --disable CONFIG_LOCALVERSION_AUTO --set-str CONFIG_LOCALVERSION "-android13-3-33470412"
# Samsung hypervisor protections (uH: RKP write-protects kernel text/data, KDP makes credentials read-only);
# they block a root module from changing credentials. DEFEX/PROCA/FIVE/DSMS are already off upstream.
cfg --disable CONFIG_UH --disable CONFIG_RKP --disable CONFIG_KDP --disable CONFIG_KDP_CRED --disable CONFIG_KDP_NS --disable CONFIG_HDM
cfg --disable CONFIG_MODULE_SIG_FORCE --enable CONFIG_KPROBES --enable CONFIG_KALLSYMS_ALL
# The build host's OpenSSL rejects SHA-1 signatures; sign in-tree modules with SHA-512 instead.
cfg --disable CONFIG_MODULE_SIG_SHA1 --enable CONFIG_MODULE_SIG_SHA512 --set-str CONFIG_MODULE_SIG_HASH sha512
MP="-j6 ARCH=arm64 KBUILD_OUTPUT=$R/out CC=clang LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- LOCALVERSION="
make $MP bizarre_defconfig custom.config
t0=$(date +%s)
make $MP "$@"
make $MP dtbs
echo "BUILD_OK $(( $(date +%s)-t0 ))s"; ls -la $R/out/arch/arm64/boot/Image
strings $R/out/arch/arm64/boot/Image | grep -m1 "Linux version"
