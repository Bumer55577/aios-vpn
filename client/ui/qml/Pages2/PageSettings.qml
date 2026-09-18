import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"

PageType {
    id: root

    Connections {
        target: ApiNewsController
        function onFetchNewsFinished() {
            PageController.showBusyIndicator(false)
        }
        
        function onErrorOccurred(errorCode, showError) {
            if (showError) {
                PageController.showErrorMessage(errorCode)
                PageController.closePage()
                PageController.showBusyIndicator(false)
            }
        }
    }

    ListViewType {
        id: listView

        anchors.fill: parent

        header: ColumnLayout {
            width: listView.width

            BaseHeaderType {
                id: header
                Layout.fillWidth: true
                Layout.topMargin: 24 + PageController.safeAreaTopMargin
                Layout.rightMargin: 16
                Layout.leftMargin: 16

                headerText: qsTr("Профиль")
            }

            // AIOS: карточка профиля — имя, срок доступа, устройства
            Rectangle {
                id: aiosProfileCard
                objectName: "aiosProfileCard"

                Layout.topMargin: 8
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 16

                width: listView.width - 32
                implicitHeight: aiosProfileColumn.implicitHeight + 32
                radius: 16

                color: '#16161A'
                border.color: '#2A2A2F'
                border.width: 1

                ColumnLayout {
                    id: aiosProfileColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 44; height: 44; radius: 22
                            color: '#D4AF37'
                            Text {
                                anchors.centerIn: parent
                                text: "AIOS"
                                color: '#0B0B0D'
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text {
                                text: AiosProfileController.hasProfile && AiosProfileController.owner !== ""
                                      ? AiosProfileController.owner : qsTr("AIOS пользователь")
                                color: '#FFFFFF'
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                            Text {
                                text: {
                                    if (!AiosProfileController.hasProfile) return qsTr("Доступ активен")
                                    if (AiosProfileController.expired) return qsTr("Доступ истёк")
                                    if (AiosProfileController.expires !== "") return qsTr("Доступ до ") + AiosProfileController.expires
                                    return qsTr("Доступ активен")
                                }
                                color: (AiosProfileController.hasProfile && AiosProfileController.expired) ? '#D4AF37' : '#34D399'
                                font.pixelSize: 12
                            }
                        }
                    }

                    DividerType { Layout.fillWidth: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Устройства")
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AiosProfileController.hasProfile
                                  ? AiosProfileController.devicesUsed + " " + qsTr("из") + " " + AiosProfileController.devicesTotal
                                  : ServersModel.rowCount() + " " + qsTr("подключено")
                            color: '#FFFFFF'
                            font.pixelSize: 12
                        }
                    }
                }

                Component.onCompleted: {
                    AiosProfileController.refresh()
                }
                Connections {
                    target: ServersUiController
                    function onDefaultServerIdChanged() {
                        AiosProfileController.refresh()
                    }
                }
            }
        }

        model: settingsEntries

        delegate: ColumnLayout {
            width: listView.width

            spacing: 0

            LabelWithButtonType {
                Layout.fillWidth: true

                visible: isVisible

                text: title
                rightImageSource: "qrc:/images/controls/chevron-right.svg"
                leftImageSource: leftImagePath

                clickedFunction: clickedHandler
            }

            DividerType {
                visible: isVisible
            }
        }

        footer: ColumnLayout {
            width: listView.width

            LabelWithButtonType {
                id: close

                visible: GC.isDesktop()
                Layout.fillWidth: true

                text: qsTr("Close application")
                leftImageSource: "qrc:/images/controls/x-circle.svg"
                isLeftImageHoverEnabled: false

                clickedFunction: function() {
                    PageController.closeApplication()
                }
            }

            DividerType {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                visible: GC.isDesktop()
            }
        }
    }

    property list<QtObject> settingsEntries: [
        servers,
        connection,
        application,
        news,
        backup,
        about,
        devConsole
    ]

    QtObject {
        id: servers

        property string title: qsTr("Servers")
        readonly property string leftImagePath: "qrc:/images/controls/server.svg"
        property bool isVisible: true
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageSettingsServersList)
        }
    }

    QtObject {
        id: connection

        property string title: qsTr("Connection")
        readonly property string leftImagePath: "qrc:/images/controls/radio.svg"
        property bool isVisible: true
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageSettingsConnection)
        }
    }

    QtObject {
        id: application

        property string title: qsTr("Application")
        readonly property string leftImagePath: "qrc:/images/controls/app.svg"
        property bool isVisible: true
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageSettingsApplication)
        }
    }

    QtObject {
        id: news

        property string title: qsTr("News & Notifications")
        readonly property string leftImagePath: NewsModel.hasUnread && SettingsController.isNewsNotificationsEnabled() ? "qrc:/images/controls/news-unread.svg" : "qrc:/images/controls/news.svg"
        property bool isVisible: ServersUiController.hasServersFromGatewayApi
        readonly property var clickedHandler: function() {
            if (!ServersUiController.hasServersFromGatewayApi) {
                return;
            }
            PageController.showBusyIndicator(true)
            ApiNewsController.fetchNews(true)
            PageController.goToPage(PageEnum.PageSettingsNewsNotifications)
        }
    }

    QtObject {
        id: backup

        property string title: qsTr("Backup")
        readonly property string leftImagePath: "qrc:/images/controls/save.svg"
        property bool isVisible: true
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageSettingsBackup)
        }
    }

    QtObject {
        id: about

        property string title: qsTr("About AIOS VPN")
        readonly property string leftImagePath: "qrc:/images/controls/amnezia.svg"
        property bool isVisible: true
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageSettingsAbout)
        }
    }

    QtObject {
        id: devConsole

        property string title: qsTr("Dev console")
        readonly property string leftImagePath: "qrc:/images/controls/bug.svg"
        property bool isVisible: SettingsController.isDevModeEnabled
        readonly property var clickedHandler: function() {
            PageController.goToPage(PageEnum.PageDevMenu)
        }
    }
}
