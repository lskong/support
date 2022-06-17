# remastersys 封装制作系统iso


## 环境准备

http://www.pcds.fi/downloads/applications/system/backup/remastersys/debian/remastersys_3.0.0-1_all.deb
http://www.pcds.fi/downloads/applications/system/backup/remastersys/debian/remastersys-gui_3.0.0-1_all.deb


apt-get install syslinux-utils isolinux squashfs-tools casper libdebian-installer4 ubiquity-frontend-debconf user-setup discover
apt-get install dialog libvte-common libvte9 plymouth-x11
apt-get install syslinux xorriso live-boot live-config hwdata
apt-get install open-infrastructure-system-config
dpkg -i remastersys_3.0.0-1_all.deb remastersys-gui_3.0.0-1_all.deb

apt --fix-broken install