# let apt know that we're operating within a sandbox
mkdir -p /etc/apt/apt.conf.d
echo 'APT::Sandbox::Verify::IDs "false";' >> /etc/apt/apt.conf.d/99-sandbox

# hook ownership routines such that common sudo operations will complete successfully
if [ -f "${DEBEXEC_DIR}"/lib/debexec-preload.so ]; then
    cp -a "${DEBEXEC_DIR}"/lib/debexec-preload.so /usr/var/cache/debexec
    echo /usr/var/cache/debexec/debexec-preload.so > /etc/ld.so.preload
fi
