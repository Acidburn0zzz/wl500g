#
#
# Copyright (C) 2004 by Oleg I. Vdovikin <oleg@cs.msu.su>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

export ROOT := $(shell (cd .. && pwd -P))
export TOP := $(ROOT)/gateway

export KERNEL_DIR := $(ROOT)/linux/linux-2.6
KERNEL=kernel-2.6
BRCM-SRC=brcm-src-2.6
IPTABLES=iptables-2.6

BUSYBOX=busybox-1.22.1
P910ND=p910nd-0.97
SAMBA=samba-2.0.10
UCDSNMP=ucd-snmp-3.6.2
MINIUPNPD=miniupnpd-1.9.20141128
PPP=ppp-2.4.7
RP-PPPOE=rp-pppoe-3.11
ACCEL-PPTP=accel-pptp-git-20100829
ACCEL-PPP=accel-ppp-git-20140916
LZMA=lzma922
LZMA4XX=lzma457
SQUASHFS=squashfs4.2
NFSUTILS=nfs-utils-1.1.6
RADVD=radvd-1.8.3
ODHCP6C=odhcp6c-git-20140814
QUAGGA=quagga-0.99.20.1
L2TP=rp-l2tp
LIBUSB10=libusb-1.0.8
USBMODESWITCH=usb-modeswitch-2.2.0
MADWIMAX=madwimax-0.1.1
LLTD=LLTD-PortingKit
TCPDUMP=tcpdump-4.2.1
LIBPCAP=libpcap-1.2.1
UDEV=udev-113
SYSFSUTILS=sysfsutils-2.1.0
WPA_SUPPLICANT=wpa_supplicant-0.6.10
INFOSRV=infosrv

UCLIBC=uClibc-0.9.32

# tar has --exclude parameter ?
export TAR_EXCL_VCS := $(shell tar --exclude-vcs -cf - Makefile >/dev/null 2>&1 && echo "--exclude-vcs")

export PATCHER := $(shell pwd)/patch.sh

define patches_list
    $(shell ls -1 $(1)/$(2)[0-9][0-9][0-9]-*.patch 2>/dev/null)
endef

DIFF := LC_ALL=C TZ=UTC0 diff

define make_diff
    (cd $(ROOT) && $(DIFF) $(1) -x'*.o' -x'*.orig' $(2)/$(4) $(3)/$(4) | grep -v "^Files .* differ$$" | grep -v ^Binary.*differ$$) > $(4).diff
    diffstat $(4).diff
endef

all: prep custom
	@true

custom:	$(TOP)/.config loader busybox dropbear dnsmasq p910nd samba \
	iproute2 iptables ipset odhcp6c \
	ppp rp-l2tp rp-pppoe accel-pptp accel-ppp \
	nfs-utils portmap radvd quagga ucd-snmp igmpproxy vsftpd udpxy \
	bpalogin bridge inadyn httpd libjpeg lib LPRng \
	misc netconf nvram others rc mjpg-streamer udev \
	scsi-idle libusb usb_modeswitch wimax uqmi lltd tcpdump ntfs-3g \
	shared miniupnpd utils wlconf www libbcmcrypto asustrx cdma \
	sysfsutils e2fsprogs wpa_supplicant lanauth authcli infosrv
	@echo
	@echo Sources prepared for compilation
	@echo

$(TOP):
	@mkdir -p $(TOP)

$(TOP)/Makefile: gateway/Makefile
	cp -p $^ $@

prep: $(TOP) $(TOP)/Makefile
	-@echo "$$(( $(shell git rev-list --all --count origin/HEAD) + 1000 ))$(if $(shell git status -s -uno),M,)" > $(TOP)/.svnrev

$(TOP)/config:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - config | tar -C $(TOP) -xf -

config: $(TOP)/config
	@true

$(TOP)/.config: config shared
	$(MAKE) -C $(KERNEL) version
	$(MAKE) -C $(TOP) .config

lzma4xx_Patches := $(call patches_list,lzma,457-)

$(ROOT)/lzma4xx: lzma/$(LZMA4XX).tbz2
	@rm -rf $@ && mkdir -p $@
	tar -C $@ -xjf $<
	$(PATCHER) -Z $@ $(lzma4xx_Patches)

lzma_Patches := $(call patches_list,lzma,922-)

$(ROOT)/lzma: lzma/$(LZMA).tar.bz2
	@rm -rf $@ && mkdir -p $@
	tar -C $@ -xjf $<
	$(PATCHER) -Z $@ $(lzma_Patches)

