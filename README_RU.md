# AIOS VPN (Android)

AIOS VPN — мобильный VPN-клиент для Android (пакет `ru.aios.vpn`), построенный
на открытом коде [AmneziaVPN](https://github.com/amnezia-vpn/amnezia-client)
и полностью переработанный: собственный брендинг, тёмная тема с золотом,
упрощённый мастер подключения и интеграция с сервисом AIOS.

[English](README.md) | Русский

## Для кого этот VPN

**AIOS VPN предназначен для тех, у кого есть свои сервера.**

Это не публичный сервис с общими серверами: приложение — клиент, который
подключает ваше устройство к **вашему собственному VPN-серверу** по ключу
доступа (QR-код, ссылка или файл конфигурации). Весь трафик идёт только через
ваш сервер. Если сервера нет и ключ доступа вам никто не выдавал — подключиться
пока не к чему: сначала нужен сервер и выданный на нём ключ.

## Быстрый старт для пользователей

1. Скачайте APK из публичного релиза
   [`aios-apk`](https://github.com/Bumer55577/aios-vpn/releases/tag/aios-apk)
   (файл `AIOSVPN.apk`) — вход в GitHub не требуется.
2. Установите на телефон с Android 9.0+ (arm64), разрешив установку
   «неизвестных приложений», когда Android об этом спросит.
3. Откройте приложение → «Начать» → добавьте ключ доступа (QR-код, ссылка
   или файл).
4. Нажмите большую золотую кнопку на главном экране — когда статус станет
   зелёным («Подключено»), можно пользоваться.

## Возможности

- Тёмная тема «чёрный + золото», собственный мастер первого запуска.
- Подключение одним действием; статус-баннер «Подключено / Вы не подключены»,
  живая статистика трафика.
- Импорт конфигураций: QR-код, ссылка, файл (vless/vmess/AmneziaWG/WireGuard,
  ссылки с токеном VPNPan).
- Интеграция VPNPan: профиль пользователя (имя, срок доступа, счётчик
  устройств «N из M») загружается с сервера по токену из импортированной
  конфигурации; ключи и секреты в интерфейсе никогда не показываются.
- Экран «Устройства»: список привязанных устройств, снятие с учёта
  (мультивыбор галочками).
- Подписка: срок доступа, продление тарифа, баннеры «Подписка истекает».
- Автоподключение к серверу при запуске и открытии приложения (настраивается
  в Профиле → шестерёнка).
- Тихое автоповтор подключения после принудительного завершения сервиса
  (например, после «очистки памяти» в Android).

## Сборка (Android, arm64-v8a)

Полная инструкция на английском — в [README.md](README.md). Кратко:

- Тулечейн: JDK 17, Android SDK (platform android-28, NDK 27.0.11718014),
  Qt 6.10.1 (android_arm64_v8a + host, модули qtremoteobjects, qt5compat,
  qtimageformats, qtshadertools), Conan 2, Ninja. Qt ниже 6.8 не подходит
  (краш на части устройств).
- `libxray.aar` (58 МБ) в репозиторий не входит: положите его в
  `client/android/xray/libXray/libxray.aar` (соберите сами или возьмите из
  релиза с тегом `libxray`).
- CI (`.github/workflows/build-android.yml`) собирает и подписывает APK при
  каждом пуше в `master` и публикует его в релиз `aios-apk`.

```bash
git clone --recurse-submodules https://github.com/Bumer55577/aios-vpn.git
cd aios-vpn

export ANDROID_HOME=~/android-sdk
export QT_ROOT_PATH=~/Qt/6.10.1
export QT_ANDROID_KEYSTORE_PATH=/path/to/your.keystore
export QT_ANDROID_KEYSTORE_STORE_PASS=...
export QT_ANDROID_KEYSTORE_ALIAS=...
./deploy/build.sh -t android --abi arm64-v8a --apk -b /tmp/aiosvpn-build
# APK: /tmp/aiosvpn-build/client/android-build/AIOSVPN.apk
```

## Технологии

Проект использует компоненты с открытым исходным кодом:

- [Qt](https://www.qt.io/)
- [OpenSSL](https://www.openssl.org/)
- [WireGuard](https://www.wireguard.com/)
- [Xray-core](https://xtls.github.io/en/)
- [Conan](https://conan.io/)
- и другие — полный список в `THIRD_PARTY_LICENSES.md`.

## Лицензия

GPL v3.0 (см. `LICENSE`). Форк основан на AmneziaVPN — состав сторонних
компонентов и их лицензии в `THIRD_PARTY_LICENSES.md`.
