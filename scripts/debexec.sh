#!/bin/sh

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEBEXEC_DIR="${DIR}"/../

DEBEXEC_LAUNCH=$(DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh /"${DIR}"/config-launch.sh)

if [ "$1" != "--fakeroot" ]; then
    . "${DIR}"/initial-setup.sh
    export DEBEXEC_UIDMAP=$(/bin/sh "${DIR}"/use-uidmap.sh)
    /bin/sh -m "${DIR}"/launch-child.sh --mount -- "$0" --fakeroot "${FAKEROOT}" --username $(id -un) --userid $(id -u) --userid $(id -u) --groupid $(id -g) "$@"
    if [ "${DEBEXEC_PERSIST}" = "" ]; then
        rm -rf "${FAKEROOT}"
    fi
    rm "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}" "${DEBEXEC_APTREAD}" "${DEBEXEC_APTWRITE}" 2>/dev/null
    exit 0
fi

# let the gui know our process id
if [ "${DEBEXEC_GUI}" -eq "1" ]; then
    printf "DEBEXEC_CHILDPID=$$" > "${DEBEXEC_TOGUI}"
fi

unset TMPDIR # do not use the external temporary directory

NOLAUNCH=0
ASROOT=0
SHIFT=1
while [ "${SHIFT}" -ne "0" ]; do
    case "$1" in
        --fakeroot) FAKEROOT="$2"; SHIFT=2;;
        --username) DEBEXEC_USER="$2"; SHIFT=2;;
        --userid) DEBEXEC_UID="$2"; SHIFT=2;;
        --groupid) DEBEXEC_GID="$2"; SHIFT=2;;
        --as-root) ASROOT=1; SHIFT=1;;
        --no-launch) NOLAUNCH=1; SHIFT=1;;
        *) SHIFT=0;;
    esac
    shift ${SHIFT}
done
#echo $FAKEROOT

. "${DIR}"/helper-functions-early.sh

DEBPATH=/usr/var/cache/debexec/aptcache
CONFIGURED=$(cat "${FAKEROOT}"/usr/var/cache/debexec/configured 2>/dev/null)
SPECIAL_DIRS=$(. "${DIR}"/config-dirs.sh)

COPY_FILES=$(/bin/sh "${DIR}"/get-video.sh)
. "${DIR}"/config-root.sh
#DIR=/REAL_ROOT/"${DIR}"
DEBEXEC_DIR=/REAL_ROOT/"${DEBEXEC_DIR}"
DEBEXEC_TOGUI=/REAL_ROOT/"${DEBEXEC_TOGUI}"
DEBEXEC_FROMGUI=/REAL_ROOT/"${DEBEXEC_FROMGUI}"
. "${DIR}"/helper-functions.sh
if [ "${CONFIGURED}" = "" ]; then
    . "${DIR}"/config-loader.sh
    . "${DIR}"/config-tmpbin.sh
    . "${DIR}"/config-permissions.sh # move ?
    . "${DIR}"/config-cache.sh
    . "${DIR}"/download-packages.sh
fi
/bin/sh "${DIR}"/copy-files.sh ${COPY_FILES}
if [ "${DEBEXEC_UIDMAP}" -eq "0" ]; then
    . "${DIR}"/config-preload.sh
fi
echo "destatus:-1:0.0000:Installing core utilities..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
if [ "${CONFIGURED}" = "" ]; then
    . "${DIR}"/install-coreutils.sh
    . "${DIR}"/install-apt.sh
    . "${DIR}"/config-debconf.sh
    . "${DIR}"/config-terminal.sh
    . "${DIR}"/config-sudo.sh
fi

# call application-specific configuration for installing packages
(
    . "${DIR}"/install-application.sh
)

# select application to launch
if [ "${NOLAUNCH}" -eq "1" ]; then
    DEBEXEC_LAUNCH="${SHELL}"
fi

# store the user ID and group ID of the user for later use
mkdir -p /usr/var/cache/debexec
echo "1" > /usr/var/cache/debexec/configured
echo "${DEBEXEC_UID}" > /usr/var/cache/debexec/uid
echo "${DEBEXEC_GID}" > /usr/var/cache/debexec/gid

# let the gui know that we're all done
if [ "${DEBEXEC_GUI}" -eq "1" ]; then
    printf "DEBEXEC_EXIT=1" > "${DEBEXEC_TOGUI}"
    cat "${DEBEXEC_FROMGUI}" >/dev/null
fi

# drop access to folders outside the container (unless explicitly specified)
OLDPWD="${PWD}"
umount -l /REAL_ROOT
cd "${OLDPWD}" 2>/dev/null || cd / 

if [ "${ASROOT}" -eq "0" ]; then
    # revert to the regular user id:
    /bin/sh -m "${DIR}"/launch-child.sh ${DEBEXEC_PERMISSIONS} --revertuid -- "${DEBEXEC_LAUNCH}"
else
    # launch a root shell:
    "${DEBEXEC_LAUNCH}"
fi

# unmount all the bind mounts (do not try to change permissions on the rest of the system)
for MOUNTPT in ${SPECIAL_DIRS}; do
    umount -l "/${MOUNTPT}" 2>/dev/null
done

# reset all permissions such that the unprivileged user can clean up the folder
for FILE in $(ls /); do
    if [ "$(find_in_list ${FILE} ${SPECIAL_DIRS} root REAL_ROOT)" -eq "1" ]; then
        continue
    fi
    chown -R root:root "/${FILE}" 2>/dev/null
done