lzma: $(ROOT)/lzma4xx $(ROOT)/lzma
	@true

squashfs_Patches := $(call patches_list,squashfs)

$(TOP)/squashfs: squashfs/$(SQUASHFS).tar.gz
	@rm -rf $(TOP)/$(SQUASHFS) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(SQUASHFS) $(squashfs_Patches)
	mv $(TOP)/$(SQUASHFS) $@

squashfs: $(TOP)/squashfs
	@true

wl:
	$(MAKE) -C $(BRCM-SRC) $@

brcm-shared:
	$(MAKE) -C $(BRCM-SRC) $@

brcm-kernel:
	$(MAKE) -C $(BRCM-SRC) $@

kernel-mrproper:
	$(MAKE) -C $(KERNEL) mrproper

kernel-patch:
	$(MAKE) -C $(KERNEL) patch

kernel-extra-drivers:
	$(MAKE) -C $(KERNEL) extra-drivers

kernel: lzma wl brcm-shared brcm-kernel kernel-extra-drivers kernel-patch
	$(MAKE) -C $(KERNEL) config

$(ROOT)/asustrx:
	@rm -rf $@
	tar -C . $(TAR_EXCL_VCS) -cf - asustrx | tar -C $(ROOT) -xf -

asustrx: $(ROOT)/asustrx
	@true

$(TOP)/loader:
	@rm -rf $@
	tar -C . $(TAR_EXCL_VCS) -cf - loader | tar -C $(TOP) -xf -
#	tar -C . $(TAR_EXCL_VCS) -cf - loader-4.65 | tar -C $(TOP) -xf - --transform=s/-4.65//

loader: $(TOP)/loader
	@true

busybox_Patches := $(call patches_list,busybox)

