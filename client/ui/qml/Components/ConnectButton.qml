import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

import ConnectionState 1.0
import PageEnum 1.0
import Style 1.0

// AIOS: кнопка питания по референсу — тёмный диск, светящееся кольцо,
// мягкое внутреннее кольцо, глиф питания. Цвета: золото офлайн / зелёный онлайн.
Button {
    id: root

    property string defaultButtonColor: '#E6B64C' // AIOS: золото офлайн
    property string progressButtonColor: '#B98A2E' // AIOS: приглушённое золото в процессе
    property string connectedButtonColor: '#3DDC84' // AIOS: зелёное свечение подключено

    // AIOS: на главной состояние показывается подписью под кнопкой,
    // на остальных экранах текст внутри кнопки сохранён
    property bool showStateText: true

    property bool buttonActiveFocus: activeFocus && (Qt.platform.os !== "android" || SettingsController.isOnTv())

    property bool isFocusable: true

    Keys.onTabPressed: {
        FocusController.nextKeyTabItem()
    }

    Keys.onBacktabPressed: {
        FocusController.previousKeyTabItem()
    }

    Keys.onUpPressed: {
        FocusController.nextKeyUpItem()
    }

    Keys.onDownPressed: {
        FocusController.nextKeyDownItem()
    }

    Keys.onLeftPressed: {
        FocusController.nextKeyLeftItem()
    }

    Keys.onRightPressed: {
        FocusController.nextKeyRightItem()
    }

    implicitWidth: 176
    implicitHeight: 176

    text: ConnectionController.connectionStateText

    // AIOS: акцентный цвет текущего состояния
    readonly property color stateColor: {
        if (ConnectionController.isConnectionInProgress) {
            return progressButtonColor
        } else if (ConnectionController.isConnected) {
            return connectedButtonColor
        }
        return defaultButtonColor
    }

    Connections {
        target: ConnectionController

        function onPreparingConfig() {
            PageController.showNotificationMessage(qsTr("Unable to disconnect during configuration preparation"))
        }
    }

    background: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height
        transformOrigin: Item.Center

        // тёмный диск
        Rectangle {
            id: disc

            anchors.fill: parent
            radius: width / 2
            color: '#121218'
        }

        // мягкое внешнее свечение кольца
        Rectangle {
            id: rim

            anchors.fill: parent
            anchors.margins: 6
            radius: width / 2
            color: AmneziaStyle.color.transparent
            border.width: 2
            border.color: root.stateColor

            layer.enabled: true
            layer.effect: DropShadow {
                anchors.fill: rim
                horizontalOffset: 0
                verticalOffset: 0
                radius: 22
                samples: 25
                color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.4)
                source: rim
            }
        }

        // мягкое внутреннее кольцо
        Rectangle {
            anchors.fill: parent
            anchors.margins: 18
            radius: width / 2
            color: AmneziaStyle.color.transparent
            border.width: 1
            border.color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.2)
        }

        // фокус-кольцо (десктоп/ТВ)
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: AmneziaStyle.color.transparent
            border.width: 1
            border.color: AmneziaStyle.color.paleGray
            visible: root.buttonActiveFocus
        }

        // дуга прогресса подключения
        Shape {
            id: shape

            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            visible: ConnectionController.isConnectionInProgress

            ShapePath {
                fillColor: AmneziaStyle.color.transparent
                strokeColor: root.defaultButtonColor
                strokeWidth: 2
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: shape.width / 2
                    centerY: shape.height / 2
                    radiusX: shape.width / 2 - 10
                    radiusY: shape.height / 2 - 10
                    startAngle: 245
                    sweepAngle: -180
                }
            }

            RotationAnimator {
                target: shape
                running: ConnectionController.isConnectionInProgress
                from: 0
                to: 360
                loops: Animation.Infinite
                duration: 1000
            }
        }

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor
            enabled: false
        }
    }

    contentItem: Item {
        implicitWidth: parent.width
        implicitHeight: parent.height

        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.showStateText ? -14 : 0
            spacing: 0

            // глиф питания: дуга с разрывом сверху + вертикальная линия
            Shape {
                id: powerGlyph

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                layer.enabled: true
                layer.samples: 4

                opacity: ConnectionController.isConnectionInProgress ? 0.8 : 1.0

                ShapePath {
                    fillColor: AmneziaStyle.color.transparent
                    strokeColor: root.stateColor
                    strokeWidth: 4.5
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 32
                        centerY: 32
                        radiusX: 23
                        radiusY: 23
                        startAngle: 320
                        sweepAngle: 280
                    }
                }

                ShapePath {
                    fillColor: AmneziaStyle.color.transparent
                    strokeColor: root.stateColor
                    strokeWidth: 4.5
                    capStyle: ShapePath.RoundCap

                    startX: 32
                    startY: 4

                    PathLine {
                        x: 32
                        y: 30
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 14

                visible: root.showStateText

                font.family: "PT Root UI VF"
                font.weight: 600
                font.pixelSize: 15

                color: root.stateColor
                text: root.text
            }
        }
    }

    onClicked: {
        ConnectionController.connectButtonClicked()
    }

    Keys.onEnterPressed: this.clicked()
    Keys.onReturnPressed: this.clicked()
}
