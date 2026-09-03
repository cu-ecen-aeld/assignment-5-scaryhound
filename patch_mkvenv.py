file_path = "/home/ubunutu/assignment-5-scaryhound/buildroot/output/build/host-qemu-8.1.1/python/scripts/mkvenv.py"

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
            f.write('                sf.write(\'#!/bin/sh\\nexec /home/ubunutu/assignment-5-scaryhound/buildroot/output/host/bin/meson "$@"\\n\')\n')
            f.write('            else:\n')
            f.write('                sf.write(\'#!/bin/sh\\nexec python3 -m \' + p + \' "$@"\\n\')\n')
            f.write('        os.chmod(s, 0o755)\n')
            f.write('    return\n')
        f.write(line)
print("Auto-patch applied successfully!")
