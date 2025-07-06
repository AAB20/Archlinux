#!/bin/bash
set -e

echo "🚀 بدء تثبيت Arch Linux على Surface Pro 3 (بدون لمس + KDE GUI)"

# 1. تفعيل التوقيت التلقائي
timedatectl set-ntp true

# 2. تقسيم القرص
echo "🧹 تقسيم القرص /dev/sda..."
parted /dev/sda --script mklabel gpt
parted /dev/sda --script mkpart ESP fat32 1MiB 513MiB
parted /dev/sda --script set 1 boot on
parted /dev/sda --script mkpart primary ext4 513MiB 100%

# 3. تهيئة الأقسام
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

# 4. تركيب النظام
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# 5. تثبيت النظام الأساسي + KDE + أدوات الشبكة
echo "📦 تثبيت الحزم الأساسية وواجهة KDE..."
pacstrap /mnt base linux linux-firmware sudo nano networkmanager grub efibootmgr \
  xorg plasma kde-applications sddm konsole dolphin

# 6. توليد fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 7. إعداد النظام داخل chroot
arch-chroot /mnt /bin/bash <<EOF

# المنطقة الزمنية
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# اللغة
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# اسم الجهاز
echo "arch-surface" > /etc/hostname
cat >> /etc/hosts <<EOT
127.0.0.1 localhost
::1       localhost
127.0.1.1 arch-surface.localdomain arch-surface
EOT

# كلمة مرور المستخدم root
echo "🔐 أدخل كلمة مرور root:"
passwd

# إنشاء مستخدم عادي
useradd -m -G wheel -s /bin/bash abdullah
echo "🔐 أدخل كلمة مرور للمستخدم abdullah:"
passwd abdullah

# تفعيل sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# تفعيل الخدمات
systemctl enable NetworkManager
systemctl enable sddm

# تثبيت GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "✅ تم التثبيت بنجاح! يمكنك الآن إعادة التشغيل:"
echo "👉 اكتب الأمر التالي:"
echo "reboot"
