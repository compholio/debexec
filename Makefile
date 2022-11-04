VERSION=$(shell ./version.sh)

.PHONY: examples

all: debexec_$(VERSION)_amd64.deb

clean:
	rm -rf debexec

.keys:
	mkdir -p .keys

.keys/pubkey_5E3C45D7B312C643.gpg: .keys
	wget -O .keys/pubkey_5E3C45D7B312C643.gpg https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg

examples: .keys/pubkey_5E3C45D7B312C643.gpg
	./bin/debexec-create examples/desmume
	./bin/debexec-create examples/discord
	./bin/debexec-create examples/firefox
	./bin/debexec-create examples/gimp
	./bin/debexec-create examples/inkscape
	./bin/debexec-create examples/python3
	./bin/debexec-create --gpgkey .keys/pubkey_5E3C45D7B312C643.gpg examples/spotify
	./bin/debexec-create examples/steam
	./bin/debexec-create examples/vlc

debexec/DEBIAN:
	mkdir -p debexec/DEBIAN
	cp -a debian/preinst debian/postinst debian/prerm debexec/DEBIAN

debexec/DEBIAN/control: debian/control.in debexec/DEBIAN
	cat debian/control.in | sed "s/@@VERSION@@/$(VERSION)/" > debexec/DEBIAN/control

debexec/usr/bin:
	mkdir -p debexec/usr/bin
	ln -s /usr/share/debexec/bin/debexec debexec/usr/bin/debexec
	ln -s /usr/share/debexec/bin/debexec-create debexec/usr/bin/debexec-create

debexec/usr/share/binfmts:
	mkdir -p debexec/usr/share/binfmts/
	cp -a binfmts/debexec debexec/usr/share/binfmts/debexec

debexec/usr/share/mime/packages/debexec.xml:
	mkdir -p debexec/usr/share/mime/packages/
	cp -a mime/debexec.xml debexec/usr/share/mime/packages/debexec.xml

debexec/usr/share/applications/debexec.desktop:
	mkdir -p debexec/usr/share/applications/
	cp -a mime/debexec.desktop debexec/usr/share/applications/debexec.desktop

.icon-cache:
	mkdir -p .icon-cache
	./icons/render-bitmaps.py --source-path icons/Yaru --dest-path .icon-cache

debexec/usr/share/icons: .icon-cache
	mkdir -p debexec/usr/share/icons/
	cp -a .icon-cache/Yaru debexec/usr/share/icons/hicolor

debexec/usr/share/debexec:
	mkdir -p debexec/usr/share/debexec/

debexec/usr/share/debexec/version.sh: debexec/usr/share/debexec
	echo "printf '%s' '$(VERSION)'" > debexec/usr/share/debexec/version.sh
	chmod +x debexec/usr/share/debexec/version.sh

debexec/usr/share/debexec/debexec.gpg: debexec/usr/share/debexec
	cp debexec.gpg debexec/usr/share/debexec/debexec.gpg

debexec/usr/share/debexec/bin: debexec/usr/share/debexec
	cp -a bin debexec/usr/share/debexec/

src/debexec-preload.so:
	DEBEXEC_UIDMAP=1 ./scripts/debexec.sh

debexec/usr/share/debexec/lib: src/debexec-preload.so
	mkdir -p debexec/usr/share/debexec/lib
	cp -a src/debexec-preload.so debexec/usr/share/debexec/lib/

debexec/usr/share/debexec/scripts:
	mkdir -p debexec/usr/share/debexec
	cp -a scripts debexec/usr/share/debexec/

debexec_$(VERSION)_amd64-unsigned.deb: debexec/DEBIAN/control debexec/usr/share/debexec/version.sh debexec/usr/share/debexec/debexec.gpg debexec/usr/bin debexec/usr/share/binfmts debexec/usr/share/mime/packages/debexec.xml debexec/usr/share/applications/debexec.desktop debexec/usr/share/icons debexec/usr/share/debexec/bin debexec/usr/share/debexec/lib debexec/usr/share/debexec/scripts
	dpkg-deb -Zxz --root-owner-group --build debexec debexec_$(VERSION)_amd64-unsigned.deb

.gnupg:
	mkdir -p .gnupg
	chmod 700 .gnupg
	echo "$${PRIVATE_KEY}" | gpg --batch --no-options --homedir=$(PWD)/.gnupg --import 2>/dev/null || true

# add a debsigs-compatible signature to the package
debexec_$(VERSION)_amd64.deb: debexec_$(VERSION)_amd64-unsigned.deb .gnupg
	$(eval SIGNATURE=$(shell cat debexec_$(VERSION)_amd64-unsigned.deb | gpg --openpgp --homedir=$(PWD)/.gnupg --detach-sign 2>/dev/null > signature.dat && echo "header.dat signature.dat" || true))
	@echo "_gpgorigin      0           0     0     644     $$(printf "%-10s" $$(wc -c < signature.dat || true))\`" > header.dat
	@cat debexec_$(VERSION)_amd64-unsigned.deb $(SIGNATURE) > debexec_$(VERSION)_amd64.deb
	@rm header.dat signature.dat || true