$(TOP)/busybox: busybox/$(BUSYBOX).tar.bz2
	@rm -rf $(TOP)/$(BUSYBOX) $@
	tar -xjf busybox/$(BUSYBOX).tar.bz2 -C $(TOP)
	rm -rf $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/fsck.c \
	    $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/chattr.c \
	    $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/lsattr.c \
	    $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/README \
	    $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/uuid \
	    $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/blkid
	mv $(TOP)/$(BUSYBOX)/e2fsprogs/old_e2fsprogs/* $(TOP)/$(BUSYBOX)/e2fsprogs/
	$(PATCHER) -Z $(TOP)/$(BUSYBOX) $(busybox_Patches)
	mkdir -p $(TOP)/$(BUSYBOX)/sysdeps/linux/
	cp -p busybox/busybox.config $(TOP)/$(BUSYBOX)/sysdeps/linux/defconfig
	chmod a+x $(TOP)/$(BUSYBOX)/testsuite/*.tests
	find $(TOP)/$(BUSYBOX)/shell/ash_test/ -name *.tests -perm 0644 -exec chmod a+x '{}' \;
	mv $(TOP)/$(BUSYBOX) $@

busybox: $(TOP)/busybox
	@true

$(TOP)/vsftpd:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - vsftpd | tar -C $(TOP) -xf -

vsftpd: $(TOP)/vsftpd
	@true

$(TOP)/ntfs-3g:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - ntfs-3g | tar -C $(TOP) -xf -

ntfs-3g: $(TOP)/ntfs-3g
	@true

$(TOP)/dropbear:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - dropbear | tar -C $(TOP) -xf -

dropbear: $(TOP)/dropbear
	@true

ucd-snmp_Patches := $(call patches_list,ucd-snmp)

$(TOP)/ucd-snmp: ucd-snmp/$(UCDSNMP).tar.gz
	@rm -rf $(TOP)/$(UCDSNMP) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(UCDSNMP) $(ucd-snmp_Patches)
	mv $(TOP)/$(UCDSNMP) $@

ucd-snmp: $(TOP)/ucd-snmp
	@true

$(TOP)/iproute2:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - iproute2 | tar -C $(TOP) -xf -

iproute2: $(TOP)/iproute2
	@true

$(TOP)/dnsmasq:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - dnsmasq | tar -C $(TOP) -xf -

dnsmasq: $(TOP)/dnsmasq
	@true

$(TOP)/LPRng:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - LPRng | tar -C $(TOP) -xf -

LPRng: $(TOP)/LPRng
	@true

p910nd_Patches := $(call patches_list,p910nd)

$(TOP)/p910nd: p910nd/$(P910ND).tar.bz2
	@rm -rf $(TOP)/$(P910ND) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(P910ND) $(p910nd_Patches)
	mv $(TOP)/$(P910ND) $@ && touch $@

p910nd: $(TOP)/p910nd
	@true

samba_Patches := $(call patches_list,samba)

$(TOP)/samba: samba/$(SAMBA).tar.bz2
	@rm -rf $(TOP)/$(SAMBA) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(SAMBA) $(samba_Patches)
	tar -xzvf samba/$(SAMBA)-codepages.tar.gz -C $(TOP)/$(SAMBA)
	mv $(TOP)/$(SAMBA) $@

samba: $(TOP)/samba
	@true

iptables:
	$(MAKE) -C $(IPTABLES) $@

$(TOP)/ipset:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - ipset | tar -C $(TOP) -xf -

ipset: $(TOP)/ipset
	@true

$(TOP)/nfs-utils:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - nfs-utils | tar -C $(TOP) -xf -

nfs-utils: $(TOP)/nfs-utils
	@true

$(TOP)/portmap:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - portmap | tar -C $(TOP) -xf -

portmap: $(TOP)/portmap
	@true

$(TOP)/bridge:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - bridge | tar -C $(TOP) -xf -

bridge: $(TOP)/bridge
	@true

radvd_Patches := $(call patches_list,radvd)

$(TOP)/radvd: radvd/$(RADVD).tar.gz
	@rm -rf $(TOP)/$(RADVD) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(RADVD) $(radvd_Patches)
	mv $(TOP)/$(RADVD) $@

radvd: $(TOP)/radvd
	@true

odhcp6c_Patches := $(call patches_list,odhcp6c)

$(TOP)/odhcp6c: odhcp6c/$(ODHCP6C).tar.gz
	@rm -rf $(TOP)/$(ODHCP6C) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(ODHCP6C) $(odhcp6c_Patches)
	mv $(TOP)/$(ODHCP6C) $@

odhcp6c: $(TOP)/odhcp6c
	@true

quagga_Patches := $(call patches_list,quagga)

$(TOP)/quagga: quagga/$(QUAGGA).tar.bz2
	@rm -rf $(TOP)/$(QUAGGA) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(QUAGGA) $(quagga_Patches)
	mv $(TOP)/$(QUAGGA) $@

quagga: $(TOP)/quagga
	@true

$(TOP)/netconf:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - netconf | tar -C $(TOP) -xf -

netconf: $(TOP)/netconf
	@true

$(TOP)/rc/Makefile:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - rc | tar -C $(TOP) -xf -

rc: $(TOP)/rc/Makefile
	@true

ppp_Patches := $(call patches_list,ppp)

$(TOP)/ppp: ppp/$(PPP).tar.bz2
	@rm -rf $(TOP)/$(PPP) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(PPP) $(ppp_Patches)
	mv $(TOP)/$(PPP) $@ && touch $@

ppp: $(TOP)/ppp
	@true

$(TOP)/rp-l2tp:
	tar -C gateway $(TAR_EXCL_VCS) -cf - $(L2TP) | tar -C $(TOP) -xf -

rp-l2tp: $(TOP)/rp-l2tp
	@true

rp-pppoe_Patches := $(call patches_list,rp-pppoe)

$(TOP)/rp-pppoe: rp-pppoe/$(RP-PPPOE).tar.gz
	@rm -rf $(TOP)/$(RP-PPPOE) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(RP-PPPOE) $(rp-pppoe_Patches)
	mv $(TOP)/$(RP-PPPOE) $@ && touch $@

rp-pppoe: $(TOP)/rp-pppoe
	@true

accel-pptp_Patches := $(call patches_list,accel-pptp)

$(TOP)/accel-pptp: accel-pptp/$(ACCEL-PPTP).tar.bz2
	@rm -rf $(TOP)/$(ACCEL-PPTP) $@
	tar -xjf $^ -C $(TOP)
	rm -rf $(TOP)/$(ACCEL-PPTP)/pppd_plugin/src/pppd
	ln -s $(TOP)/ppp/pppd $(TOP)/$(ACCEL-PPTP)/pppd_plugin/src/pppd
	$(PATCHER) -Z $(TOP)/$(ACCEL-PPTP) $(accel-pptp_Patches)
	mv $(TOP)/$(ACCEL-PPTP) $@ && touch $@
	touch $@

accel-pptp: $(TOP)/accel-pptp
	@true

accel-ppp_Patches := $(call patches_list,accel-ppp)

$(TOP)/accel-ppp: accel-ppp/$(ACCEL-PPP).tar.gz
	@rm -rf $(TOP)/$(ACCEL-PPP) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(ACCEL-PPP) $(accel-ppp_Patches)
	mv $(TOP)/$(ACCEL-PPP) $@ && touch $@
	touch $@

accel-ppp: $(TOP)/accel-ppp
	@true

$(TOP)/igmpproxy:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - igmpproxy | tar -C $(TOP) -xf -

igmpproxy: $(TOP)/igmpproxy
	@true

$(TOP)/udpxy:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - udpxy | tar -C $(TOP) -xf -

udpxy: $(TOP)/udpxy
	@true

inadyn_Patches := $(call patches_list,inadyn)

$(TOP)/inadyn:
	@rm -rf $@
	tar -C gateway $(TAR_EXCL_VCS) -cf - inadyn | tar -C $(TOP) -xf -
	$(PATCHER) -Z $@ $(inadyn_Patches)

inadyn: $(TOP)/inadyn
	@true

$(TOP)/bpalogin:
	@rm -rf $@
	tar -C gateway $(TAR_EXCL_VCS) -cf - bpalogin | tar -C $(TOP) -xf -

bpalogin: $(TOP)/bpalogin
	@true

rcamd_Patches := $(call patches_list,mjpg-streamer)

$(TOP)/mjpg-streamer: mjpg-streamer/mjpg-streamer-r103.tar.bz2
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/mjpg-streamer $(rcamd_Patches)

mjpg-streamer: $(TOP)/mjpg-streamer
	@true

$(TOP)/jpeg-8b:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - jpeg-8b | tar -C $(TOP) -xf -

libjpeg: $(TOP)/jpeg-8b
	@true

$(TOP)/scsi-idle:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - scsi-idle | tar -C $(TOP) -xf -

scsi-idle: $(TOP)/scsi-idle
	@true

libusb: $(TOP)/libusb10
	@true

libusb10_Patches := $(call patches_list,libusb)

$(TOP)/libusb10: libusb/$(LIBUSB10).tar.bz2
	@rm -rf $(TOP)/$(LIBUSB10) $@
	tar -jxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(LIBUSB10) $(libusb10_Patches)
	mv $(TOP)/$(LIBUSB10) $@ && touch $@

modeswitch_Patches := $(call patches_list,usb_modeswitch)

$(TOP)/usb_modeswitch: usb_modeswitch/$(USBMODESWITCH).tar.bz2
	rm -rf $(TOP)/$(USBMODESWITCH) $@
	tar -jxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(USBMODESWITCH) $(modeswitch_Patches)
	$(MAKE) -C $(TOP)/$(USBMODESWITCH) clean
	mv $(TOP)/$(USBMODESWITCH) $@ && touch $@
	# usb_modeswitch data
	tar -C usb_modeswitch $(TAR_EXCL_VCS) -cf - data | tar -C $(TOP)/usb_modeswitch -xf -

usb_modeswitch: $(TOP)/usb_modeswitch
	@true

wimax_Patches := $(call patches_list,wimax)

$(TOP)/madwimax: wimax/$(MADWIMAX).tar.gz
	rm -rf $(TOP)/$(MADWIMAX) $@
	tar -zxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(MADWIMAX) $(wimax_Patches)
	mv $(TOP)/$(MADWIMAX) $@ && touch $@

wimax: $(TOP)/madwimax
	@true

lltd_Patches := $(call patches_list,lltd)

$(TOP)/lltd: lltd/$(LLTD).tar.bz2
	rm -rf $(TOP)/$(LLTD) $@
	tar -jxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(LLTD) $(lltd_Patches)
	tar -jxf lltd/icons.tar.bz2 -C $(TOP)/$(LLTD)
	mv $(TOP)/$(LLTD) $@ && touch $@

lltd: $(TOP)/lltd
	@true

$(TOP)/libpcap: 
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - libpcap | tar -C $(TOP) -xf -

libpcap: $(TOP)/libpcap
	@true

$(TOP)/tcpdump: 
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - tcpdump | tar -C $(TOP) -xf -

tcpdump: libpcap $(TOP)/tcpdump
	@true

udev_Patches := $(call patches_list,udev)

$(TOP)/udev: udev/$(UDEV).tar.bz2
	@rm -rf $(TOP)/$(UDEV) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(UDEV) $(udev_Patches)
	mv $(TOP)/$(UDEV) $@ && touch $@

udev: $(TOP)/udev
	@true

sysfsutils_Patches := $(call patches_list,sysfsutils)

$(TOP)/sysfsutils: sysfsutils/$(SYSFSUTILS).tar.bz2
	@rm -rf $(TOP)/$(SYSFSUTILS) $@
	tar -xjf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(SYSFSUTILS) $(sysfsutils_Patches)
	mv $(TOP)/$(SYSFSUTILS) $@ && touch $@

sysfsutils: $(TOP)/sysfsutils
	@true

$(TOP)/e2fsprogs:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - e2fsprogs | tar -C $(TOP) -xf -

e2fsprogs: $(TOP)/e2fsprogs
	@true

$(TOP)/others:
	tar -C gateway $(TAR_EXCL_VCS) -cf - others | tar -C $(TOP) -xf -

others: $(TOP)/others

$(TOP)/lib:
	tar -C gateway $(TAR_EXCL_VCS) -cf - lib | tar -C $(TOP) -xf -

lib: $(TOP)/lib

libbcmcrypto:
	$(MAKE) -C $(BRCM-SRC) $@

wlconf:
	$(MAKE) -C $(BRCM-SRC) $@

miniupnpd_Patches := $(call patches_list,miniupnpd)

$(TOP)/miniupnpd: miniupnpd/$(MINIUPNPD).tar.gz
	rm -rf $(TOP)/$(MINIUPNPD) $@
	tar -zxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(MINIUPNPD) $(miniupnpd_Patches)
	mv $(TOP)/$(MINIUPNPD) $@ && touch $@

miniupnpd: $(TOP)/miniupnpd
	@true

wpa_supplicant_Patches := $(call patches_list,wpa_supplicant)

$(TOP)/wpa_supplicant: wpa_supplicant/$(WPA_SUPPLICANT).tar.gz
	rm -rf $(TOP)/$(WPA_SUPPLICANT) $@
	tar -zxf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(WPA_SUPPLICANT) $(wpa_supplicant_Patches)
	cp -p wpa_supplicant/wpa_supplicant.config $(TOP)/$(WPA_SUPPLICANT)/wpa_supplicant/.config
	mv $(TOP)/$(WPA_SUPPLICANT) $@ && touch $@

wpa_supplicant: $(TOP)/wpa_supplicant
	@true

$(TOP)/lanauth:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - lanauth | tar -C $(TOP) -xf -

lanauth: $(TOP)/lanauth
	@true

$(TOP)/authcli:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - authcli | tar -C $(TOP) -xf -

authcli: $(TOP)/authcli
	@true

$(TOP)/httpd:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - httpd | tar -C $(TOP) -xf -

httpd: $(TOP)/httpd
	@true

$(TOP)/nvram:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - nvram | tar -C $(TOP) -xf -

nvram: $(TOP)/nvram
	@true

$(TOP)/shared:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - shared | tar -C $(TOP) -xf -

shared: $(TOP)/shared
	@true

$(TOP)/utils:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - utils | tar -C $(TOP) -xf -

utils: $(TOP)/utils
	@true

$(TOP)/infosrv:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - infosrv | tar -C $(TOP) -xf -

infosrv: $(TOP)/infosrv
	@true

$(TOP)/cdma:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - cdma | tar -C $(TOP) -xf -

cdma: $(TOP)/cdma
	@true

$(TOP)/uqmi:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - uqmi | tar -C $(TOP) -xf -

uqmi: $(TOP)/uqmi
	@true

$(TOP)/misc:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - misc | tar -C $(TOP) -xf -

misc: $(TOP)/misc
	@true

$(TOP)/www:
	[ -d $@ ] || \
		tar -C gateway $(TAR_EXCL_VCS) -cf - www | tar -C $(TOP) -xf -

www: $(TOP)/www
	@true


#%-diff:
#	[ -d $(SRC)/$* ] || [ -d $(TOP)/$* ] && \
#	    $(call make_diff,-BurpN,router,gateway,$*)

.PHONY: custom kernel kernel-patch kernel-extra-drivers brcm-src www \
	accel-pptp busybox dropbear inadyn httpd iptables others \
	rc mjpg-streamer libjpeg config igmpproxy iproute2 lib shared utils
