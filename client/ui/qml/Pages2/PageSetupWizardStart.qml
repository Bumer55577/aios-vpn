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

PageType {
    id: root
    enableTimer: (SettingsController.isOnTv()) ? false : true

    // AIOS: стартовый экран 1:1 по референсу design-reference-main.png
    // (лого-пик, AIOS VPN, слоган, планета, 5 фич, кнопка «Начать», точки)

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 0

        Image {
            id: logoImage
            source: "qrc:/images/aios_logo.png"

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24 + PageController.safeAreaTopMargin
            Layout.preferredWidth: 88
            Layout.preferredHeight: 84
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: qsTr("AIOS")
            color: "#D4AF37"
            font.pixelSize: 38
            font.weight: Font.DemiBold
            font.letterSpacing: 12
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
        }

        Text {
            text: qsTr("VPN")
            color: "#D4AF37"
            font.pixelSize: 15
            font.weight: Font.Medium
            font.letterSpacing: 13
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
        }

        Text {
            text: qsTr("Свобода в каждом соединении")
            color: "#D4AF37"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
        }

        Text {
            text: qsTr("Быстрый  •  Безопасный  •  Без границ")
            color: "#8E8E93"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
        }

        Image {
            id: planetImage
            source: "qrc:/images/aios_planet.jpg"

            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.preferredHeight: 200
            fillMode: Image.PreserveAspectCrop
        }

        RowLayout {
            id: featuresRow1
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            spacing: 30

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: "#16161A"
                    border.color: "#2A2A2E"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: f1
                        source: "qrc:/images/controls/eye-off.svg"
                        anchors.centerIn: parent
                        width: 24; height: 24
                        visible: false
                    }
                    ColorOverlay { anchors.fill: f1; source: f1; color: "#D4AF37" }
                }

                Text {
                    text: qsTr("Полная\nконфиденциальность")
                    color: "#B9B9BE"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: "#16161A"
                    border.color: "#2A2A2E"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: f2
                        source: "qrc:/images/controls/gauge.svg"
                        anchors.centerIn: parent
                        width: 24; height: 24
                        visible: false
                    }
                    ColorOverlay { anchors.fill: f2; source: f2; color: "#D4AF37" }
                }

                Text {
                    text: qsTr("Высокая\nскорость")
                    color: "#B9B9BE"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: "#16161A"
                    border.color: "#2A2A2E"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: f3
                        source: "qrc:/images/controls/globe-2.svg"
                        anchors.centerIn: parent
                        width: 24; height: 24
                        visible: false
                    }
                    ColorOverlay { anchors.fill: f3; source: f3; color: "#D4AF37" }
                }

                Text {
                    text: qsTr("Доступ к любому\nконтенту")
                    color: "#B9B9BE"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        RowLayout {
            id: featuresRow2
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            spacing: 30

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: "#16161A"
                    border.color: "#2A2A2E"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: f4
                        source: "qrc:/images/controls/check.svg"
                        anchors.centerIn: parent
                        width: 24; height: 24
                        visible: false
                    }
                    ColorOverlay { anchors.fill: f4; source: f4; color: "#D4AF37" }
                }

                Text {
                    text: qsTr("Защита\nваших данных")
                    color: "#B9B9BE"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 46; height: 46; radius: 12
                    color: "#16161A"
                    border.color: "#2A2A2E"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        id: f5
                        source: "qrc:/images/controls/server.svg"
                        anchors.centerIn: parent
                        width: 24; height: 24
                        visible: false
                    }
                    ColorOverlay { anchors.fill: f5; source: f5; color: "#D4AF37" }
                }

                Text {
                    text: qsTr("Серверы по всему\nмиру")
                    color: "#B9B9BE"
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 8
        }

        BasicButtonType {
            id: startButton

            Layout.fillWidth: true
            Layout.bottomMargin: 10 + PageController.safeAreaBottomMargin
            Layout.leftMargin: 40
            Layout.rightMargin: 40
            Layout.alignment: Qt.AlignBottom

            implicitHeight: 48

            defaultColor: "#D4AF37"
            hoveredColor: "#E5C158"
            pressedColor: "#B8860B"
            disabledColor: AmneziaStyle.color.mutedGray
            textColor: "#0B0B0D"
            borderWidth: 0

            buttonTextLabel.font.pixelSize: 17
            buttonTextLabel.font.weight: Font.DemiBold

            text: qsTr("Начать")

            clickedFunc: function() {
                PageController.goToPage(PageEnum.PageSetupWizardConfigSource)
            }
        }

        Row {
            id: pageDots
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 14 + PageController.safeAreaBottomMargin
            spacing: 7

            Rectangle { width: 8; height: 8; radius: 4; color: "#D4AF37" }
            Rectangle { width: 8; height: 8; radius: 4; color: "#3A3A3E" }
            Rectangle { width: 8; height: 8; radius: 4; color: "#3A3A3E" }
            Rectangle { width: 8; height: 8; radius: 4; color: "#3A3A3E" }
        }
    }

    Timer {
        interval: 250
        running: SettingsController.isOnTv()
        repeat: true
        onTriggered: {
            startButton.forceActiveFocus()
            if (startButton.activeFocus) {
                running = false
            }
        }
    }

    onVisibleChanged: {
        if (visible && SettingsController.isOnTv()) {
            startButton.forceActiveFocus()
        }
    }
}
