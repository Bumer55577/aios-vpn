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

// AIOS: экран «Серверы» — единственная карточка «Мой сервер» по референсу.
// Без списка стран: один личный сервер, весь трафик идёт через него.
PageType {
    id: root

    readonly property bool isConnected: ConnectionController.isConnected
    readonly property bool isConnecting: ConnectionController.isConnectionInProgress
    readonly property bool isExpired: AiosProfileController.hasProfile && AiosProfileController.expired
    readonly property bool hasToken: ServersUiController.aiosTokenForServer(ServersUiController.defaultServerId) !== ""

    Component.onCompleted: AiosProfileController.refresh()

    Connections {
        target: ServersUiController
        function onDefaultServerIdChanged() {
            AiosProfileController.refresh()
        }
    }

    // Пустое состояние — доступ не добавлен
    ColumnLayout {
        anchors.fill: parent
        visible: ServersModel.rowCount() === 0

        Item { Layout.fillWidth: true; Layout.preferredHeight: 24 + PageController.safeAreaTopMargin }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Серверы")
            color: '#F3EEE1'
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 96
            height: 96
            radius: 32
            color: '#101015'
            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.2)
            border.width: 1

            Image {
                anchors.centerIn: parent
                source: "qrc:/images/controls/server.svg"
                sourceSize.width: 40
                sourceSize.height: 40
                layer.enabled: true
                layer.effect: ColorOverlay { color: '#E6B64C' }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24

            text: qsTr("Доступ ещё не добавлен")
            color: '#F3EEE1'
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            Layout.maximumWidth: 300

            text: qsTr("AIOS VPN работает с одним личным сервером. Добавьте доступ по QR, ссылке или файлу — и он появится здесь карточкой «Мой сервер».")
            color: '#98917F'
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }

        BasicButtonType {
            id: addAccessButton

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28

            implicitHeight: 48
            implicitWidth: 220

            defaultColor: '#E6B64C'
            hoveredColor: '#F4D98B'
            pressedColor: '#C9962E'
            textColor: '#231806'
            borderWidth: 0

            text: qsTr("Добавить доступ")
            clickedFunc: function() {
                PageController.goToPage(PageEnum.PageSetupWizardConfigSource)
            }
        }

        Item { Layout.fillHeight: true }
        Item { Layout.preferredHeight: 24 }
    }

    // Основное содержимое
    FlickableType {
        id: flickable
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: ServersModel.rowCount() !== 0
        visible: ServersModel.rowCount() !== 0

        contentHeight: contentColumn.implicitHeight + contentColumn.anchors.topMargin

        ColumnLayout {
            id: contentColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 20 + PageController.safeAreaTopMargin

            spacing: 0

            // Заголовок
            Text {
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                text: qsTr("Серверы")
                color: '#F3EEE1'
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Text {
                Layout.topMargin: 4
                Layout.leftMargin: 20
                Layout.rightMargin: 20

                text: qsTr("Единая точка управления доступом")
                color: '#98917F'
                font.pixelSize: 12
            }

            // Карточка «Мой сервер»
            Rectangle {
                id: serverCard

                Layout.topMargin: 20
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: cardInner.implicitHeight + 2 * 20

                radius: 24
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                ColumnLayout {
                    id: cardInner

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20

                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        spacing: 16

                        // Иконка сервера со статусной точкой
                        Rectangle {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56

                            radius: 16
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.1)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.25)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                source: "qrc:/images/controls/server.svg"
                                sourceSize.width: 26
                                sourceSize.height: 26
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.rightMargin: -2
                                anchors.bottomMargin: -2

                                width: 14
                                height: 14
                                radius: 7

                                border.color: '#101015'
                                border.width: 2

                                color: root.isConnected ? '#3DDC84' : (root.isExpired ? '#F87171' : '#C9962E')
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 4

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: qsTr("Мой сервер")
                                    color: '#F3EEE1'
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }

                                // Бейдж статуса
                                Rectangle {
                                    implicitWidth: statusText.implicitWidth + 16
                                    implicitHeight: statusText.implicitHeight + 8
                                    radius: height / 2

                                    color: root.isConnected ? Qt.rgba(61/255, 220/255, 132/255, 0.1)
                                                            : root.isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.1)
                                                                             : Qt.rgba(255/255, 255/255, 255/255, 0.04)
                                    border.color: root.isConnected ? Qt.rgba(61/255, 220/255, 132/255, 0.25)
                                                                   : root.isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.3)
                                                                                    : Qt.rgba(230/255, 182/255, 76/255, 0.18)
                                    border.width: 1

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent

                                        text: root.isConnected ? qsTr("Активен") : root.isExpired ? qsTr("Истёк") : qsTr("Готов")
                                        color: root.isConnected ? '#A7F3C9' : root.isExpired ? '#F0858A' : '#CBBD95'
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true

                                text: ServersUiController.defaultServerDescriptionCollapsed !== ""
                                      ? ServersUiController.defaultServerDescriptionCollapsed
                                      : ServersUiController.defaultServerName
                                color: '#98917F'
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }

                    DividerType {
                        Layout.topMargin: 16
                        Layout.fillWidth: true
                    }

                    // Информационные строки
                    ColumnLayout {
                        Layout.topMargin: 14
                        Layout.fillWidth: true

                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true

                            spacing: 12

                            Image {
                                source: "qrc:/images/controls/arrow-left-right.svg"
                                sourceSize.width: 16
                                sourceSize.height: 16
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }

                            Text {
                                text: qsTr("Протокол")
                                color: '#98917F'
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: ServersUiController.defaultServerDefaultContainerName !== ""
                                      ? ServersUiController.defaultServerDefaultContainerName : "—"
                                color: '#E9E2D2'
                                font.pixelSize: 12
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            spacing: 12

                            Image {
                                source: root.isExpired ? "qrc:/images/controls/shield-alert.svg" : "qrc:/images/controls/shield-check.svg"
                                sourceSize.width: 16
                                sourceSize.height: 16
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: root.isExpired ? '#F0858A' : '#E6B64C' }
                            }

                            Text {
                                text: qsTr("Тип доступа")
                                color: '#98917F'
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.hasToken ? qsTr("VPNPan (по токену)") : qsTr("Локальная конфигурация")
                                color: '#E9E2D2'
                                font.pixelSize: 12
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            spacing: 12

                            Image {
                                source: "qrc:/images/controls/calendar.svg"
                                sourceSize.width: 16
                                sourceSize.height: 16
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: '#E6B64C' }
                            }

                            Text {
                                text: qsTr("Доступ")
                                color: '#98917F'
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (!AiosProfileController.hasProfile) return qsTr("Не ограничен")
                                    if (AiosProfileController.expired) return qsTr("Истёк")
                                    return qsTr("до ") + AiosProfileController.expires
                                }
                                color: AiosProfileController.hasProfile && AiosProfileController.expired ? '#F0858A' : '#E9E2D2'
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            // Кнопка подключения
            BasicButtonType {
                id: connectButton

                Layout.topMargin: 16
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                implicitHeight: 48

                defaultColor: '#E6B64C'
                hoveredColor: '#F4D98B'
                pressedColor: '#C9962E'
                disabledColor: '#57503C'
                textColor: '#231806'
                borderWidth: 0

                enabled: !root.isConnecting

                text: root.isConnecting ? qsTr("Подключение…") : root.isConnected ? qsTr("Отключиться") : qsTr("Подключиться")

                clickedFunc: function() {
                    ConnectionController.connectButtonClicked()
                }
            }

            // Заменить / Удалить
            RowLayout {
                Layout.topMargin: 12
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.fillWidth: true

                spacing: 12

                BasicButtonType {
                    id: replaceButton

                    Layout.fillWidth: true

                    implicitHeight: 44

                    defaultColor: Qt.rgba(255/255, 255/255, 255/255, 0.04)
                    hoveredColor: Qt.rgba(255/255, 255/255, 255/255, 0.07)
                    pressedColor: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                    textColor: '#F3EEE1'
                    borderColor: Qt.rgba(230/255, 182/255, 76/255, 0.14)
                    borderWidth: 1

                    buttonTextLabel.font.pixelSize: 13

                    text: qsTr("Заменить доступ")

                    clickedFunc: function() {
                        PageController.goToPage(PageEnum.PageSetupWizardConfigSource)
                    }
                }

                BasicButtonType {
                    id: deleteButton

                    Layout.fillWidth: true

                    implicitHeight: 44

                    defaultColor: Qt.rgba(255/255, 255/255, 255/255, 0.04)
                    hoveredColor: Qt.rgba(255/255, 255/255, 255/255, 0.07)
                    pressedColor: Qt.rgba(255/255, 255/255, 255/255, 0.1)
                    textColor: '#F0858A'
                    borderColor: Qt.rgba(229/255, 72/255, 77/255, 0.2)
                    borderWidth: 1

                    buttonTextLabel.font.pixelSize: 13

                    text: qsTr("Удалить")

                    clickedFunc: function() {
                        deleteDrawer.openTriggered()
                    }
                }
            }

            // Примечание
            Rectangle {
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 24
                Layout.fillWidth: true

                implicitHeight: noteRow.implicitHeight + 32

                radius: 16
                color: '#101015'
                border.color: Qt.rgba(230/255, 182/255, 76/255, 0.13)
                border.width: 1

                RowLayout {
                    id: noteRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16

                    spacing: 10

                    Image {
                        source: "qrc:/images/controls/info.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: '#E6B64C' }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Здесь намеренно нет списка стран: AIOS VPN использует один личный сервер, а весь трафик направляется через него.")
                        color: '#98917F'
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                    }
                }
            }
        }
    }

    // Подтверждение удаления доступа
    QuestionDrawer {
        id: deleteDrawer

        headerText: qsTr("Удалить доступ?")
        descriptionText: qsTr("Карточка «Мой сервер» и профиль будут удалены с устройства. Токен в панели VPNPan останется активным.")
        yesButtonText: qsTr("Удалить")
        noButtonText: qsTr("Отмена")

        yesButtonFunction: function() {
            if (ConnectionController.isConnected) {
                PageController.showNotificationMessage(qsTr("Нельзя удалять доступ во время подключения"))
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
