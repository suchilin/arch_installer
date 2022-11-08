#!/bin/bash

hostname="suchilBOX"
root_password='suchilin'
suchil_password='normita'
echo "Zapping disk"
sgdisk --zap-all /dev/sda
echo "partitioning"
parted /dev/sda --script mklabel msdos  \
	mkpart primary ext4 2048s  97%\
	mkpart primary ext2 97% 100%

blockdev --rereadpt /dev/sda

echo "Creating file systems"
yes | mkswap -f /dev/sda2
yes | mkfs.xfs -f /dev/sda1

################################################################################
#### Install Arch                                                           ####
################################################################################
swapon /dev/sda2
mount /dev/sda1 /mnt
mkdir /mnt/{boot,home}

yes '' | pacstrap /mnt base base-devel grub os-prober ntfs-3g networkmanager gvfs gvfs-afc gvfs-mtp xdg-user-dirs linux linux-firmware nano dhcpcd

genfstab -U -p /mnt >> /mnt/etc/fstab

################################################################################
#### Configure base system                                                  ####
################################################################################
arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "es_MX.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=es_MX.UTF-8
echo "LANG=es_MX.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime
echo "Setting hostname"
echo $hostname > /etc/hostname
sed -i '/localhost/s/$'"/ $hostname/" /etc/hosts
echo "Installing wifi packages"
pacman --noconfirm -S iw xorg-xinit xorg git
echo "Generating initramfs"
mkinitcpio -p linux
echo "Setting root password"
echo "root:${root_password}" | chpasswd
mkdir src
cd src
git clone git://git.suckless.org/st
cd st
make clean install
cd ..
git clone git://git.suckless.org/dmenu
cd dmenu
make clean install
cd ..
git clone git://git.suckless.org/dwm
cd dwm
make clean install
cd ../../
rm -rf src
useradd -m -g users -G audio,lp,optical,storage,video,wheel,games,power,scanner -s /bin/bash suchil
echo "suchil:${suchil_password}" | chpasswd
echo "exec dwm" >> /home/suchil/.xinitrc
EOF

################################################################################
#### Install boot loader                                                    ####
################################################################################
arch-chroot /mnt /bin/bash <<EOF
    echo "Installing Grub boot loader"
    grub-install /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
EOF

################################################################################
#### The end                                                                ####
################################################################################
printf "The script has completed bootstrapping Arch Linux.\n\nTake a minute to scroll up and check for errors (using shift+pgup).\nIf it looks good you can reboot.\n"
