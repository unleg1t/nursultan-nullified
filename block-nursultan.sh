#!/usr/bin/env sh
# Null-routes Nursultan's backend in /etc/hosts (needs root).
# The repo jar is already patched; this is optional defense in depth.
set -eu
HOSTS=/etc/hosts
for h in nursultan.fun www.nursultan.fun; do
  if grep -qE "[[:space:]]$h$" "$HOSTS" 2>/dev/null; then
    echo "[=] $h already null-routed"
  else
    echo "0.0.0.0 $h" | sudo tee -a "$HOSTS" >/dev/null
    echo "[+] blocked $h"
  fi
done
echo "To undo, remove those lines from $HOSTS."
