log "patching ${GCC}"
for patchfile in "${GCC}"-*.patch; do
    if [ ! -f "${GCC}/$patchfile.applied" ]; then
        patch -d "${GCC}" -p1 < "$patchfile"
        touch "${GCC}/$patchfile.applied"
    fi
done
