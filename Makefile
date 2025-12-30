# phoenix-rtos-deb
#
# Ubuntu package building script
#
# (C) 2025 Apator Metrix
# Author: Mateusz Karcz


VERSION ?= 3.3.2
REVISION ?= 1
UBUNTU ?= noble


INSTALL_PREFIX = $(shell pwd)/_int


all: _out/arm-phoenix-toolchain_$(VERSION)-$(REVISION)~$(UBUNTU).deb

clean:
	rm -rf _int _out _pkg

clean-everything: clean
	rm -rf _ext


_out/arm-phoenix-toolchain_$(VERSION)-$(REVISION)~$(UBUNTU).deb: \
	_pkg/DEBIAN/control \
	_pkg/usr/local/bin/arm-phoenix-gcc
	mkdir -p $(@D)
	rm -rf $(INSTALL_PREFIX)/_build
	dpkg-deb --build _pkg $@

_pkg/usr/local/bin/arm-phoenix-gcc: $(INSTALL_PREFIX)/arm-phoenix/bin/arm-phoenix-gcc
	mkdir -p _pkg/usr
	cp -r $(INSTALL_PREFIX)/arm-phoenix _pkg/usr/local

_pkg/DEBIAN/control:
	mkdir -p $(@D)
	echo "Package: arm-phoenix-toolchain" > $@
	echo "Version: $(VERSION)-$(REVISION)" >> $@
	echo "Section: base" >> $@
	echo "Priority: optional" >> $@
	echo "Architecture: amd64" >> $@
	echo "Maintainer: Mateusz Karcz <mateusz.karcz@apator.com>" >> $@
	echo "Description: Phoenix-RTOS cross toolchain for ARM" >> $@


$(INSTALL_PREFIX)/arm-phoenix/bin/arm-phoenix-gcc: _ext/phoenix-rtos-build/toolchain/build-toolchain.sh
	mkdir -p $(@D)
	cd $(<D) && ./$(<F) arm-phoenix $(INSTALL_PREFIX)


_ext/phoenix-rtos-build/toolchain/build-toolchain.sh: \
	_ext/phoenix-rtos-build \
	_ext/phoenix-rtos-kernel \
	_ext/libphoenix
	@test -f $@ || { echo "Missing $@ (did clone/checkout succeed?)"; exit 1; }

_ext/%:
	git clone https://github.com/phoenix-rtos/$(@F).git _ext/$(@F)
	cd _ext/$(@F) && git checkout v$(VERSION)
