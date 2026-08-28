#!/bin/bash
#Script to build buildroot configuration
#Author: Siddhant Jajoo

source shared.sh

EXTERNAL_REL_BUILDROOT=../base_external
git submodule init
git submodule sync
git submodule update

set -e 
cd `dirname $0`

# =====================================================================
# BULLETPROOF QEMU HOTFIX
# 1. Create a Python script that perfectly patches mkvenv.py
cat << 'EOF' > buildroot/package/qemu/patch_mkvenv.py
import sys
import os

qemu_dir = sys.argv[1]
file_path = os.path.join(qemu_dir, "python/scripts/mkvenv.py")

try:
    with open(file_path, "r") as f:
        lines = f.readlines()

    with open(file_path, "w") as f:
        for line in lines:
            if "maker = distlib.scripts.ScriptMaker(None, bin_path)" in line:
                f.write('    import os\n')
                f.write('    for p in packages:\n')
                f.write('        s = os.path.join(bin_path, p)\n')
                f.write('        with open(s, "w") as sf:\n')
                f.write('            if p == "meson":\n')
                f.write('                sf.write(\'#!/bin/sh\\nexec meson "$@"\\n\')\n')
                f.write('            else:\n')
                f.write('                sf.write(\'#!/bin/sh\\nexec python3 -m \' + p + \' "$@"\\n\')\n')
                f.write('        os.chmod(s, 0o755)\n')
                f.write('    return\n')
            f.write(line)
    print("Successfully patched mkvenv.py for QEMU!")
except Exception as e:
    print("Note: Patching mkvenv.py skipped or failed: " + str(e))
EOF

# 2. Inject a hook into QEMU's makefile to run our Python script
if ! grep -q "HOST_QEMU_PATCH_MKVENV" buildroot/package/qemu/qemu.mk; then
    echo "Injecting QEMU patch at the top of qemu.mk..."
    
    cat << 'EOF' > qemu_patch_temp.mk
define HOST_QEMU_PATCH_MKVENV
	python3 package/qemu/patch_mkvenv.py $(@D)
endef
HOST_QEMU_POST_EXTRACT_HOOKS += HOST_QEMU_PATCH_MKVENV

EOF
    cat buildroot/package/qemu/qemu.mk >> qemu_patch_temp.mk
    mv qemu_patch_temp.mk buildroot/package/qemu/qemu.mk
fi
# =====================================================================

if [ ! -e buildroot/.config ]
then
    echo "MISSING BUILDROOT CONFIGURATION FILE"

    if [ -e ${AESD_MODIFIED_DEFCONFIG} ]
    then
        echo "USING ${AESD_MODIFIED_DEFCONFIG}"
        make -C buildroot defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT}
    else
        echo "Run ./save_config.sh to save this as the default configuration in ${AESD_MODIFIED_DEFCONFIG}"
        echo "Then add packages as needed to complete the installation, re-running ./save_config.sh as needed"
        make -C buildroot defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_DEFAULT_DEFCONFIG}
    fi
else
    echo "USING EXISTING BUILDROOT CONFIG"
    echo "To force update, delete .config or make changes using make menuconfig and build again."
    make -C buildroot BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT}
fi
