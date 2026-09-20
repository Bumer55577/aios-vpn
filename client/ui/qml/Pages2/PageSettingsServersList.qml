import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SortFilterProxyModel 0.2

import PageEnum 1.0
import ContainerProps 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"
import "../Components"

PageType {
    id: root

    ColumnLayout {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.topMargin: 20 + PageController.safeAreaTopMargin

        BackButtonType {
            id: backButton
        }

        BaseHeaderType {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            headerText: qsTr("Servers")
        }
    }

    // AIOS: единственный сервер — карточка «Мой сервер»
    Rectangle {
        id: aiosServersCard
        objectName: "aiosServersCard"

        anchors.top: header.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16

        implicitHeight: 96
        radius: 16

        color: '#16161A'
        border.color: '#2A2A2F'
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: 40; height: 40; radius: 12
                color: '#E6B64C'
                Text {
                    anchors.centerIn: parent
                    text: "\u25B2"
                    color: '#0B0B0D'
                    font.pixelSize: 18
                    font.bold: true
                }
            }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: ServersUiController.defaultServerName !== "" ? ServersUiController.defaultServerName : qsTr("Мой сервер")
                    color: '#FFFFFF'
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: ConnectionController.isConnected ? qsTr("Подключено") : qsTr("Доступен")
                    color: ConnectionController.isConnected ? '#3DDC84' : '#8E8E93'
                    font.pixelSize: 12
                }
            }
            Text {
                text: "AWG"
                color: '#8E8E93'
                font.pixelSize: 12
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
                PageController.goToPage(PageEnum.PageSettingsServerInfo)
            }
        }
    }
}
