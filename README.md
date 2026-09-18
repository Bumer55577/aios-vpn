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

Toolchain: JDK 17, Android SDK (platform 34, build-tools 34.0.0, NDK 26.3),
Qt 6.7.3 (android_arm64_v8a + linux_gcc_64 host, modules: qtremoteobjects,
qt5compat), Conan 2, Ninja.

```sh
git clone --recurse-submodules <this-repo>
cd aios-vpn

# libxray.aar is NOT in the repo (58 MB, gitignored).
# Build/download it per client/android/xray/libXray/build.gradle.kts and place at:
#   client/android/xray/libXray/libxray.aar

export ANDROID_HOME=~/android-sdk
export QT_ROOT_PATH=~/Qt/6.7.3          # the script appends the abi dir itself
export QT_ANDROID_KEYSTORE_PATH=/path/to/your.keystore
export QT_ANDROID_KEYSTORE_STORE_PASS=...
export QT_ANDROID_KEYSTORE_ALIAS=...
./deploy/build.sh -t android --abi arm64-v8a --apk -b /tmp/aiosvpn-build
# APK: /tmp/aiosvpn-build/client/android-build/AIOSVPN.apk
```

Windows installers build via GitHub Actions (`.github/workflows/build-windows.yml`,
workflow_dispatch).

## Secrets policy

- Keystore path/passwords/alias come only from `QT_ANDROID_KEYSTORE_*` env
  vars (`client/android/build.gradle.kts`).
- CI workflows reference GitHub Actions secrets only — no values in the repo.
- No API keys, tokens, or server addresses are hardcoded.

## License

Upstream AmneziaVPN license applies (see LICENSE).
