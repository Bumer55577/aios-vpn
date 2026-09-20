import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import PageEnum 1.0
import Style 1.0

import "./"
import "../Controls2"
import "../Controls2/TextTypes"
import "../Config"

// AIOS: шторка продления подписки — выбор тарифа -> «Оплатить».
// Кнопка оплаты открывает внешнюю страницу оплаты (Qt.openUrlExternally).
DrawerType2 {
    id: root

    anchors.fill: parent
    expandedHeight: parent.height * 0.56

    defaultColor: '#121218'
    borderColor: Qt.rgba(230/255, 182/255, 76/255, 0.15)

    // Плейсхолдер: заменить на реальный адрес платёжной страницы
    property string paymentBaseUrl: "https://aios-vpn.app/pay"

    property int selectedTariffIndex: 0

    readonly property var tariffs: [
        { id: "m1", label: qsTr("1 месяц"), price: 199, badge: "" },
        { id: "m6", label: qsTr("6 месяцев"), price: 999, badge: "−16%" },
        { id: "m12", label: qsTr("12 месяцев"), price: 1799, badge: "−25% · " + qsTr("выгодно") }
    ]

    readonly property var selectedTariff: tariffs[selectedTariffIndex]

    function pay() {
        var tariff = selectedTariff
        var url = paymentBaseUrl + "?plan=" + encodeURIComponent(tariff.id)
        Qt.openUrlExternally(url)
        root.closeTriggered()
    }

    expandedStateContent: ColumnLayout {
        id: renewContent

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: root.expandedHeight

        BackButtonType {
            id: renewDrawerBackButton

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16

            backButtonFunction: function() {
                root.closeTriggered()
            }
        }

        ColumnLayout {
            anchors.top: renewDrawerBackButton.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 8
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16

            spacing: 12

            Text {
                Layout.fillWidth: true

                text: qsTr("Продлить подписку")
                color: '#F0EAD9'
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true

                text: qsTr("Доступ продлевается сразу после оплаты — перезапускать приложение не нужно.")
                color: '#8E8E93'
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            // Тарифы
            Repeater {
                model: root.tariffs

                delegate: Rectangle {
                    id: tariffCard

                    required property var modelData
                    required property int index

                    property bool isSelected: root.selectedTariffIndex === index

                    Layout.fillWidth: true
                    implicitHeight: tariffRow.implicitHeight + 24

                    radius: 14
                    color: isSelected ? Qt.rgba(230/255, 182/255, 76/255, 0.08) : '#101015'
                    border.color: isSelected ? '#E6B64C' : '#2A2A2F'
                    border.width: 1

                    RowLayout {
                        id: tariffRow

                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        spacing: 12

                        // Радио-индикатор
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "transparent"
                            border.color: tariffCard.isSelected ? '#E6B64C' : '#8E8E93'
                            border.width: 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                radius: 5
                                color: '#E6B64C'
                                visible: tariffCard.isSelected
                            }
                        }

                        Text {
                            text: tariffCard.modelData.label
                            color: '#F0EAD9'
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: tariffCard.modelData.badge !== ""
                            radius: 8
                            color: Qt.rgba(230/255, 182/255, 76/255, 0.12)
                            border.color: Qt.rgba(230/255, 182/255, 76/255, 0.4)
                            width: badgeText.implicitWidth + 16
                            height: badgeText.implicitHeight + 6

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: tariffCard.modelData.badge
                                color: '#E6B64C'
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            text: tariffCard.modelData.price + " ₽"
                            color: '#F0EAD9'
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedTariffIndex = tariffCard.index
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Text {
                Layout.fillWidth: true

                text: qsTr("Оплата откроется в браузере — защищённый платёж, без ввода данных карты в приложении.")
                color: '#8E8E93'
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            BasicButtonType {
                id: payButton

                Layout.fillWidth: true
                implicitHeight: 48

                defaultColor: '#E6B64C'
                hoveredColor: '#F4D98B'
                pressedColor: '#C9962E'
                textColor: '#060609'
                borderWidth: 0

                text: qsTr("Оплатить") + " " + root.selectedTariff.price + " ₽"
                clickedFunc: function() {
                    root.pay()
                }
            }
        }
    }
}
