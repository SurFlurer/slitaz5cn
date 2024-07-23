#!/bin/bash

SOURCES_MIRRORS_FILE="packages/mirrors.list"
MIRRORS_SPEED_FILE="/tmp/mirrors_speed.list"
function get_ping_speed()
{
local speed=`ping -W1 -c1 $1 2> /dev/null | grep "^r" |  cut -d '/' -f5`
echo $speed
}
function test_mirror_speed()
{
    rm $MIRRORS_SPEED_FILE 2> /dev/null; touch $MIRRORS_SPEED_FILE
     cat $SOURCES_MIRRORS_FILE | while read mirror
    do
        if [ "$mirror" != "" ]; then
            echo -e "正在ping $mirror 检测中"
            local mirror_host=`echo $mirror | cut -d '/' -f3`    #change mirror_url to host
            local speed=$(get_ping_speed $mirror_host)
            if [ "$speed" != "" ]; then
                echo "测速时间是 $speed"
                echo "$mirror $speed" >> $MIRRORS_SPEED_FILE
            else
                echo "链接失败."
            fi
        fi
    done
}
function get_fast_mirror()
{
    sort -k 2 -n -o $MIRRORS_SPEED_FILE $MIRRORS_SPEED_FILE
    local fast_mirror=`head -n 1 $MIRRORS_SPEED_FILE | cut -d ' ' -f1`
    echo $fast_mirror
}
#test -f $SOURCES_MIRRORS_FILE
#  if [ "$?" != "0" ]; then  
#    echo -e "$SOURCES_MIRRORS_FILE 不存在.\n"; exit 2
#  else
#    test_mirror_speed
#    fast_mirror=$(get_fast_mirror)
#  if [ "$fast_mirror" == "" ]; then
#    echo -e "无法找到连通的网站数据源，请检查你的列表 $SOURCES_MIRRORS_FILE\n"
#    exit 0
#  fi
#  fi
#echo $fast_mirror
[ ! -e slitaz-rolling-core64.iso ] && wget http://www.gtlib.gatech.edu/pub/slitaz/iso/rolling/slitaz-rolling-core64.iso
mkdir iso-old
[ ! -d iso-old/boot ] && 7z x slitaz-rolling-core64.iso -y -r -o./iso-old
#[ ! -e packages/linux64-3.16.55.tazpkg ] && wget -O ./packages/linux64-3.16.55.tazpkg https://slitaz.cn/dl/slitaz/linux64-3.16.55.tazpkg
#[ ! -e packages/teasiu-5.0.tazpkg ] && wget -O ./packages/teasiu-5.0.tazpkg https://slitaz.cn/dl/slitaz/teasiu-5.0.tazpkg
#[ ! -e packages/updatetime.txt ] && wget -O ./packages/updatetime.txt https://slitaz.cn/dl/slitaz/iso/rolling/slitaz-rolling-core64-chinese-updatetime.txt
docker build -t newrootfs -f ./dockerfile-rootfs64 .
docker run --name myrootfs newrootfs
#rm -f ./iso-old/EFI/esp.img
#rm -f ./iso-old/EFI/boot/rootfs.gz
rm -f ./iso-old/boot/rootfs.gz
rm -rf ./iso-old/EFI/
docker cp myrootfs:/tmp/rootfs-new.gz ./iso-old/boot/rootfs.gz
#docker cp myrootfs:/tmp/rootfs-new.gz ./iso-old/EFI/boot/rootfs.gz
#echo "###############"
#ls ./iso-old/
#echo "###############"
#ls ./iso-old/boot/
#echo "###############"
#ls ./iso-old/EFI/boot/
#echo "###############"
docker stop myrootfs
docker rm myrootfs
docker rmi newrootfs
mkisofs -r -T -J -V "Slitaz_ISO" -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
	-boot-info-table -v -o slitaz5.0-rolling-core64-cn.iso ./iso-old/
