# AIOS VPN (Android)

Fork of the AmneziaVPN client, rebranded and extended for the AIOS VPN service
(package `ru.aios.vpn`, app name «AIOS VPN»).

## Who this is for

**AIOS VPN is intended for people who have their own servers.** It is not a
public VPN service with shared nodes: the app is a client that connects your
device to **your own VPN server** using an access key (QR code, link or config
file). If you have no server and no key issued to you, there is nothing to
connect to yet.

## Quick start (end users)

**Android:** download the APK from the public rolling release
[aios-apk](https://github.com/Bumer55577/aios-vpn/releases/tag/aios-apk)
(file `AIOSVPN.apk`), install on an Android 9+ device (arm64), open the app →
«Начать» → add the access key (QR / link / file) → press the big gold button.

**Windows:** download the MSI from
[aios-windows](https://github.com/Bumer55577/aios-vpn/releases/tag/aios-windows)
(`AIOSVPN_*_windows_x64.msi`, Windows 10/11 x64), install it (the VPN service is
registered automatically by the installer), open the app → add the access key →
connect. The desktop app uses the same gold/dark UI and features as the mobile
one (profile, devices, subscription, auto-connect), and the Kill Switch toggle
is fully functional on Windows.

Requirements: Android 9.0+ (arm64) or Windows 10/11 (x64), ~150–250 MB free space.

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

## Build

### Windows (x64, MSI installer)

Toolchain: Visual Studio 2022 (MSVC), JDK not required, Qt 6.10.1
(`win64_msvc2022_64`, modules: qtremoteobjects, qt5compat, qtshadertools,
qtimageformats), WiX 4.0.6, Conan 2.

```bat
set QT_INSTALL_DIR=C:\Qt
set WIX_ROOT_PATH=%USERPROFILE%\.dotnet\tools
deploy\build.bat --installer wix
rem MSI: deploy\build\AIOSVPN_*_windows_x64.msi
```

The build produces `AIOSVPN.exe` (client) and `AIOSVPN-service.exe` (VPN
service, registered by the MSI). CI: `.github/workflows/build-windows.yml`
(staged at `deploy/ci/build-windows.yml`), publishes to the `aios-windows`
release.

### Android (arm64-v8a)

Toolchain: JDK 17, Android SDK (platform android-28, NDK 27.0.11718014),
Qt 6.10.1 (android_arm64_v8a + linux_gcc_64 host, modules: qtremoteobjects,
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
export QT_ROOT_PATH=~/Qt/6.10.1         # the script appends the abi dir itself
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
push to `master` (and on demand via workflow_dispatch). Results:
- Actions -> latest run -> Artifacts -> `AIOS-VPN-Android-arm64`;
- the same APK is published to the public rolling release
  [aios-apk](https://github.com/Bumer55577/aios-vpn/releases/tag/aios-apk)
  (file `AIOSVPN.apk`) — direct download without a GitHub login.

`.github/workflows/build-windows.yml` (staged at `deploy/ci/build-windows.yml`;
the deploy key lacks the workflow scope, so activating it is a one-time manual
copy to `.github/workflows/build-windows.yml`) builds the Windows MSI on every
push to `master` and publishes it to the public rolling release
[aios-windows](https://github.com/Bumer55577/aios-vpn/releases/tag/aios-windows).

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
