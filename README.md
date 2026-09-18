# AIOS VPN (Android)

Fork of the AmneziaVPN client, rebranded and extended for the AIOS VPN service
(package `ru.aios.vpn`, app name «AIOS VPN»).

## What changed vs upstream (amnezia-vpn/amnezia-client)

- Rebranding: package id `ru.aios.vpn`, app label «AIOS VPN», gold/black design
  per the AIOS design references (start screen, home screen, profile).
- Custom app icons (`client/android/res/mipmap-*`) and gold tile icon.
- Start screen `client/ui/qml/Pages2/PageSetupWizardStart.qml` — AIOS design
  (logo, slogan, planet art, feature tiles, «Начать» button).
- `PageHome` — status banner (yellow offline / green connected) per reference.
- Setup wizard reduced: config import is QR-scan or config-file only.
- VPNPan integration: an imported config may carry a `# AIOS: token=...`
  comment; `AiosProfileController` (`client/ui/controllers/aiosProfileController.*`)
  then loads the user profile (name, devices, expiry) from the VPNPan API
  (`/api/profile/<token>`, deployed behind TLS on the VPN server, port 8765).
  No keys/secrets are ever shown in the UI.

## Build (Android, arm64-v8a)

Toolchain: JDK 17, Android SDK (platform android-28, NDK 27.0.11718014),
Qt 6.10.3 (android_arm64_v8a + linux_gcc_64 host, modules: qtremoteobjects,
qt5compat, qtimageformats, qtshadertools), Conan 2, Ninja.
NOTE: Qt >= 6.8 is required — 6.7.3 lacks popupType/ContextMenu support and
caused a startup crash on low-end devices (e.g. Redmi 12C).

```sh
git clone --recurse-submodules <this-repo>
cd aios-vpn

# libxray.aar is NOT in the repo (58 MB, gitignored).
# Build/download it per client/android/xray/libXray/build.gradle.kts and place at:
#   client/android/xray/libXray/libxray.aar

export ANDROID_HOME=~/android-sdk
export QT_ROOT_PATH=~/Qt/6.10.3         # the script appends the abi dir itself
export QT_ANDROID_KEYSTORE_PATH=/path/to/your.keystore
export QT_ANDROID_KEYSTORE_STORE_PASS=...
export QT_ANDROID_KEYSTORE_ALIAS=...
./deploy/build.sh -t android --abi arm64-v8a --apk -b /tmp/aiosvpn-build
# APK: /tmp/aiosvpn-build/client/android-build/AIOSVPN.apk
```

Windows installers build via GitHub Actions (`.github/workflows/build-windows.yml`,
workflow_dispatch).

## CI (autobuild APK)

`.github/workflows/build-android.yml` builds a signed arm64-v8a APK on every
push to `master` (and on demand via workflow_dispatch). Result: Actions ->
latest run -> Artifacts -> `AIOS-VPN-Android-arm64`.

One-time manual step — `libxray.aar` is not stored in the repo (58 MB):

1. Releases -> Draft a new release -> tag **`libxray`**
2. Attach your local `libxray.aar` (the file you already use for local builds)
3. Publish

Signing: if secrets `QT_ANDROID_KEYSTORE_BASE64`, `QT_ANDROID_KEYSTORE_STORE_PASS`,
`QT_ANDROID_KEYSTORE_ALIAS` are set, your release keystore is used. Otherwise
the workflow generates a personal keystore and caches it between runs
(`aios-signing-keystore-v1` cache entry).

## Permissions (single-dialog setup)

The user sees exactly ONE system dialog during install + first connect —
the VpnService consent (mandatory by Android). Notification permission is
never proactively requested (the VPN key icon is visible without it and the
foreground service runs fine); camera and file access are contextual, asked
only when the user actually scans a QR code / imports a restricted file.

## Secrets policy

- Keystore path/passwords/alias come only from `QT_ANDROID_KEYSTORE_*` env
  vars (`client/android/build.gradle.kts`).
- CI workflows reference GitHub Actions secrets only — no values in the repo.
- No API keys, tokens, or server addresses are hardcoded.

## License

Upstream AmneziaVPN license applies (see LICENSE).
