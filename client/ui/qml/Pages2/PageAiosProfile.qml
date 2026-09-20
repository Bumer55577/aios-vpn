import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

// AIOS: экран «Профиль» по референсу — личный кабинет, план, устройства,
// настройки защиты, выход. Подэкраны: Устройства (PageAiosDevices).
PageType {
    id: root

    readonly property bool isExpired: AiosProfileController.hasProfile && AiosProfileController.expired
    readonly property bool hasServer: ServersModel.rowCount() !== 0

    property int daysLeft: {
        if (!AiosProfileController.hasProfile) return -1
        var s = AiosProfileController.expires
        if (!s) return -1
        var t = Date.parse(s)
        if (isNaN(t)) {
            var m = s.match(/^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})/)
            if (m) t = new Date(parseInt(m[3], 10), parseInt(m[2], 10) - 1, parseInt(m[1], 10)).getTime()
        }
        if (isNaN(t)) return -1
        return Math.max(0, Math.ceil((t - Date.now()) / 86400000))
    }

    Component.onCompleted: AiosProfileController.refresh()

    Connections {
        target: ServersUiController
        function onDefaultServerIdChanged() {
            AiosProfileController.refresh()
        }
    }

    FlickableType {
        id: flickable
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        contentHeight: contentColumn.implicitHeight + contentColumn.anchors.topMargin

        ColumnLayout {
            id: contentColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 20 + PageController.safeAreaTopMargin

            spacing: 0

            // Шапка: «Профиль» + кнопка настроек
            RowLayout {
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                Text {
                    text: qsTr("Профиль")
                    color: '#F3EEE1'
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: '#101015'
                    border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/images/controls/settings.svg"
                        sourceSize.width: 17
                        sourceSize.height: 17
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: '#D7D8DB' }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsDrawer.openTriggered()
                    }
                }
            }

            // Карточка личности
            Rectangle {
                Layout.topMargin: 20
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: 104

                radius: 24
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    spacing: 16

                    // Аватар: первая буква имени, золотая
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64

                        radius: 32
                        color: '#17171D'
                        border.color: Qt.rgba(230/255, 182/255, 76/255, 0.5)
                        border.width: 2

                        Text {
                            anchors.centerIn: parent

                            text: {
                                var n = AiosProfileController.owner
                                if (!n || n.length === 0) return "Г"
                                return n.substring(0, 1).toUpperCase()
                            }
                            color: '#E6B64C'
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 4

                        RowLayout {
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: AiosProfileController.owner !== "" ? AiosProfileController.owner : qsTr("Гость")
                                color: '#F3EEE1'
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            // PRO-бейдж
                            Rectangle {
                                visible: AiosProfileController.hasProfile

                                implicitWidth: proText.implicitWidth + 16
                                implicitHeight: proText.implicitHeight + 6
                                radius: height / 2

                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0; color: '#F4D98B' }
                                    GradientStop { position: 1; color: '#C9962E' }
                                }

                                Text {
                                    id: proText
                                    anchors.centerIn: parent

                                    text: "PRO"
                                    color: '#231806'
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true

                            text: AiosProfileController.hasProfile
                                  ? qsTr("Доступ до ") + AiosProfileController.expires
                                  : qsTr("Доступ не добавлен")
                            color: '#98917F'
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Секция «Мой план»
            Text {
                Layout.topMargin: 24
                Layout.leftMargin: 21
                Layout.rightMargin: 20

                text: qsTr("Мой план").toUpperCase()
                color: Qt.rgba(152/255, 145/255, 127/255, 0.7)
                font.pixelSize: 11
                font.letterSpacing: 2
            }

            Rectangle {
                Layout.topMargin: 10
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: planInner.implicitHeight + 40

                radius: 24
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                ColumnLayout {
                    id: planInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20

                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40

                            radius: 12
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.2)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/images/controls/credit-card.svg"
                                sourceSize.width: 19
                                sourceSize.height: 19
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 3

                            Text {
                                Layout.fillWidth: true

                                text: AiosProfileController.hasProfile ? qsTr("AIOS VPN") : qsTr("Без тарифа")
                                color: '#F3EEE1'
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                spacing: 5

                                Image {
                                    source: "qrc:/images/controls/calendar.svg"
                                    sourceSize.width: 13
                                    sourceSize.height: 13
                                    layer.enabled: true
                                    layer.effect: ColorOverlay { color: '#98917F' }
                                }

                                Text {
                                    text: AiosProfileController.hasProfile
                                          ? qsTr("Доступ до ") + AiosProfileController.expires
                                          : qsTr("Срок доступа не ограничен")
                                    color: '#98917F'
                                    font.pixelSize: 12
                                }
                            }
                        }

                        // Плашка «Осталось N дн.» / «Истёк»
                        Rectangle {
                            visible: AiosProfileController.hasProfile

                            implicitWidth: planBadgeText.implicitWidth + 20
                            implicitHeight: planBadgeText.implicitHeight + 10
                            radius: height / 2

                            color: root.isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.1)
                                                  : root.daysLeft <= 7 ? Qt.rgba(230/255, 182/255, 76/255, 0.1)
                                                                       : Qt.rgba(61/255, 220/255, 132/255, 0.08)
                            border.color: root.isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.3)
                                                         : root.daysLeft <= 7 ? Qt.rgba(230/255, 182/255, 76/255, 0.3)
                                                                              : Qt.rgba(61/255, 220/255, 132/255, 0.25)
                            border.width: 1

                            Text {
                                id: planBadgeText
                                anchors.centerIn: parent

                                text: root.isExpired ? qsTr("Истёк") : qsTr("Осталось ") + root.daysLeft + qsTr(" дн.")
                                color: root.isExpired ? '#F0858A' : root.daysLeft <= 7 ? '#F4D98B' : '#A7F3C9'
                                font.pixelSize: 10.5
                            }
                        }
                    }

                    BasicButtonType {
                        id: renewButton

                        visible: root.hasServer

                        Layout.topMargin: 16
                        Layout.fillWidth: true

                        implicitHeight: 44

                        defaultColor: '#E6B64C'
                        hoveredColor: '#F4D98B'
                        pressedColor: '#C9962E'
                        textColor: '#231806'
                        borderWidth: 0

                        buttonTextLabel.font.pixelSize: 13.5
                        buttonTextLabel.font.weight: Font.DemiBold

                        text: root.isExpired ? qsTr("Продлить доступ") : qsTr("Продлить тариф")

                        clickedFunc: function() {
                            renewDrawer.openTriggered()
                        }
                    }
                }
            }

            // Секция «Устройства»
            Text {
                Layout.topMargin: 24
                Layout.leftMargin: 21
                Layout.rightMargin: 20

                text: qsTr("Устройства").toUpperCase()
                color: Qt.rgba(152/255, 145/255, 127/255, 0.7)
                font.pixelSize: 11
                font.letterSpacing: 2
            }

            Rectangle {
                Layout.topMargin: 10
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: devicesInner.implicitHeight + 40

                radius: 24
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                TapHandler {
                    onTapped: PageController.goToPage(PageEnum.PageAiosDevices)
                }

                ColumnLayout {
                    id: devicesInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20

                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40

                            radius: 12
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.2)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/images/controls/smartphone.svg"
                                sourceSize.width: 19
                                sourceSize.height: 19
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 3

                            Text {
                                text: AiosProfileController.hasProfile
                                      ? AiosProfileController.devicesUsed + " " + qsTr("из") + " " + AiosProfileController.devicesTotal
                                      : qsTr("Без ограничений")
                                color: '#F3EEE1'
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true

                                text: AiosProfileController.hasProfile
                                      ? qsTr("Сменили телефон или ПК? Отвяжите старое устройство")
                                      : qsTr("Добавьте доступ, чтобы увидеть лимит")
                                color: '#98917F'
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Золотая плашка «Управлять»
                        Rectangle {
                            visible: AiosProfileController.hasProfile

                            implicitWidth: manageText.implicitWidth + 20
                            implicitHeight: manageText.implicitHeight + 10
                            radius: height / 2

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0; color: '#F4D98B' }
                                GradientStop { position: 1; color: '#C9962E' }
                            }

                            Text {
                                id: manageText
                                anchors.centerIn: parent

                                text: qsTr("Управлять")
                                color: '#231806'
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        Image {
                            source: "qrc:/images/controls/chevron-right.svg"
                            sourceSize.width: 16
                            sourceSize.height: 16
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: Qt.rgba(152/255, 145/255, 127/255, 0.6) }
                        }
                    }
                }
            }

            // Секция «О приложении»
            Text {
                Layout.topMargin: 24
                Layout.leftMargin: 21
                Layout.rightMargin: 20

                text: qsTr("О приложении").toUpperCase()
                color: Qt.rgba(152/255, 145/255, 127/255, 0.7)
                font.pixelSize: 11
                font.letterSpacing: 2
            }

            Rectangle {
                Layout.topMargin: 10
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: 56

                radius: 24
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    Text {
                        text: "AIOS VPN"
                        color: '#E9E2D2'
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: SettingsController.getAppVersion()
                        color: '#98917F'
                        font.pixelSize: 12
                        font.family: "PT Root UI VF"
                    }
                }
            }

            // Кнопка «Выйти»
            BasicButtonType {
                id: logoutButton

                Layout.topMargin: 28
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 24
                Layout.fillWidth: true

                implicitHeight: 48

                defaultColor: Qt.rgba(255/255, 255/255, 255/255, 0.04)
                hoveredColor: Qt.rgba(255/255, 255/255, 255/255, 0.07)
                pressedColor: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                textColor: '#F3EEE1'
                borderColor: Qt.rgba(230/255, 182/255, 76/255, 0.25)
                borderWidth: 1

                text: qsTr("Выйти")

                clickedFunc: function() {
                    logoutDrawer.openTriggered()
                }
            }
        }
    }

    // Настройки защиты
    AiosSettingsDrawer {
        id: settingsDrawer
        parent: root
    }

    // Шторка продления
    AiosRenewDrawer {
        id: renewDrawer
        parent: root
    }

    // Подтверждение выхода
    QuestionDrawer {
        id: logoutDrawer

        headerText: qsTr("Выйти из профиля?")
        descriptionText: qsTr("Доступ и профиль будут удалены с устройства. При следующем запуске мастер предложит добавить доступ заново.")
        yesButtonText: qsTr("Выйти")
        noButtonText: qsTr("Остаться")

        yesButtonFunction: function() {
            if (ConnectionController.isConnected) {
                PageController.showNotificationMessage(qsTr("Нельзя выходить во время подключения"))
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
