#!/bin/bash

# packing tools
# git clone https://github.com/ASdev/android_img_repack_tools.git

# Refs
# make_ext4fs -l 2147483648 -a system out/target/product/redhookbay/obj/PACKAGING/systemimage_intermediates/system.img out/target/product/redhookbay/system
# simg2img system.img system.img.ext4
# img2simg system.img.ext4 system.img
# tar cv system.img.tar system.img
# md5sum -t system.img.tar >> system.img.tar
# mv system.img.tar system.img.tar.md5


TOP=`pwd`
echo $TOP

sourceimg=$TOP/binary/N7100ZCUENB1_N7100CHNENB1_N7100ZCUENB1_HOME.tar.md5
working_dir=$TOP/working
tools_dir=$TOP/tools
app_dir=$TOP/app
gapp_name=$TOP/app/gapp/gapps-jb-20130813-signed.zip

unzip_img()
{
mkdir -p $working_dir
tar xfv $sourceimg -C $working_dir
}

prepare_working_fs()
{
cd $working_dir &&  $tools_dir/simg2img system.img system.img.ext4 && cd $TOP
sudo mkdir -p /mnt/img/
echo "sudo mount -o loop $working_dir/system.img.ext4 /mnt/img"
sudo mount -o loop $working_dir/system.img.ext4 /mnt/img
}
remove_bloatware()
{
  for i in `cat bloatapp.list` ; do sudo rm -fv /mnt/img/app/$i; done
}

add_gapps()
{
  cd $app_dir/gapp/ && unzip $gapp_name && rm -f system/addon.d/70-gapps.sh && sudo cp -rf system/* /mnt/img/ && cd $TOP 
}

repack()
{
	sudo umount /mnt/img

	cd $TOP/working

	echo " ../tools/img2simg system.img.ext4 system.img"
	../tools/img2simg system.img.ext4 system.img

	echo "create system.img.tar.md5"

	tar cfv system.img.tar system.img
	md5sum -t system.img.tar >> system.img.tar
	mv system.img.tar system.img.tar.md5
	cd $TOP
	echo "done"
}

clean_up()
{
	rm -f $app_dir/gapp/install-optional.sh
	rm -rf $app_dir/gapp/META-INF
	rm -rf $app_dir/gapp/optional
	rm -rf $app_dir/gapp/system
}

# function same as repack(), but more safe
create_simage_from_fs()
{
	cd $TOP/working
	sudo ../tools/make_ext4fs -l 2G -s -a system system.img /mnt/img/
	cd $TOP
	sudo umount /mnt/img
}

create_tar_md5_file()
{
	cd $TOP/working
	tar -c boot.img cache.img hidden.img modem.bin recovery.img system.img >> new.tar 
	md5sum -t new.tar >> new.tar
	mv new.tar new.tar.md5
}
unzip_img
prepare_working_fs
remove_bloatware
add_gapps
#repack
create_simage_from_fs
create_tar_md5_file
clean_up

# last step, to use odin to flash it
# ToDO: try with heimdall
