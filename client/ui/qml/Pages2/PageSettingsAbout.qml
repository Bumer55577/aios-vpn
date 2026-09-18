import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Config"
import "../Controls2/TextTypes"
import "../Components"

PageType {
    id: root

    Connections {
        target: UpdateController

        function onUpdateNotFound() {
            PageController.showNotificationMessage(qsTr("You have the latest version of AIOS VPN"))
        }

        function onUpdateCheckFailed() {
            PageController.showNotificationMessage(qsTr("Failed to check for updates"))
        }
    }

    BackButtonType {
        id: backButton

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 20 + PageController.safeAreaTopMargin

        onActiveFocusChanged: {
            if(backButton.enabled && backButton.activeFocus) {
                listView.positionViewAtBeginning()
            }
        }
    }

    ListViewType {
        id: listView

        anchors.top: backButton.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left

        header: ColumnLayout {
            width: listView.width

            Image {
                id: image
                source: "qrc:/images/aios_logo.png"

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 24
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.preferredWidth: 140
                Layout.preferredHeight: 136
                fillMode: Image.PreserveAspectFit
            }

            Header2TextType {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                text: qsTr("О приложении AIOS VPN")
                horizontalAlignment: Text.AlignHCenter
            }

            ParagraphTextType {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                horizontalAlignment: Text.AlignHCenter

                height: 20
                font.pixelSize: 14

                text: qsTr("AIOS VPN — ваш личный защищённый доступ в интернет. Свобода в каждом соединении.")
                color: AmneziaStyle.color.paleGray
            }

            ParagraphTextType {
                Layout.fillWidth: true
                Layout.topMargin: 32
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                text: qsTr("Contacts")
            }
        }

        model: contacts

        delegate: ColumnLayout {
            width: listView.width

            LabelWithButtonType {
                Layout.fillWidth: true
                Layout.topMargin: 6

                text: title
                descriptionText: description
                leftImageSource: imageSource

                clickedFunction: handler
            }

            DividerType {}

        }

        footer: ColumnLayout {
            width: listView.width

            CaptionTextType {
                Layout.fillWidth: true
                Layout.topMargin: 40

                horizontalAlignment: Text.AlignHCenter

                text: qsTr("Software version: %1").arg(SettingsController.getAppVersion())
                color: AmneziaStyle.color.mutedGray

                MouseArea {
                    property int clickCount: 0
                    anchors.fill: parent
                    onClicked: {
                        if (clickCount > 10) {
                            SettingsController.enableDevMode()
                        } else {
                            clickCount++
                        }
                    }
                }
            }

            BasicButtonType {
                id: checkUpdatesButton

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 16
                implicitHeight: 48

                defaultColor: AmneziaStyle.color.surfaceBase
                hoveredColor: AmneziaStyle.color.surfaceHovered
                pressedColor: AmneziaStyle.color.surfacePressed
                disabledColor: AmneziaStyle.color.surfaceBase
                textColor: AmneziaStyle.color.surfaceInverse
                borderWidth: 1
                borderColor: AmneziaStyle.color.borderSoft

                enabled: !UpdateController.isCheckRunning

                text: UpdateController.isCheckRunning ? qsTr("Checking...") : qsTr("Check for updates")

                clickedFunc: function() {
                    UpdateController.checkForUpdates()
                }
            }

            BasicButtonType {
                id: privacyPolicyButton

                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16
                Layout.topMargin: -15
                implicitHeight: 25

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                disabledColor: AmneziaStyle.color.mutedGray
                textColor: AmneziaStyle.color.goldenApricot

                text: qsTr("Privacy Policy")

                clickedFunc: function() {
                    Qt.openUrlExternally(LanguageUiController.getCurrentSiteUrl("policy"))
                }
            }
        }
    }
    
    property list<QtObject> contacts: [
        mail,
        github
    ]

    QtObject {
        id: mail

        readonly property string title: qsTr("support@aios-vpn.app")
        readonly property string description: qsTr("For reviews and bug reports")
        readonly property string imageSource: "qrc:/images/controls/mail.svg"
        readonly property var handler: function() {
            Qt.openUrlExternally(qsTr("mailto:support@aios-vpn.app"))
        }
    }

    QtObject {
        id: github

        readonly property string title: qsTr("GitHub")
        readonly property string description: qsTr("Discover the source code")
        readonly property string imageSource: "qrc:/images/controls/github.svg"
        readonly property var handler: function() {
            Qt.openUrlExternally(qsTr("https://github.com/Bumer55577/aios-vpn"))
        }
    }
}
