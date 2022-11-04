db_get() {
    echo "get $1" | debconf-communicate 2>/dev/null | sed 's/[^ ]* //'
}

AREA=$(db_get tzdata/Areas)
ZONE=$(db_get tzdata/Zones/${AREA})
model=$(db_get keyboard-configuration/modelcode)
layout=$(db_get keyboard-configuration/layoutcode)
variant=$(db_get keyboard-configuration/variantcode)
options=$(db_get keyboard-configuration/optionscode)

mkdir -p "${FAKEROOT}"/usr/var/cache/debexec
cat - > "${FAKEROOT}"/usr/var/cache/debexec/debconf <<EOF
tzdata	tzdata/Areas	select	${AREA}
tzdata	tzdata/Zones/$AREA	select ${ZONE}
keyboard-configuration	keyboard-configuration/modelcode	string	${model}
keyboard-configuration	keyboard-configuration/layoutcode	string	${layout}
keyboard-configuration	keyboard-configuration/variantcode	string	${variant}
keyboard-configuration	keyboard-configuration/optionscode	string	${options}
EOF
