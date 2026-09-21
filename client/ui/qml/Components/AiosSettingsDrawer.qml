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

// AIOS: шторка «Настройки защиты» — автоподключение, Kill Switch, строгий режим.
DrawerType2 {
    id: root

    anchors.fill: parent
    expandedHeight: parent.height * 0.62

    defaultColor: '#121218'
    borderColor: Qt.rgba(230/255, 182/255, 76/255, 0.15)

    expandedStateContent: ColumnLayout {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: root.expandedHeight

        BackButtonType {
            id: backButton

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16

            backButtonFunction: function() {
                root.closeTriggered()
            }
        }

        ColumnLayout {
            anchors.top: backButton.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 8
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: 24

            spacing: 0

            Text {
                Layout.fillWidth: true

                text: qsTr("Настройки защиты")
                color: '#F3EEE1'
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Text {
                Layout.topMargin: 6
                Layout.fillWidth: true

                text: qsTr("Параметры применяются к новому соединению.")
                color: '#98917F'
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            SwitcherType {
                id: autoConnectSwitcher

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Автоподключение")
                descriptionText: qsTr("Подключаться к серверу при старте приложения")

                checkedIndicatorColor: '#E6B64C'
                checkedIndicatorBorderColor: '#E6B64C'
                checkedInnerCircleColor: '#231806'

                checked: SettingsController.isAutoConnectEnabled()
                onToggled: function() {
                    if (checked !== SettingsController.isAutoConnectEnabled()) {
                        SettingsController.toggleAutoConnect(checked)
                    }
                }
            }

            DividerType { Layout.fillWidth: true; Layout.topMargin: 8 }

            SwitcherType {
                id: killSwitchSwitcher

                Layout.topMargin: 8
                Layout.fillWidth: true

                text: qsTr("Kill Switch")
                descriptionText: qsTr("Блокировать трафик при разрыве соединения")

                checkedIndicatorColor: '#E6B64C'
                checkedIndicatorBorderColor: '#E6B64C'
                checkedInnerCircleColor: '#231806'

                checked: SettingsController.isKillSwitchEnabled
                onToggled: function() {
                    if (checked !== SettingsController.isKillSwitchEnabled) {
                        SettingsController.toggleKillSwitch(checked)
                    }
                }
            }

            DividerType { Layout.fillWidth: true; Layout.topMargin: 8 }

            SwitcherType {
                id: strictKillSwitchSwitcher

                Layout.topMargin: 8
                Layout.fillWidth: true

                text: qsTr("Строгий Kill Switch")
                descriptionText: qsTr("Разрешать только VPN-трафик, блокировать всё остальное")

                checkedIndicatorColor: '#E6B64C'
                checkedIndicatorBorderColor: '#E6B64C'
                checkedInnerCircleColor: '#231806'

                checked: SettingsController.strictKillSwitchEnabled
                onToggled: function() {
                    if (checked !== SettingsController.strictKillSwitchEnabled) {
                        SettingsController.toggleStrictKillSwitch(checked)
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
