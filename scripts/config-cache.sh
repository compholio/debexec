# move the debian packages to the cache folder
mkdir -p /usr/var/cache/debexec/aptcache/
if [ ! -z "${DEBEXEC_TMP}" ]; then
    mv "${DEBEXEC_TMP}"/*.deb /usr/var/cache/debexec/aptcache/
fi
