#!/bin/bash

hostname="suchilBOX"
root_password='suchilin'
echo "Zapping disk"
sgdisk --zap-all /dev/sda
echo "partitioning"
parted /dev/sda --script mklabel GPT  \
	mkpart primary ext4 0  97%\
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

yes '' | pacstrap -i /mnt base base-devel grub networkmanager netctl wpa_supplicant dialog

genfstab -U -p /mnt >> /mnt/etc/fstab

################################################################################
#### Configure base system                                                  ####
################################################################################
arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
ln -s /usr/share/zoneinfo/America/Mexico_City /etc/localtime
echo "Setting hostname"
echo $hostname > /etc/hostname
sed -i '/localhost/s/$'"/ $hostname/" /etc/hosts
echo "Installing wifi packages"
pacman --noconfirm -S iw wpa_supplicant dialog wpa_actiond
echo "Generating initramfs"
sed -i "s/^HOOKS.*/HOOKS=\"base udev autodetect modconf block keyboard ${encrypt_mkinitcpio_hook}lvm2 filesystems fsck\"/" /etc/mkinitcpio.conf
mkinitcpio -p linux
echo "Setting root password"
echo "root:${root_password}" | chpasswd
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
