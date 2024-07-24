#!/usr/bin/env bash

echo "Please enter Boot partition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter Root(/) paritition: (example /dev/sda3)"
read ROOT  

echo "Please enter your Username"
read USER 

echo "Please enter your PC-Name"
read NAME 

echo "Please enter your Password"
read PASSWORD 

echo "Please enter your Hostname"
read HOSTNAME


#while true; do
    #echo "Choose Bootloader"
    #echo "1. Systemdboot"
    #echo "2. GRUB"
    #read BOOT

    ## Check if input is either 1 or 2
    #if [[ $BOOT == 1 || $BOOT == 2 ]]; then
        #break
    #else
        #echo "Invalid input. Please enter either 1 or 2."
    #fi
#done

# make filesystems
echo -e "\nCreating Filesystems...\n"

existing_fs=$(blkid -s TYPE -o value "$EFI")

mkfs.fat -F32 "$EFI"

mkfs.ext4 "${ROOT}"

# mount target
mount "${ROOT}" /mnt
mkdir /mnt/boot
mount "$EFI" /mnt/boot

echo "--------------------------------------"
echo "-- INSTALLING Base Arch Linux --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware linux-headers networkmanager wireless_tools nano intel-ucode bluez bluez-utils git --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

cat <<REALEND > /mnt/next.sh
useradd -m -G wheel -s /bin/bash $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

echo "$HOSTNAME" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	archlinux.localdomain	archlinux
EOF

echo "-------------------------------------------------"
echo "Audio Drivers"
echo "-------------------------------------------------"

pacman -S mesa-utils pipewire pipewire-alsa pipewire-pulse --noconfirm --needed

systemctl enable NetworkManager bluetooth
systemctl --user enable pipewire pipewire-pulse

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"


pacman -S grub --noconfirm --needed
grub-install --target=x86_64 --directory=/boot --bootloader-id="Linux Boot Manager"
grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND

arch-chroot /mnt sh next.sh

