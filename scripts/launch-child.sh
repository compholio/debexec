DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

REVERTUID=0
FLAGS="--user"

SHIFT=1
while [ "${SHIFT}" -ne "0" ]; do
    case "$1" in
        --revertuid)
            REVERTUID=1
            USEPROC="--use-proc"
            DEBEXEC_UID=$(cat /usr/var/cache/debexec/uid)
            DEBEXEC_GID=$(cat /usr/var/cache/debexec/gid)
            SHIFT=1
            ;;
        --mount)
            FLAGS="${FLAGS} $1"
            SHIFT=1
            ;;
        --)
            SHIFT=1
            ;;
        *)
            SHIFT=0
            ;;
    esac
    shift ${SHIFT}
done

ARGS="$@"
TRIGA=$(mktemp --tmpdir "debexec-trigA.XXXXXXXXXX")
TRIGB=$(mktemp --tmpdir "debexec-trigB.XXXXXXXXXX")
mkfifo "${TRIGA}" "${TRIGB}" 2>/dev/null
unshare ${FLAGS} /bin/sh -lc "echo '' > '${TRIGA}'; cat '${TRIGB}'; rm '${TRIGA}' '${TRIGB}'; ${ARGS}" &
PID=$!
cat "${TRIGA}"
if [ "${REVERTUID}" -eq "1" ]; then
    UIDMAP=$(printf "${DEBEXEC_UID} 0 1\n")
    GIDMAP=$(printf "${DEBEXEC_GID} 0 1\n")
    if [ "${DEBEXEC_UIDMAP}" -eq "1" ]; then
        UIDMAP="${UIDMAP} 1 1 999\n0 65535 1\n"
        GIDMAP="${GIDMAP} 1 1 999\n0 65535 1\n"
    fi
else
    UIDMAP="0 $(id -u) 1"
    GIDMAP="0 $(id -g) 1"
    if [ "${DEBEXEC_UIDMAP}" -eq "1" ]; then
        UIDMAP="${UIDMAP} 1 $(cat /etc/subuid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")"
        GIDMAP="${GIDMAP} 1 $(cat /etc/subgid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")"
    else
        USEPROC="--use-proc"
    fi
fi
/bin/sh "${DIR}"/config-ids.sh ${USEPROC} "${PID}" "${UIDMAP}" "${GIDMAP}"
echo "" > "${TRIGB}"
fg %1
wait ${PID}
