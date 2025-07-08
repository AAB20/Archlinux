#!/bin/bash

# التأكد من الاتصال بالإنترنت
ping -c 3 archlinux.org || { echo "❌ فشل الاتصال بالإنترنت. تحقق من WiFi."; exit 1; }

# تهيئة القرص
echo "📦 افتح أداة تقسيم القرص الآن"
cfdisk /dev/sda

# تنسيق الأقسام
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# تركيب النظام
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# تثبيت النظام الأساسي
pacstrap /mnt base linux linux-firmware networkmanager sudo grub efibootmgr \
xorg xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter nano firefox

# إنشاء ملفات النظام
genfstab -U /mnt >> /mnt/etc/fstab

# إعداد النظام داخل chroot
arch-chroot /mnt <<EOF

# إعداد المنطقة الزمنية واللغة
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo archsurface > /etc/hostname

# كلمة مرور root
echo "root:2007" | chpasswd

# إنشاء مستخدم abdullah
useradd -m -G wheel -s /bin/bash abdullah
echo "abdullah:2007" | chpasswd

# تمكين sudo للمجموعة wheel
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# تفعيل الخدمات
systemctl enable NetworkManager
systemctl enable lightdm

# إعداد GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# إنهاء التثبيت
umount -R /mnt
echo "✅ تم التثبيت بنجاح! أعد التشغيل الآن 🎉"
