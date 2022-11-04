#!/bin/sh

echo "custatus:9:100.0000:Installing core APT utilities..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
ln -s /bin/sh /bin/bash # work around a bug in adduser
install_deps --and-package apt
rm /bin/bash # remove adduser bug workaround

# configure the apt sources file
(
    . "${DIR}"/load-config.sh
    echo "deb file:/${DEBPATH} ./" >> /etc/apt/sources.list
    echo "deb ${MIRRORSITE} ${DISTRIBUTION} ${COMPONENTS}"  >> /etc/apt/sources.list
)

# set a "pin" to prefer the local copy of packages when they are available (TODO not needed?)
#cat << EOF > /etc/apt/preferences.d/99-prefer-local-packages
#Package: *
#Pin: origin ""
#Pin-Priority: 1001
#EOF

# keep downloaded packages so that it is easy to make a collection of them
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >> /etc/apt/apt.conf.d/99-keep-downloads

# install common utilities that virtually everything will require (and were not already needed)
echo "destatus:0:0.0000:Updating apt package list..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
apt -o APT::Status-Fd=3 update 3>/REAL_ROOT/${DEBEXEC_APTSTATUS}
# * rest of util-linux unlisted dependencies
echo "destatus:1:0.0000:Installing pre-dependency packages..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
ln -s /bin/false /bin/mountpoint # work around bug in usrmerge
apt -o APT::Status-Fd=3 install --yes \
    libterm-readline-gnu-perl \
    init-system-helpers \
    bash \
3>/REAL_ROOT/${DEBEXEC_APTSTATUS};
rm /bin/mountpoint # remove usrmerge bug workaround
# * dependencies are satisfied
echo "destatus:2:0.0000:Installing packages..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
apt -o APT::Status-Fd=3 install --yes \
    apt-utils \
    gzip \
    libtext-iconv-perl \
    locales-all \
    mount \
    util-linux \
    wget \
3>/REAL_ROOT/${DEBEXEC_APTSTATUS};
