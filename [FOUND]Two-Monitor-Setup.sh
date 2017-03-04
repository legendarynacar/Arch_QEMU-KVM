#!/bin/bash
if [ "${1}" = "nosleep" ]; then
	no_sleep="1"
fi

echo -n "Disabling display HDMI2..."
xrandr \
	--output HDMI1 --mode 1920x1080 --pos 0x0 --rotate normal \
	--output HDMI2 --off \
	--output VIRTUAL1 --off \
	--output VGA1 --off
[ -z "${no_sleep}" ] && sleep 2
echo "done"

echo -n "Restarting conky..."
killall conky &>/dev/null
[ -z "${no_sleep}" ] && sleep 1
(conky &>/dev/null &) &>/dev/null
[ -z "${no_sleep}" ] && sleep 1
echo "done"

echo -n "Disabling power saving..."
sudo mode performance
echo "done"

echo -n "Unloading nvidia driver..."
sudo /etc/init.d/nvidia-smi stop > /dev/null
sudo rmmod nvidia
echo "done"

echo -n "Binding GTX 770..."
for dev in "0000:01:00.0" "0000:01:00.1"; do
	vendor=$(cat /sys/bus/pci/devices/${dev}/vendor)
	device=$(cat /sys/bus/pci/devices/${dev}/device)
	if [ -e /sys/bus/pci/devices/${dev}/driver ]; then
		echo "${dev}" | sudo tee /sys/bus/pci/devices/${dev}/driver/unbind > /dev/null
		while [ -e /sys/bus/pci/devices/${dev}/driver ]; do
			sleep 0.1
		done
	fi
	echo "${vendor} ${device}" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null
done
echo "done"

# use pulseaudio
export QEMU_AUDIO_DRV=pa

echo -n "Starting virtual machine..."
[ -z "${no_sleep}" ] && sleep 0.2
sudo \
	nice -n -1 \
	qemu-system-x86_64 \
	-serial none \
	-parallel none \
	-nodefconfig \
	-nodefaults \
	-enable-kvm \
	-name Nafrayu \
	-cpu host,kvm=off,check \
	-smp threads=2,cores=4,sockets=1 \
	-m 12288 \
	-mem-path /var/lib/hugetlbfs/group/kvm/pagesize-1GB \
	-mem-prealloc \
	-soundhw hda \
	-device ich9-usb-uhci3,id=uhci  \
	-device usb-ehci,id=ehci \
	-device nec-usb-xhci,id=xhci \
	-device usb-host,vendorid=0x06a3,productid=0x0836,bus=uhci.0 `# Saitek Cyborg X` \
	-device usb-host,vendorid=0x0421,productid=0x0106,bus=ehci.0 `# Nokia N96 Flash Mode` \
	-device usb-host,vendorid=0x0421,productid=0x003a,bus=ehci.0 `# Nokia N96 PC Suite Mode` \
	-device usb-host,vendorid=0x0421,productid=0x0037,bus=ehci.0 `# Nokia N96 Mass Memory` \
	-device usb-host,vendorid=0x0421,productid=0x0038,bus=ehci.0 `# Nokia N96 Picture Tansfer` \
	-device usb-host,vendorid=0x0421,productid=0x0039,bus=ehci.0 `# Nokia N96 File Transfer` \
	-netdev type=tap,id=net0,ifname=tap0,vhost=on \
	-device virtio-net-pci,netdev=net0,mac=00:26:18:DF:54:01 \
	-k de \
	-drive if=pflash,format=raw,readonly,file=/home/bluebird/Projects/edk2/Build/OvmfX64/RELEASE_GCC48/FV/OVMF_CODE.fd \
	-drive if=pflash,format=raw,file=/var/lib/ovmf/nafrayu.fd `# /home/bluebird/Projects/edk2/Build/OvmfX64/RELEASE_GCC48/FV/OVMF_VARS.fd` \
	-rtc base=utc \
	-monitor unix:/run/Nafrayu.sock,server,nowait \
	-boot order=c \
	-object iothread,id=iothread0 \
	-drive if=none,id=drive0,file=/dev/mapper/lvm-kvm_nafrayu,format=raw,cache=none,aio=native \
	-device virtio-blk-pci,iothread=iothread0,drive=drive0 \
	-nographic \
	-device vfio-pci,host=01:00.0,addr=09.0,multifunction=on \
	-device vfio-pci,host=01:00.1,addr=09.1 \
	-daemonize
echo "done"

# for install
	#-vga std \
	#-sdl \
	#-boot order=d \
	#-device ide-cd,drive=drive-cd-disk1,id=cd-disk1,unit=0,bus=ide.0 \
	#-drive file=/home/bluebird/Downloads/WindowsTechnicalPreview-x64-EN-US.iso,if=none,id=drive-cd-disk1,media=cdrom \
	#-device ide-cd,drive=drive-cd-disk2,id=cd-disk2,unit=0,bus=ide.1 \
	#-drive file=/home/bluebird/Downloads/virtio-win-0.1-81.iso,if=none,id=drive-cd-disk2,media=cdrom \

# connect user to monitor
sudo nc.openbsd -U /run/Nafrayu.sock
echo

echo -n "Enabling power saving..."
sudo mode powersave
echo "done"

echo -n "Unbinding GTX 770..."
for dev in "0000:01:00.0" "0000:01:00.1"; do
	vendor=$(cat /sys/bus/pci/devices/${dev}/vendor)
	device=$(cat /sys/bus/pci/devices/${dev}/device)
	if [ -e /sys/bus/pci/devices/${dev}/driver ]; then
		echo "${dev}" | sudo tee /sys/bus/pci/devices/${dev}/driver/unbind > /dev/null
		while [ -e /sys/bus/pci/devices/${dev}/driver ]; do
			sleep 0.1
		done
	fi
done
echo "done"

echo -n "Loading nvidia driver..."
sudo modprobe nvidia
sudo /etc/init.d/nvidia-smi start > /dev/null
echo "done"

echo -n "Restoring display HDMI2..."
xrandr \
	--output HDMI2 --mode 1920x1080 --pos 0x0 --rotate normal \
	--output HDMI1 --mode 1920x1080 --pos 1920x0 --rotate normal \
	--output VIRTUAL1 --off \
	--output VGA1 --off
[ -z "${no_sleep}" ] && sleep 2
echo "done"

echo -n "Restarting conky..."
killall conky &>/dev/null
[ -z "${no_sleep}" ] && sleep 1
(conky &>/dev/null &) &>/dev/null
[ -z "${no_sleep}" ] && sleep 1
echo "done"
