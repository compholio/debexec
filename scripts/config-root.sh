if [ "${CONFIGURED}" = "" ]; then
    mkdir -p "${FAKEROOT}/REAL_ROOT"
    for FILE in $(ls /); do ln -s "/${FILE}" "${FAKEROOT}/REAL_ROOT/${FILE}"; done
    for FILE in $(ls /); do ln -s "REAL_ROOT/${FILE}" "${FAKEROOT}/${FILE}"; done
else
    rm "${FAKEROOT}"/etc/ld.so.preload 2>/dev/null
fi
rm "${FAKEROOT}"/run 2>/dev/null
mount --bind "${FAKEROOT}" "${FAKEROOT}"
for FILE in ${SPECIAL_DIRS}; do
    rm "${FAKEROOT}/${FILE}" 2>/dev/null
    mkdir -p "${FAKEROOT}/${FILE}"
    mount --rbind $(realpath "/${FILE}") "${FAKEROOT}/${FILE}"
done
. "${DIR}"/query-debconf.sh
pivot_root "${FAKEROOT}" "${FAKEROOT}/REAL_ROOT"

# "which" is required very early by some scripts
rm /tmp 2>/dev/null
mkdir -p /tmp/bin/
ln -s $(realpath $(which which)) /tmp/bin/which 2>/dev/null

# allow access to our scripts within the container
mkdir -p "${DIR}"
mount --bind /REAL_ROOT/"${DIR}" "${DIR}"

LD_LINUX=$(realpath /REAL_ROOT/lib64/ld-linux-x86-64.so.2)

if [ "${CONFIGURED}" = "" ]; then
    # get rid of most of the temporary root system, only keep key files
    FILES=""
    for FILE in $(ls /); do
        found=$(find_in_list ${FILE} ${SPECIAL_DIRS} tmp)
        if [ "${found}" -eq "1" ]; then
            continue;
        fi
        FILES="${FILES} /${FILE}";
    done;
    rm ${FILES} 2>/dev/null;
fi

