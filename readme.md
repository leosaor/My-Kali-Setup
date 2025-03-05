- Check if AMD-V (SVM Mode) or VT-x (AMD or Intel virtualization) is enabled in the BIOS
- Download and install [VMware](https://support.broadcom.com/group/ecx/free-downloads) or [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- Download [KaliLinux](https://www.kali.org/get-kali/#kali-virtual-machines). You can download the Installer Image, but i prefer a pre-built image. If you will use the pre-built image, you will need download and install [7Zip](https://www.7-zip.org/)
- Extract the Kali .7z image and open the VMware and import the Virtual Machine, click on "Upgrade this virtual machine" and select Workstation 17.x
- Edit virtual machine settings, in my case i have 32gb of memory and my processor is a Ryzen 9 5900x, in VM Settings i set 8gb of memory and 1 on number of processors and 8 on number of cores per processor.
- Add the Shared Folders
- Power on the virtual machine
- Clone this repository and execute config.sh
- Create Snapshot