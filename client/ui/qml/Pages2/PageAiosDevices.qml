import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

PageType {
    id: root

    // Выбранные для отвязки HWID
    property var selectedHwids: []

    function isSelected(hwid) {
        return selectedHwids.indexOf(hwid) !== -1
    }

    function toggleSelection(hwid) {
        var next = selectedHwids.slice()
        var i = next.indexOf(hwid)
        if (i !== -1) {
            next.splice(i, 1)
        } else {
            next.push(hwid)
        }
        selectedHwids = next
    }

    function clearSelection() {
        selectedHwids = []
    }

    function selectedNames() {
        var names = []
        var devices = AiosDevicesController.devices
        for (var i = 0; i < devices.length; i++) {
            if (isSelected(devices[i].hwid)) {
                names.push("«" + devices[i].name + "»")
            }
        }
        return names.join(", ")
    }

    function includesCurrent() {
        return isSelected(AiosDevicesController.myHwid())
    }

    function isDesktopPlatform(platform) {
        var p = (platform || "").toLowerCase()
        return p.indexOf("mac") !== -1 || p.indexOf("windows") !== -1
               || p.indexOf("linux") !== -1 || p.indexOf("pc") !== -1
               || p.indexOf("desktop") !== -1
    }

    function confirmUnlink() {
        var list = []
        for (var i = 0; i < selectedHwids.length; i++) {
            list.push(selectedHwids[i])
        }
        AiosDevicesController.revokeMany(list)
    }

    // Профиль может отсутствовать — тогда счётчики из профиля недоступны
    readonly property bool hasProfileInfo: AiosProfileController.hasProfile

    Component.onCompleted: {
        AiosDevicesController.refresh()
        AiosProfileController.refresh()
    }

    Connections {
        target: AiosDevicesController
        function onRevokeFinished(okCount, failCount, includesThisDevice, lastError) {
            root.clearSelection()
            AiosProfileController.refresh()
            if (okCount > 0 && failCount === 0) {
                PageController.showNotificationMessage(okCount === 1
                    ? qsTr("Устройство отвязано. Слот освобождён для нового устройства.")
                    : qsTr("Отвязано устройств: %1").arg(okCount))
            } else if (okCount > 0 && failCount > 0) {
                PageController.showNotificationMessage(qsTr("Отвязаны не все устройства. Попробуйте позже."))
            } else if (failCount > 0) {
                PageController.showNotificationMessage(qsTr("Не удалось отвязать устройства. Попробуйте позже."))
            }
            if (includesThisDevice) {
                PageController.showNotificationMessage(qsTr("Текущее устройство отвязано — при смене ключей добавьте доступ заново."))
            }
        }
    }

    // Подэкран профиля: список устройств подписки
    BackButtonType {
        id: backButton

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 20 + PageController.safeAreaTopMargin
    }

    BaseHeaderType {
        id: headerTitle

        anchors.top: backButton.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        headerText: qsTr("Устройства")
    }

    FlickableType {
        id: flickable

        anchors.top: headerTitle.bottom
        anchors.bottom: parent.bottom

        contentHeight: content.height

        ColumnLayout {
            id: content

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            // Счётчики слотов
            Rectangle {
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                width: parent.width - 32
                height: countersRow.implicitHeight + 24
                radius: 16

                color: '#101015'
                border.color: '#2A2A2F'
                border.width: 1

                RowLayout {
                    id: countersRow

                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: root.hasProfileInfo
                                  ? AiosProfileController.devicesUsed + " " + qsTr("из") + " " + AiosProfileController.devicesTotal
                                  : ServersModel.rowCount() !== 0 ? "1 " + qsTr("из") + " 5"
                                                                  : qsTr("Без ограничений")
                            color: '#F0EAD9'
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: qsTr("Слоты подписки AIOS")
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        visible: root.hasProfileInfo || ServersModel.rowCount() !== 0
                        radius: 12
                        color: Qt.rgba(230/255, 182/255, 76/255, 0.12)
                        border.color: Qt.rgba(230/255, 182/255, 76/255, 0.4)
                        width: limitText.implicitWidth + 20
                        height: limitText.implicitHeight + 8

                        Text {
                            id: limitText
                            anchors.centerIn: parent
                            text: root.hasProfileInfo
                                  ? qsTr("Лимит") + " " + AiosProfileController.devicesTotal
                                  : qsTr("Лимит") + " 5"
                            color: '#E6B64C'
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Text {
                visible: AiosDevicesController.supported && !AiosDevicesController.loading && AiosDevicesController.devices.length > 0
                Layout.topMargin: 12
                Layout.leftMargin: 20
                Layout.rightMargin: 16

                text: qsTr("Отметьте устройства, которые нужно отвязать, и нажмите кнопку внизу.")
                color: '#8E8E93'
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            // Список устройств
            ColumnLayout {
                id: devicesList

                visible: AiosDevicesController.supported && !AiosDevicesController.loading && AiosDevicesController.devices.length > 0

                Layout.topMargin: 12
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                width: parent.width - 32
                spacing: 12

                Repeater {
                    model: AiosDevicesController.devices

                    delegate: Rectangle {
                        id: deviceCard

                        required property var modelData

                        property bool isCurrent: modelData.hwid === AiosDevicesController.myHwid()
                        property bool isSelected: root.isSelected(modelData.hwid)

                        Layout.fillWidth: true
                        implicitHeight: deviceRow.implicitHeight + 28

                        radius: 16
                        color: isSelected ? Qt.rgba(230/255, 182/255, 76/255, 0.08) : '#101015'
                        border.color: isSelected ? Qt.rgba(230/255, 182/255, 76/255, 0.5) : '#2A2A2F'
                        border.width: 1

                        RowLayout {
                            id: deviceRow

                            anchors.fill: parent
                            anchors.margins: 14
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            spacing: 14

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 12
                                color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.24)

                                Image {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    source: root.isDesktopPlatform(modelData.platform)
                                            ? "qrc:/images/controls/monitor.svg"
                                            : "qrc:/images/controls/smartphone.svg"
                                    mipmap: true
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: 8
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        color: '#F0EAD9'
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        id: currentBadge
                                        visible: deviceCard.isCurrent
                                        radius: 8
                                        color: Qt.rgba(61/255, 220/255, 132/255, 0.12)
                                        border.color: Qt.rgba(61/255, 220/255, 132/255, 0.3)
                                        width: currentBadgeText.implicitWidth + 16
                                        height: currentBadgeText.implicitHeight + 6

                                        Text {
                                            id: currentBadgeText
                                            anchors.centerIn: parent
                                            text: qsTr("Это устройство")
                                            color: '#A7F3C9'
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.platform
                                          + (modelData.addedAt !== "" ? " · " + qsTr("с") + " " + modelData.addedAt : "")
                                    color: '#8E8E93'
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Чекбокс выбора
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: deviceCard.isSelected ? '#E6B64C' : "transparent"
                                border.color: deviceCard.isSelected ? '#E6B64C' : Qt.rgba(230/255, 182/255, 76/255, 0.4)

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: '#060609'
                                    font.pixelSize: 13
                                    font.bold: true
                                    visible: deviceCard.isSelected
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleSelection(modelData.hwid)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    text: qsTr("Отвязка освобождает слот: устройство потеряет доступ при следующем обновлении ключей. Если отвязать текущее устройство — при смене ключей потребуется заново добавить доступ (например, на новом телефоне или Mac).")
                    color: '#8E8E93'
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }

            // AIOS: локальная конфигурация (без токена панели) — показываем это
            // устройство и возможность отвязать его (удалив доступ из приложения)
            ColumnLayout {
                id: localDeviceFallback

                visible: ServersModel.rowCount() !== 0 && !AiosDevicesController.supported && !AiosDevicesController.loading

                Layout.topMargin: 12
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                width: parent.width - 32
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: localDeviceRow.implicitHeight + 28

                    radius: 16
                    color: '#101015'
                    border.color: '#2A2A2F'
                    border.width: 1

                    RowLayout {
                        id: localDeviceRow

                        anchors.fill: parent
                        anchors.margins: 14
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        spacing: 14

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 12
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.24)

                            Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                source: "qrc:/images/controls/smartphone.svg"
                                mipmap: true
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true

                                Text {
                                    text: qsTr("Это устройство")
                                    color: '#F0EAD9'
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    radius: 8
                                    color: Qt.rgba(61/255, 220/255, 132/255, 0.12)
                                    border.color: Qt.rgba(61/255, 220/255, 132/255, 0.3)
                                    width: localBadgeText.implicitWidth + 16
                                    height: localBadgeText.implicitHeight + 6

                                    Text {
                                        id: localBadgeText
                                        anchors.centerIn: parent
                                        text: qsTr("Подключено к серверу")
                                        color: '#A7F3C9'
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Text {
                                text: "Android · " + qsTr("занимает 1 слот из 5")
                                color: '#8E8E93'
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true

                    text: qsTr("Управление списком устройств доступно для доступа по токену. Чтобы освободить слот на этом устройстве, отвяжите его — доступ будет удалён и его можно будет добавить на другом телефоне.")
                    color: '#8E8E93'
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }

                BasicButtonType {
                    id: localUnlinkButton

                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    implicitHeight: 44

                    defaultColor: Qt.rgba(255/255, 255/255, 255/255, 0.04)
                    hoveredColor: Qt.rgba(255/255, 255/255, 255/255, 0.07)
                    pressedColor: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                    textColor: '#F0858A'
                    borderColor: Qt.rgba(229/255, 72/255, 77/255, 0.2)
                    borderWidth: 1

                    buttonTextLabel.font.pixelSize: 13

                    text: qsTr("Отвязать это устройство")

                    clickedFunc: function() {
                        localUnlinkDrawer.openTriggered()
                    }
                }
            }

            // Пустые состояния
            ColumnLayout {
                visible: !AiosDevicesController.loading && !localDeviceFallback.visible
                         && (AiosDevicesController.error !== "" || AiosDevicesController.devices.length === 0)

                Layout.topMargin: 24
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                width: parent.width - 32
                spacing: 8

                Text {
                    Layout.fillWidth: true

                    text: {
                        if (!AiosDevicesController.supported) {
                            return ServersModel.rowCount() === 0
                                    ? qsTr("Доступ не добавлен")
                                    : qsTr("Панель не поддерживает список устройств")
                        }
                        if (AiosDevicesController.error !== "") {
                            return qsTr("Не удалось загрузить устройства")
                        }
                        return qsTr("Пока нет устройств")
                    }
                    color: '#F0EAD9'
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true

                    text: {
                        if (!AiosDevicesController.supported) {
                            return ServersModel.rowCount() === 0
                                    ? qsTr("Добавьте доступ по токену, чтобы видеть устройства подписки.")
                                    : qsTr("Просмотр и отвязка доступны в панели VPNPan. Лимит берётся из профиля: это устройство занимает слот автоматически.")
                        }
                        if (AiosDevicesController.error !== "") {
                            return AiosDevicesController.error
                        }
                        return qsTr("Устройство появится в списке после первого подключения.")
                    }
                    color: '#8E8E93'
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                BasicButtonType {
                    id: retryButton

                    visible: AiosDevicesController.error !== "" && AiosDevicesController.supported
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8

                    implicitHeight: 36

                    defaultColor: Qt.rgba(230/255, 182/255, 76/255, 0.12)
                    hoveredColor: Qt.rgba(230/255, 182/255, 76/255, 0.2)
                    pressedColor: Qt.rgba(230/255, 182/255, 76/255, 0.28)
                    textColor: '#E6B64C'
                    borderWidth: 1
                    borderColor: Qt.rgba(230/255, 182/255, 76/255, 0.4)

                    text: qsTr("Повторить")
                    clickedFunc: function() {
                        AiosDevicesController.refresh()
                    }
                }
            }

            Item {
                // отступ под нижнюю панель действий
                Layout.fillWidth: true
                Layout.preferredHeight: 140
            }
        }
    }

    BusyIndicatorType {
        anchors.centerIn: parent
        // AIOS: BusyIndicatorType — Popup, свойства running нет;
        // открытие/закрытие только через visible
        visible: AiosDevicesController.loading
    }

    // Нижняя панель действий
    Rectangle {
        id: actionBar

        visible: root.selectedHwids.length > 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        anchors.bottomMargin: 16 + PageController.safeAreaBottomMargin

        height: actionBarRow.implicitHeight + 20
        radius: 16

        color: '#0E0E12'
        border.color: Qt.rgba(230/255, 182/255, 76/255, 0.28)
        border.width: 1

        RowLayout {
            id: actionBarRow

            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            spacing: 10

            BasicButtonType {
                id: clearButton

                implicitHeight: 40

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                textColor: '#8E8E93'
                borderWidth: 0

                text: qsTr("Снять")
                clickedFunc: function() {
                    root.clearSelection()
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Выбрано:") + " " + root.selectedHwids.length
                    color: '#F4D98B'
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                Text {
                    visible: root.includesCurrent()
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("в т.ч. это устройство")
                    color: '#8E8E93'
                    font.pixelSize: 10
                }
            }

            BasicButtonType {
                id: unlinkButton

                implicitHeight: 40

                defaultColor: '#E5484D'
                hoveredColor: '#F05A5F'
                pressedColor: '#C9383D'
                textColor: '#FFFFFF'
                borderWidth: 0

                text: qsTr("Отвязать")
                clickedFunc: function() {
                    confirmDrawer.openTriggered()
                }
            }
        }
    }

    // Подтверждение отвязки
    DrawerType2 {
        id: confirmDrawer

        anchors.fill: parent
        expandedHeight: parent.height * 0.5

        expandedStateContent: ColumnLayout {
            id: confirmContent

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            implicitHeight: confirmDrawer.expandedHeight

            spacing: 16

            Item {
                Layout.preferredHeight: 4
            }

            Text {
                Layout.fillWidth: true

                text: root.selectedHwids.length === 1
                      ? qsTr("Отвязать устройство?")
                      : qsTr("Отвязать устройства (%1)?").arg(root.selectedHwids.length)
                color: '#F0EAD9'
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true

                text: {
                    var base = root.selectedNames() + " " +
                        (root.selectedHwids.length === 1
                            ? qsTr("потеряет доступ к серверу, слот освободится — на его место можно зарегистрировать другое устройство.")
                            : qsTr("потеряют доступ к серверу, слоты освободятся — на их место можно зарегистрировать другие устройства."))
                    return base
                }
                color: '#8E8E93'
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                visible: root.includesCurrent()

                Layout.fillWidth: true

                text: qsTr("Среди выбранных — текущее устройство: после отвязки при смене ключей потребуется заново добавить доступ.")
                color: '#F4D98B'
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8

                spacing: 12

                BasicButtonType {
                    id: cancelButton

                    Layout.fillWidth: true
                    implicitHeight: 44

                    defaultColor: AmneziaStyle.color.transparent
                    hoveredColor: AmneziaStyle.color.translucentWhite
                    pressedColor: AmneziaStyle.color.sheerWhite
                    textColor: '#F0EAD9'
                    borderWidth: 1
                    borderColor: '#2A2A2F'

                    text: qsTr("Отмена")
                    clickedFunc: function() {
                        confirmDrawer.closeTriggered()
                    }
                }

                BasicButtonType {
                    id: confirmButton

                    Layout.fillWidth: true
                    implicitHeight: 44

                    defaultColor: '#E5484D'
                    hoveredColor: '#F05A5F'
                    pressedColor: '#C9383D'
                    textColor: '#FFFFFF'
                    borderWidth: 0

                    text: qsTr("Отвязать")
                    clickedFunc: function() {
                        confirmDrawer.closeTriggered()
                        root.confirmUnlink()
                    }
                }
            }
        }
    }

    // AIOS: подтверждение отвязки для локальной конфигурации (без панели)
    QuestionDrawer {
        id: localUnlinkDrawer

        headerText: qsTr("Отвязать это устройство?")
        descriptionText: qsTr("Доступ будет удалён с этого устройства, слот освободится. Чтобы вернуть VPN, добавьте доступ заново по QR-коду, ссылке или файлу.")
        yesButtonText: qsTr("Отвязать")
        noButtonText: qsTr("Отмена")

        yesButtonFunction: function() {
            if (ConnectionController.isConnected || ConnectionController.isConnectionInProgress) {
                PageController.showNotificationMessage(qsTr("Нельзя отвязывать устройство во время подключения"))
                return
            }
            PageController.showBusyIndicator(true)
            InstallController.removeServer(ServersUiController.defaultServerId)
            PageController.showBusyIndicator(false)
        }
        noButtonFunction: function() {
        }
    }
}
