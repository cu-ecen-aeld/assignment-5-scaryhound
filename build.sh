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
# CLOUD-READY DYNAMIC PATCH GENERATOR
# We dynamically create a .patch file to bypass submodule git errors.
# Buildroot will automatically apply this to QEMU right after extraction.
# =====================================================================
cat << 'EOF' > buildroot/package/qemu/0004-fix-python-distlib.patch
--- a/python/scripts/mkvenv.py
+++ b/python/scripts/mkvenv.py
@@ -496,10 +496,14 @@
         generate_console_scripts(
             ent.values(), dict(dist.exports).get("console_scripts", {})
         )
-
-    maker = distlib.scripts.ScriptMaker(None, bin_path)
-    maker.variants = {""}
-    maker.make("")
+    import os
+    for p in packages:
+        s = os.path.join(bin_path, p)
+        with open(s, "w") as sf:
+            if p == "meson":
+                sf.write('#!/bin/sh\nexec meson "$@"\n')
+            else:
+                sf.write('#!/bin/sh\nexec python3 -m ' + p + ' "$@"\n')
+        os.chmod(s, 0o755)
EOF
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
