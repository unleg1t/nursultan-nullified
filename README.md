# nursultan-nullified

An **offline-capable, backend-nullified** repack of the Nursultan Minecraft
1.16.5 client. All references to the client's backend (`nursultan.fun` and its
VK page) have been severed in the bytecode, and the missing dependencies are
provided so the client runs without internet access.

> Educational / testing purposes only. See [DISCLAIMER.md](DISCLAIMER.md).

## What was changed

- `nursultan.jar` is built from the original clean (obfuscated) client with the
  pause-menu constants neutralized (`case/KW.class`):
  - `nursultan.fun` → `0.0.0.0`
  - `https://vk.com/nursultanclientn` → `https://0.0.0.0/`
  - No other plaintext phone-home exists in the jar (the `/api/...` strings are
    Baritone/ViaVersion).
- `fastutil-8.2.1` (shipped with MC 1.16.5) is replaced with **`8.5.13`** - the
  client calls `Int2ObjectMap.computeIfAbsent(int, Int2ObjectFunction)`, which
  does not exist in 8.2.1.
- The full Minecraft 1.16.5 Windows library set + natives are fetched by the
  setup script (they were not bundled with the client).

## Requirements

- **Windows 10/11** or **Linux/macOS + Wine** (the client and its natives are
  Windows-only).
- A **JDK 17** (or newer) - the setup script can download a Windows JDK 17 for
  Wine users.

## Quick start

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -WithJdk
.\start.bat
```

`-WithJdk` is optional if you already have a JDK 17 on `PATH`. If you prefer,
`.\setup.ps1` (without it) will use your system `java`.

### Linux / macOS (Wine)

```sh
./setup.sh --with-jdk
./start.sh
```

`wine` must be installed. `--with-jdk` downloads a Windows JDK 17 into `./jre`,
which `start.sh` uses automatically. Skip it and set `JAVA_WIN=/path/to/java.exe`
if you already have one.

## Manual setup

If you would rather not run the setup scripts:

1. Install a JDK 17 that runs on your platform (Windows) or in Wine (Linux/macOS).
2. Put the Minecraft **1.16.5** libraries into `libraries/libs/` and the
   `natives-windows` DLLs into `libraries/natives/`. The easiest source is the
   official version JSON:
   `https://piston-meta.mojang.com/v1/packages/fba9f7833e858a1257d810d21a3a9e3c967f9077/1.16.5.json`
3. Add `fastutil-8.5.13.jar` to `libraries/libs/` and delete `fastutil-8.2.1.jar`.
4. Copy `prebuilt/libs/*.jar` into `libraries/libs/` and
   `prebuilt/natives/*.dll` into `libraries/natives/`.
5. Launch (Windows):
   ```
   java -XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal ^
     -Xmx2G -Djava.library.path="libraries/natives" ^
     -cp "nursultan.jar;libraries/libs/*" we.are.sk3d.Launcher
   ```

## Layout

```
nursultan.jar            nullified client
prebuilt/libs/           client-only jars (viaversion, discord-rpc, ...)
prebuilt/natives/        client native DLLs (Nursultan.dll, naebalovo.dll, ...)
setup.sh / setup.ps1     download MC 1.16.5 libs + natives (+ optional JDK)
start.sh / start.bat     launchers
block-nursultan.sh/.bat  optional hosts null-route for nursultan.fun
libraries/               generated at setup time (gitignored)
jre/                     optional Windows JDK 17 (gitignored)
```

## Why these JVM flags

The client's obfuscated classes use bytecode that fails the strict verifier, so
it must run with verification disabled:

```
-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal
```

The launcher also starts the game offline (`--accessToken null --username
Sk3d.club`), so no Mojang login is required.

## Troubleshooting

- **`NoClassDefFoundError: joptsimple/OptionSpec`** - libraries are missing.
  Run the setup script.
- **`NoSuchMethodError: ... fastutil ... computeIfAbsent`** - `fastutil-8.2.1`
  is still on the classpath. Delete it and keep `8.5.13`.
- **`VerifyError` / JVM fatal error** - you are using the wrong jar. This repo
  ships the correct (`nursultan-obf.jar`-derived) build, which is clean. Do not
  use the older broken jar.
- **`wine: command not found`** - install Wine, or use Windows.
- Cosmetic console warnings about the missing asset index, icon, or sounds are
  harmless (the jar ships textures/models but not the sound files).

## Optional hard block

`nursultan.jar` is already patched, but you can also null-route the domain at
the OS level:

```
./block-nursultan.sh      # Linux (needs root)
block-nursultan.bat       # Windows, run as Administrator
```
