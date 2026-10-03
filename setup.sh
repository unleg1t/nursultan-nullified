#!/usr/bin/env bash
# Sets up the runtime for nursultan-nullified on Linux/macOS.
# Downloads the Minecraft 1.16.5 libraries + Windows natives, the correct
# fastutil, and copies the prebuilt client files into ./libraries.
#
#   ./setup.sh              set up libraries only
#   ./setup.sh --with-jdk   also download a Windows JDK 17 into ./jre (for Wine)
set -euo pipefail
cd "$(dirname "$0")"

VERSION_JSON_URL="https://piston-meta.mojang.com/v1/packages/fba9f7833e858a1257d810d21a3a9e3c967f9077/1.16.5.json"
FASTUTIL="8.5.13"
JDK_URL="https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse"

command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required" >&2; exit 1; }

mkdir -p libraries/libs libraries/natives

echo "==> Minecraft 1.16.5 libraries + Windows natives"
python3 - "$VERSION_JSON_URL" "$FASTUTIL" <<'PY'
import io, json, os, sys, urllib.request, zipfile

ver_url, fastutil = sys.argv[1], sys.argv[2]

def get(url, binary=True):
    req = urllib.request.Request(url, headers={"User-Agent": "nursultan-nullified-setup"})
    return urllib.request.urlopen(req, timeout=180).read()

def allowed(lib):
    rules = lib.get("rules")
    if not rules:
        return True
    ok = False
    for r in rules:
        if r.get("action") == "allow" and r.get("os", {}).get("name") in (None, "windows"):
            ok = True
        if r.get("action") == "disallow" and r.get("os", {}).get("name") == "windows":
            ok = False
    return ok

spec = json.loads(get(ver_url).decode("utf-8"))
for lib in spec["libraries"]:
    if not allowed(lib):
        continue
    d = lib.get("downloads", {})
    art = d.get("artifact")
    if art and art.get("url"):
        p = os.path.join("libraries", "libs", os.path.basename(art["path"]))
        if not os.path.exists(p):
            open(p, "wb").write(get(art["url"]))
    cls = d.get("classifiers", {}).get("natives-windows")
    if cls and cls.get("url"):
        z = zipfile.ZipFile(io.BytesIO(get(cls["url"])))
        for n in z.namelist():
            if n.lower().endswith(".dll"):
                open(os.path.join("libraries", "natives", os.path.basename(n)), "wb").write(z.read(n))

# correct fastutil (8.2.1 ships with 1.16.5 and is too old for this client)
fdst = os.path.join("libraries", "libs", f"fastutil-{fastutil}.jar")
if not os.path.exists(fdst):
    open(fdst, "wb").write(get(f"https://repo1.maven.org/maven2/it/unimi/dsi/fastutil/{fastutil}/fastutil-{fastutil}.jar"))
old = os.path.join("libraries", "libs", "fastutil-8.2.1.jar")
if os.path.exists(old):
    os.remove(old)
print("    libraries:", len(os.listdir(os.path.join("libraries", "libs"))), "jars")
PY

echo "==> copying prebuilt client files"
cp -f prebuilt/libs/*.jar libraries/libs/
cp -f prebuilt/natives/*.dll libraries/natives/

if [ "${1:-}" = "--with-jdk" ]; then
  echo "==> downloading Windows JDK 17 into ./jre"
  python3 - "$JDK_URL" <<'PY'
import io, sys, urllib.request, zipfile
url = sys.argv[1]
z = zipfile.ZipFile(io.BytesIO(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "nursultan-nullified-setup"}), timeout=600).read()))
root = z.namelist()[0].split("/")[0]
import os, shutil
if os.path.exists("jre"):
    shutil.rmtree("jre")
z.extractall("_jdk_tmp")
os.rename(os.path.join("_jdk_tmp", root), "jre")
shutil.rmtree("_jdk_tmp")
for junk in ("jre/src.zip", "jre/jmods"):
    p = os.path.join(".", junk)
    if os.path.isdir(p):
        shutil.rmtree(p)
    elif os.path.exists(p):
        os.remove(p)
# zip extraction drops the exec bit; java.exe must be runnable by path
for name in os.listdir(os.path.join("jre", "bin")):
    p = os.path.join("jre", "bin", name)
    if os.path.isfile(p):
        os.chmod(p, os.stat(p).st_mode | 0o111)
print("    jre ready")
PY
fi

echo
echo "Done. Launch with ./start.sh (Linux/Wine) or start.bat (Windows)."
