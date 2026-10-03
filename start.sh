#!/usr/bin/env sh
# Launches the Nursultan client on Linux/macOS through Wine.
#
# The client is a Windows build: it needs a Windows JVM under Wine.
# Run ./setup.sh --with-jdk first (or set JAVA_WIN to your own java.exe).
#
# Windows java.exe resolution: $JAVA_WIN > ./jre > java.exe on the Wine PATH
set -eu
cd "$(dirname "$0")" || exit 1

if [ ! -d libraries/libs ]; then
  echo "[!] Libraries are missing. Run ./setup.sh first." >&2
  exit 1
fi

if ! command -v wine >/dev/null 2>&1; then
  echo "[!] wine not found. Install Wine, or run start.bat on Windows." >&2
  exit 1
fi

if [ -n "${JAVA_WIN:-}" ]; then
  JAVA="$JAVA_WIN"
elif [ -x "./jre/bin/java.exe" ]; then
  JAVA="$(pwd)/jre/bin/java.exe"
else
  JAVA="java.exe"
fi

exec wine "$JAVA" \
  -XX:+UnlockDiagnosticVMOptions \
  -XX:-BytecodeVerificationRemote \
  -XX:-BytecodeVerificationLocal \
  -Xmx2G \
  -Djava.library.path="libraries/natives" \
  -cp "nursultan.jar;libraries/libs/*" \
  we.are.sk3d.Launcher "$@"
