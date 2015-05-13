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
export CWD := $(shell pwd)

export KERNEL_DIR := $(ROOT)/linux/linux-2.6
KERNEL=kernel-2.6
BRCM-SRC=brcm-src-2.6

ACCEL-PPTP=accel-pptp-git-20100829
ACCEL-PPP=accel-ppp-git-20140916
ODHCP6C=odhcp6c-git-20140814

# tar has --exclude parameter ?
export TAR_EXCL_VCS := $(shell tar --exclude-vcs -cf - Makefile >/dev/null 2>&1 && echo "--exclude-vcs")

export PATCHER := $(CWD)/patch.sh

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

subdirs=loader busybox dropbear dnsmasq p910nd iproute2 iptables ipset \
	rp-l2tp nfs-utils portmap radvd quagga ucd-snmp igmpproxy vsftpd udpxy \
	bpalogin bridge inadyn httpd jpeg-8b lib LPRng ppp rp-pppoe \
	misc nvram others rc mjpg-streamer udev \
	scsi-idle libusb usb_modeswitch madwimax uqmi lltd tcpdump libpcap \
	miniupnpd utils www config shared cdma ntfs-3g samba \
	sysfsutils e2fsprogs wpa_supplicant lanauth authcli infosrv \
	wlconf libbcmcrypto 

custom:	asustrx odhcp6c accel-pptp accel-ppp $(subdirs)
	$(MAKE) -C $(KERNEL) version
	$(MAKE) -C $(TOP) .config
	@echo
	@echo Sources prepared for compilation
	@echo

$(TOP):
	@mkdir -p $(TOP)

$(TOP)/Makefile: $(TOP)
	ln -sfT $(CWD)/gateway/Makefile $@

prep: $(TOP)/Makefile
	-@echo "$$(( $(shell git rev-list --all --count origin/HEAD) + 1000 ))$(if $(shell git status -s -uno),M,)" > $(TOP)/.svnrev

rsubdirs=linux lzma4xx lzma bcm57xx emf et include rts shared wl

kernel:
	for dir in $(rsubdirs); do \
		ln -sfT $(CWD)/$${dir} $(ROOT)/$${dir}; \
	done
	$(MAKE) -C $(KERNEL) config

asustrx:
	ln -sfT $(CWD)/$@ $(ROOT)/asustrx

odhcp6c_Patches := $(call patches_list,odhcp6c)

$(TOP)/odhcp6c: odhcp6c/$(ODHCP6C).tar.gz
	@rm -rf $(TOP)/$(ODHCP6C) $@
	tar -xzf $^ -C $(TOP)
	$(PATCHER) -Z $(TOP)/$(ODHCP6C) $(odhcp6c_Patches)
	mv $(TOP)/$(ODHCP6C) $@

odhcp6c: $(TOP)/odhcp6c
	@true

accel-pptp_Patches := $(call patches_list,accel-pptp)

$(TOP)/accel-pptp: accel-pptp/$(ACCEL-PPTP).tar.bz2
	@rm -rf $(TOP)/$(ACCEL-PPTP) $@
	tar -xjf $^ -C $(TOP)
	rm -rf $(TOP)/$(ACCEL-PPTP)/pppd_plugin/src/pppd
	ln -s $(CWD)/gateway/ppp/pppd $(TOP)/$(ACCEL-PPTP)/pppd_plugin/src/pppd
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

$(subdirs):
	ln -sfT $(CWD)/gateway/$@ $(TOP)/$@

clean distclean: $(TOP)/Makefile
	$(MAKE) -C $(TOP) $@
	$(MAKE) -C asustrx $@

.PHONY: kernel kernel-patch kernel-extra-drivers asustrx lzma $(subdirs)
