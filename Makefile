# phoenix-rtos-deb
#
# Ubuntu package building script
#
# (C) 2025-2025 Apator Metrix
# Author: Mateusz Karcz


VERSION ?= 99
REVISION ?= 260428
UBUNTU ?= noble


PROJECT_PREFIX   = $(shell pwd)
TOOLCHAIN_PREFIX = $(shell pwd)/_int/toolchain
LIBSTDCXX_PREFIX = $(shell pwd)/_int/libstdc++


all: toolchain libstdc++

clean:
	rm -rf _int _out _pkg

clean-everything: clean
	rm -rf _ext


toolchain: _out/arm-phoenix-toolchain_$(VERSION)-$(REVISION)~$(UBUNTU).deb

_out/arm-phoenix-toolchain_$(VERSION)-$(REVISION)~$(UBUNTU).deb: \
	_pkg/toolchain/DEBIAN/control \
	_pkg/toolchain/usr/local/bin/arm-phoenix-gcc
	mkdir -p $(@D)
	dpkg-deb --build _pkg/toolchain $@

_pkg/toolchain/usr/local/bin/arm-phoenix-gcc: $(TOOLCHAIN_PREFIX)/arm-phoenix/bin/arm-phoenix-gcc
	mkdir -p _pkg/toolchain/usr
	cp -r $(TOOLCHAIN_PREFIX)/arm-phoenix _pkg/toolchain/usr/local
	rm -rf _pkg/toolchain/usr/lib/bfd-plugins
	rm -rf _pkg/toolchain/usr/local/share/info
	rm -rf _pkg/toolchain/usr/local/share/locale

_pkg/toolchain/DEBIAN/control:
	mkdir -p $(@D)
	echo "Package: arm-phoenix-toolchain" > $@
	echo "Version: $(VERSION)-$(REVISION)" >> $@
	echo "Section: base" >> $@
	echo "Priority: optional" >> $@
	echo "Architecture: amd64" >> $@
	echo "Maintainer: Mateusz Karcz <mateusz.karcz@apator.com>" >> $@
	echo "Description: Phoenix-RTOS cross toolchain for ARM" >> $@


$(TOOLCHAIN_PREFIX)/arm-phoenix/bin/arm-phoenix-gcc: _ext/phoenix-rtos-build/toolchain/build.sh
	mkdir -p $(@D)
	cd $(<D) && ./$(<F) arm-phoenix $(TOOLCHAIN_PREFIX)


libstdc++: _out/arm-phoenix-libstdc++_$(VERSION)-$(REVISION).deb

_out/arm-phoenix-libstdc++_$(VERSION)-$(REVISION).deb: \
	_pkg/libstdc++/DEBIAN/control \
	_pkg/libstdc++/usr/local
	mkdir -p $(@D)
	dpkg-deb --build _pkg/libstdc++ $@

_pkg/libstdc++/usr/local: $(LIBSTDCXX_PREFIX)/arm-phoenix
	mkdir -p _pkg/libstdc++/usr
	cp -r $(LIBSTDCXX_PREFIX)/arm-phoenix _pkg/libstdc++/usr/local

_pkg/libstdc++/DEBIAN/control:
	mkdir -p $(@D)
	echo "Package: arm-phoenix-libstdc++" > $@
	echo "Version: $(VERSION)-$(REVISION)" >> $@
	echo "Section: base" >> $@
	echo "Priority: optional" >> $@
	echo "Architecture: amd64" >> $@
	echo "Maintainer: Mateusz Karcz <mateusz.karcz@apator.com>" >> $@
	echo "Description: Phoenix-RTOS flavor of libstdc++ for ARM" >> $@

$(LIBSTDCXX_PREFIX)/arm-phoenix: _ext/phoenix-rtos-build/toolchain/build-libstdc++.sh
	mkdir -p $(@D)
	cd $(<D) && ./$(<F) arm-phoenix $(LIBSTDCXX_PREFIX)


_ext/phoenix-rtos-build/toolchain/build.sh: _ext/phoenix-rtos-build/toolchain/build-toolchain.sh
	sed -E "s/-j[0-9]+/-j$(shell nproc --all)/" $< | \
		sed -E "/^build_libstdcpp;/d" > $@
	chmod +x $@

_ext/phoenix-rtos-build/toolchain/build-libstdc++.sh: _ext/phoenix-rtos-build/toolchain/build-toolchain.sh
	sed -E "s/-j[0-9]+/-j$(shell nproc --all)/" $< | \
		sed -E "s/command -v \"\\$$\{TARGET\}-gcc\"/false/" | \
		sed -E "/\\$$\{BINUTILS\}.tar.bz2/d" | \
		sed -n "/### MAIN ###/q;p" > $@
	echo "download;" >> $@
	cat patch-gcc.sh >> $@
	echo "build_libstdcpp;" >> $@
	echo "strip_binaries;" >> $@
	chmod +x $@

_ext/phoenix-rtos-build/toolchain/build-toolchain.sh: \
	_ext/phoenix-rtos-build \
	_ext/phoenix-rtos-kernel \
	_ext/libphoenix
	@test -f $@ || { echo "Missing $@ (did clone/checkout succeed?)"; exit 1; }
	cd _ext/phoenix-rtos-build && git apply $(PROJECT_PREFIX)/build-toolchain.sh.patch

_ext/%:
	git clone https://github.com/phoenix-rtos/$(@F).git _ext/$(@F)
	cd _ext/$(@F) && git checkout master
