#!/bin/bash

#path
wd=$(pwd)
out=$wd"/out"
KERNEL_DIR=$wd
ANYKERNEL_DIR="/home/shadowelite/android_lab/AnyKernel3"
IMG=$out"/arch/arm64/boot/Image.gz-dtb"
DATE="`date +%d_%m_%Y_%a_%I-%M-%S-%P`" 
grp_chat_id=""
chat_id="872750064"
token=$(echo "MTI1NTcyNDg1MjpBQUVoTy16NjFyWmpfSGJNdENESnJmSFUyOUVvTVJub3dWZwo=" | base64 -d)
TC=aarch64-linux-gnu-gcc

#exports
PATH="/home/shadowelite/toolchains/android_prebuilts_clang_host_linux-x86_clang-5484270/bin:/home/shadowelite/toolchains/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/bin:/home/shadowelite/toolchains/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9/bin:/home/shadowelite/toolchains/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-gnu-6.4.1/bin:${PATH}"

export ARCH=arm64 && export SUBARCH=arm64

function build()
{
clear
tg_inform
mkdir $out
make -j$(nproc --all) clean
make -j$(nproc --all) mrproper
make -j$(nproc --all) O=out CC=clang ARCH=arm64 clean 
make -j$(nproc --all) O=out CC=clang ARCH=arm64 mrproper
make -j$(nproc --all) O=out CC=clang ARCH=arm64 RMX2185_defconfig 
#make -j$(nproc --all) O=out CC=clang ARCH=arm64 RMX2185-stock_defconfig
#cp ../.config out/.config
tg_menu
make -j$(nproc --all) O=out CC=clang ARCH=arm64 menuconfig
tg_started
clear

##start
toilet -f future --filter border:metal BUILD START | lolcat
BUILD_START=$(date +"%s")
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
		      ARCH_MTK_PLATFORM=mt8173 \
		      SHELL=/bin/bash \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1 | tee $out/build.log



BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

if [ -f "${IMG}" ]; then
        echo -e "Build completed in $(($DIFF / 60)) minutse(s) and $(($DIFF % 60)) second(s)."
        flash_zip

else
        tg_push_error
        echo "Build failed, please fix the errors first ! "
fi
#end 
toilet -f future --filter border:metal BUILD END | lolcat

echo "==========================================================="

echo "build log is here : $(curl -s -F "file=@$out/build.log" 0x0.st) "

echo "==========================================================="
}

#functions
function flash_zip()
{
    echo -e "Now making a flashable zip of kernel with AnyKernel3"

    tg_ziping

    export ZIPNAME=ShadowElite-Nethunter-RM2185-$DATE.zip

    # Checkout anykernel3 dir
    cd "$ANYKERNEL_DIR"

    # Cleanup and copy Image.gz-dtb to dir.
    rm -f ShadowElite-*.zip
    rm -f Image.gz-dtb

    #copy modules
    #cp -r $out/modules_out/* $ANYKERNEL_DIR/modules/

    # Copy Image.gz-dtb to dir.
    cp $out/arch/arm64/boot/Image.gz-dtb ${ANYKERNEL_DIR}/
    #rm $ANYKERNEL_DIR/modules/lib/modules/*/source
    #rm $ANYKERNEL_DIR/modules/lib/modules/*/build

    # Build a flashable zip
    zip -r9 $ZIPNAME * -x .git README.md
    MD5=$(md5sum ShadowElite-*.zip | cut -d' ' -f1)
    tg_sending
    tg_push_log
    tg_push
   # rm -rf $out
}

function tg_menu()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Making menuconfig ... .</b>"
}

function tg_started()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> 🔨 Build Started .....</b>"
}

function tg_inform()
{
        curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>⚒️ New CI build has been triggered"'!'" ⚒️</b>%0A%0A<b>Linux Version • </b><code>$(make kernelversion)</code>%0A<b>Compiler • </b><code>$(${TC} --version --version | head -n 1)</code>%0A<b>At • </b><code>$(TZ=Asia/Kolkata date)</code>%0A"  
}

function tg_push()
{
    ZIP="${ANYKERNEL_DIR}"/$(echo ShadowElite-*.zip)
    curl -F document=@"${ZIP}" "https://api.telegram.org/bot${token}/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | <b>MD5 checksum</b> • <code>${MD5}</code>"
}

function tg_push_error()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>❌ Build failed after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s).</b>"
}

function tg_push_log()
{
    LOG=$out/build.log
    LOG_LINK=$(curl -s -F "file=@$LOG" 0x0.st)
  curl -F document=@"${LOG}" "https://api.telegram.org/bot$token/sendDocument" \
      -F chat_id="$chat_id" \
      -F "disable_web_page_preview=true" \
      -F "parse_mode=html" \
            -F caption="🛠️ Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). @shadowelite"
}

function tg_ziping()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b> Building flashable zip ....</b>"
}

function tg_sending()
{
  curl -s -X POST https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id -d "disable_web_page_preview=true" -d "parse_mode=html&text=<b>Sending flashable zip wait ...</b>"
}

#start build function
build
