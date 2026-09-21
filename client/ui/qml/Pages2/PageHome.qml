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

// AIOS: главный экран «Мой сервер» по референсу — шапка, статус, кнопка питания,
// карточка сервера, преимущества. Нижняя навигация живёт в PageStart.
PageType {
    id: root

    Item {
        objectName: "homeColumnItem"

        anchors.fill: parent

        FlickableType {
            id: homeFlickable
            objectName: "homeFlickable"

            height: parent.height
            contentHeight: homeColumnLayout.implicitHeight

            ColumnLayout {
                id: homeColumnLayout
                objectName: "homeColumnLayout"

                width: homeFlickable.width
                spacing: 0

                // AIOS: отступ под системный статус-бар
                Item {
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: 12 + PageController.safeAreaTopMargin
                }

                // AIOS: шапка — фирменный знак + кнопка настроек
                RowLayout {
                    objectName: "aiosHeaderRow"

                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 10

                    Image {
                        source: "qrc:/images/aios_logo.png"
                        sourceSize.width: 28
                        sourceSize.height: 28
                    }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: "AIOS"
                            color: '#E6B64C'
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            font.letterSpacing: 4.5
                        }

                        Text {
                            text: "VPN"
                            color: AmneziaStyle.color.textTertiary
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            font.letterSpacing: 7
                        }
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
                            source: "qrc:/images/controls/gauge.svg"
                            sourceSize.width: 17
                            sourceSize.height: 17
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: '#E6B64C' }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsDrawer.openTriggered()
                        }
                    }
                }

                // AIOS: статус-карточка по референсу (золото офлайн / зелёный подключено)
                Rectangle {
                    id: aiosStatusBanner
                    objectName: "aiosStatusBanner"

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 16
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredWidth: parent.width - 40
                    implicitHeight: 64
                    radius: 16

                    color: ConnectionController.isConnected ? Qt.rgba(61/255, 220/255, 132/255, 0.08) : '#101015'
                    border.color: ConnectionController.isConnected ? Qt.rgba(61/255, 220/255, 132/255, 0.3) : Qt.rgba(230/255, 182/255, 76/255, 0.13)
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AiosNav.goToServersTab()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Image {
                            source: ConnectionController.isConnected ? "qrc:/images/controls/shield-check.svg" : "qrc:/images/controls/shield-alert.svg"

                            sourceSize.width: 20
                            sourceSize.height: 20

                            layer {
                                enabled: true
                                effect: ColorOverlay {
                                    color: ConnectionController.isConnected ? '#3DDC84' : '#E6B64C'
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 1

                            Text {
                                text: ConnectionController.isConnected ? qsTr("Подключено") : qsTr("Вы не подключены")
                                color: ConnectionController.isConnected ? '#A7F3C9' : '#F3EEE1'
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                text: ConnectionController.isConnected ? qsTr("Ваше соединение защищено") : qsTr("Ваше соединение не защищено")
                                color: '#98917F'
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Image {
                            source: "qrc:/images/controls/chevron-right.svg"

                            sourceSize.width: 16
                            sourceSize.height: 16

                            layer {
                                enabled: true
                                effect: ColorOverlay {
                                    color: '#98917F'
                                }
                            }
                        }
                    }
                }

                // AIOS: баннер окончания подписки (последние 7 дней / истёк)
                Rectangle {
                    id: aiosExpiryBanner
                    objectName: "aiosExpiryBanner"

                    property int aiosDaysLeft: {
                        var s = AiosProfileController.expires
                        if (!s) return -1
                        var t = Date.parse(s)
                        if (isNaN(t)) {
                            var m = s.match(/^(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})/)
                            if (m) t = new Date(parseInt(m[3], 10), parseInt(m[2], 10) - 1, parseInt(m[1], 10)).getTime()
                        }
                        if (isNaN(t)) return -1
                        return Math.ceil((t - Date.now()) / 86400000)
                    }

                    readonly property bool isExpired: AiosProfileController.hasProfile && AiosProfileController.expired

                    visible: AiosProfileController.hasProfile
                             && (isExpired || (aiosDaysLeft >= 0 && aiosDaysLeft <= 7))

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 10
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredWidth: parent.width - 40
                    implicitHeight: expiryRow.implicitHeight + 24
                    radius: 16

                    color: isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.12) : Qt.rgba(230/255, 182/255, 76/255, 0.09)
                    border.color: isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.3) : Qt.rgba(230/255, 182/255, 76/255, 0.35)
                    border.width: 1

                    RowLayout {
                        id: expiryRow

                        anchors.centerIn: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        width: parent.width - 32

                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true

                                text: {
                                    if (aiosExpiryBanner.isExpired || aiosExpiryBanner.aiosDaysLeft <= 0) {
                                        return qsTr("Срок доступа истёк")
                                    }
                                    return qsTr("Подписка истекает · Осталось %1 дн.").arg(aiosExpiryBanner.aiosDaysLeft)
                                }
                                color: aiosExpiryBanner.isExpired ? '#F0858A' : '#F4D98B'
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true

                                text: aiosExpiryBanner.isExpired || aiosExpiryBanner.aiosDaysLeft <= 0
                                      ? qsTr("Продлите тариф, чтобы подключаться снова")
                                      : qsTr("Продлите без перерыва в защите")
                                color: '#98917F'
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Продлить")
                            color: aiosExpiryBanner.isExpired ? '#F0858A' : '#F4D98B'
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: renewDrawer.openTriggered()
                    }

                    Component.onCompleted: AiosProfileController.refresh()
                }

                // AIOS: кнопка питания по референсу
                ConnectButton {
                    id: connectButton
                    objectName: "connectButton"

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 28

                    showStateText: false
                }

                Text {
                    id: connectCaption
                    objectName: "connectCaption"

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12

                    text: {
                        if (ConnectionController.isConnected) {
                            var elapsed = ConnectionController.connectionElapsedText
                            return elapsed ? qsTr("Подключено · %1").arg(elapsed)
                                           : qsTr("Подключено")
                        } else if (ConnectionController.isConnectionInProgress) {
                            return qsTr("Устанавливаем защищённый канал…")
                        }
                        return qsTr("Нажмите для подключения")
                    }
                    color: ConnectionController.isConnected ? '#3DDC84' : '#98917F'
                    font.pixelSize: 12
                }

                // AIOS: карточка «Мой сервер» — переход на вкладку «Серверы»
                Rectangle {
                    id: aiosServerCard
                    objectName: "aiosServerCard"

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 28
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredWidth: parent.width - 40

                    implicitHeight: 76

                    radius: 16
                    color: '#101015'
                    border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AiosNav.goToServersTab()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44

                            radius: 12
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.22)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/images/controls/server.svg"
                                sourceSize.width: 20
                                sourceSize.height: 20
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 3

                            Text {
                                text: qsTr("Мой сервер")
                                color: '#F3EEE1'
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.maximumWidth: parent.width

                                text: ServersUiController.defaultServerDescriptionCollapsed !== ""
                                      ? ServersUiController.defaultServerDescriptionCollapsed
                                      : qsTr("Доступ не добавлен")
                                color: '#98917F'
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Image {
                            source: "qrc:/images/controls/chevron-right.svg"

                            sourceSize.width: 16
                            sourceSize.height: 16

                            layer {
                                enabled: true
                                effect: ColorOverlay {
                                    color: '#98917F'
                                }
                            }
                        }
                    }
                }

                // AIOS: живая статистика подключения — 4 плитки по референсу
                GridLayout {
                    objectName: "aiosStatsTiles"

                    visible: ConnectionController.isConnected

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 20
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredWidth: parent.width - 40

                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: [
                            {
                                icon: "qrc:/images/controls/download.svg",
                                title: qsTr("Скорость загрузки"),
                                value: ConnectionController.receivedSpeedText !== "" ? ConnectionController.receivedSpeedText : "—"
                            },
                            {
                                icon: "qrc:/images/controls/arrow-up.svg",
                                title: qsTr("Скорость отдачи"),
                                value: ConnectionController.sentSpeedText !== "" ? ConnectionController.sentSpeedText : "—"
                            },
                            {
                                icon: "qrc:/images/controls/timer.svg",
                                title: qsTr("Пинг"),
                                value: ConnectionController.pingText !== "" ? ConnectionController.pingText : "—"
                            },
                            {
                                icon: "qrc:/images/controls/history.svg",
                                title: qsTr("Время подключения"),
                                value: ConnectionController.connectionElapsedText !== "" ? ConnectionController.connectionElapsedText : "00:00:00"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: statInner.implicitHeight + 28

                            radius: 16
                            color: '#101015'
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                            border.width: 1

                            ColumnLayout {
                                id: statInner

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 14

                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true

                                    spacing: 8

                                    Image {
                                        source: modelData.icon
                                        sourceSize.width: 15
                                        sourceSize.height: 15
                                        layer.enabled: true
                                        layer.effect: ColorOverlay { color: '#E6B64C' }
                                    }

                                    Text {
                                        Layout.fillWidth: true

                                        text: modelData.title
                                        color: '#98917F'
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text: modelData.value
                                    color: '#F3EEE1'
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: 24
                }
            }
        }
    }

    // AIOS: настройки защиты (шторка)
    AiosSettingsDrawer {
        id: settingsDrawer
        parent: root
    }

    // AIOS: шторка продления подписки
    AiosRenewDrawer {
        id: renewDrawer
        parent: root
    }
}
