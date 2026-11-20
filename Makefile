# phoenix-rtos-deb
#
# Ubuntu package building script
#
# (C) 2025-2026 Apator Metrix
# Author: Mateusz Karcz


VERSION ?= 3.4.0
REVISION ?= 1
UBUNTU ?= noble
DEB_VERSION := $(VERSION)-$(REVISION)~$(UBUNTU)


PROJECT_PREFIX   = $(shell pwd)
BINUTILS_PREFIX  = $(PROJECT_PREFIX)/_int/binutils
GCC_PREFIX       = $(PROJECT_PREFIX)/_int/gcc
LIBSTDCXX_PREFIX = $(PROJECT_PREFIX)/_int/libstdc++

OS_VERSION_FILE = $(PROJECT_PREFIX)/_ext/OS-VERSION

TARGET       := arm-phoenix
BUILD_SCRIPT := _ext/phoenix-rtos-build/toolchain/build-toolchain.sh

.DEFAULT_GOAL := help

.PHONY: help binutils gcc libstdc++

help:
	@echo "Available targets: binutils gcc libstdc++"

binutils: _out/arm-phoenix-binutils_$(DEB_VERSION)_amd64.deb

gcc: _out/arm-phoenix-gcc_$(DEB_VERSION)_amd64.deb

libstdc++: _out/arm-phoenix-libstdc++_$(DEB_VERSION)_amd64.deb


# Build each component in its own root

_int/%/.built: $(BUILD_SCRIPT) \
	$(OS_VERSION_FILE) \
	_ext/libphoenix/README.md \
	_ext/phoenix-rtos-kernel/README.md
	mkdir -p $(@D)
	OS_VERSION_FILE=$(OS_VERSION_FILE) \
		./$(BUILD_SCRIPT) $(TARGET) $(abspath _int/$*) $*
	touch $@


# Package only the files installed by the selected component

_out/arm-phoenix-%_$(DEB_VERSION)_amd64.deb: _int/%/.built
	rm -rf _pkg/$*
	mkdir -p _pkg/$*/DEBIAN _pkg/$*/usr _out

	cp -a $(abspath _int/$*/$(TARGET)) _pkg/$*/usr/local
	rm -f _pkg/$*/usr/local/share/info/dir

	@printf 'Package: arm-phoenix-%s\nVersion: %s\nSection: devel\nPriority: optional\nArchitecture: amd64\nMaintainer: Mateusz Karcz <mateusz.karcz@apator.com>\n' \
		"$*" "$(DEB_VERSION)" > _pkg/$*/DEBIAN/control

	@case "$*" in \
		gcc) \
			echo "Depends: arm-phoenix-binutils (= $(DEB_VERSION))" \
				>> _pkg/$*/DEBIAN/control ;; \
		libstdc++) \
			echo "Depends: arm-phoenix-gcc (= $(DEB_VERSION))" \
				>> _pkg/$*/DEBIAN/control ;; \
	esac

	@echo "Description: Phoenix-RTOS ARM cross-toolchain component ($*)" \
		>> _pkg/$*/DEBIAN/control

	dpkg-deb --root-owner-group --build _pkg/$* $@

$(BUILD_SCRIPT): _ext/phoenix-rtos-build/README.md
	@test -f $@ || { echo "Missing $@ (did clone/checkout succeed?)"; exit 1; }
	cd _ext/phoenix-rtos-build && git apply $(PROJECT_PREFIX)/build-toolchain.sh.patch

$(OS_VERSION_FILE):
	wget -O $@ https://github.com/phoenix-rtos/phoenix-rtos-project/raw/refs/tags/v$(VERSION)/OS-VERSION

_ext/libphoenix/README.md: _ext/libphoenix
	cd $(@D) && git checkout v$(VERSION)

_ext/phoenix-rtos-build/README.md: _ext/phoenix-rtos-build
	cd $(@D) && git checkout v$(VERSION)

_ext/phoenix-rtos-kernel/README.md: _ext/phoenix-rtos-kernel
	cd $(@D) && git checkout v$(VERSION)

_ext/%:
	git clone https://github.com/phoenix-rtos/$(@F).git _ext/$(@F)
