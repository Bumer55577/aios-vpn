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

    property var apiAvailableProtocols: []
    property string apiCurrentProtocol: ""

    readonly property bool isApiProtocolSelectionVisible: ServersUiController.isDefaultServerFromApi && root.apiAvailableProtocols.length > 0
    readonly property bool isOutdatedAwgWarningVisible: drawer.isCollapsedStateActive()
                                                        && ServersUiController.defaultServerHasOutdatedAwgContainer

    function updateApiProtocolState() {
        if (ServersUiController.isDefaultServerFromApi) {
            root.apiAvailableProtocols = SubscriptionUiController.availableProtocols(ServersUiController.defaultServerId)
            root.apiCurrentProtocol = SubscriptionUiController.currentProtocol(ServersUiController.defaultServerId)
        } else {
            root.apiAvailableProtocols = []
            root.apiCurrentProtocol = ""
        }
    }

    function protocolDisplayName(protocol) {
        switch (protocol) {
        case "awg": return "AWG"
        case "vless": return "VLESS"
        default: return protocol
        }
    }

    Component.onCompleted: {
        root.updateApiProtocolState()
    }

    Connections {
        target: ServersUiController

        function onDefaultServerIdChanged() {
            root.updateApiProtocolState()
        }
    }

    Connections {
        target: Qt.application

        function onStateChanged() {
            if (Qt.application.state !== Qt.ApplicationActive) {
                if (drawer.isOpened) {
                    drawer.closeTriggered()
                }
                if (homeSplitTunnelingDrawer.isOpened) {
                    homeSplitTunnelingDrawer.closeTriggered()
                }
            }
        }
    }

    Connections {
        objectName: "pageControllerConnections"

        target: PageController

        function onRestorePageHomeState(isContainerInstalled) {
            drawer.openTriggered()
        }
    }


    Item {
        objectName: "homeColumnItem"

        anchors.fill: parent
        anchors.bottomMargin: drawer.collapsedHeight

        ColumnLayout {
            objectName: "homeColumnLayout"

            anchors.fill: parent
            anchors.topMargin: 12 + PageController.safeAreaTopMargin

            // AIOS: статус-баннер по референсу (жёлтый офлайн / зелёный подключено)
            Rectangle {
                id: aiosStatusBanner
                objectName: "aiosStatusBanner"

                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.topMargin: 8
                Layout.preferredWidth: Math.min(parent.width - 32, 340)
                Layout.preferredHeight: 52
                radius: 26

                color: ConnectionController.isConnected ? Qt.rgba(52/255, 211/255, 153/255, 0.14) : Qt.rgba(212/255, 175/255, 55/255, 0.16)
                border.color: ConnectionController.isConnected ? '#34D399' : '#D4AF37'
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: ConnectionController.isConnected ? '#34D399' : '#D4AF37'
                        Text {
                            anchors.centerIn: parent
                            text: ConnectionController.isConnected ? "✓" : "⚠"
                            color: '#0B0B0D'
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: ConnectionController.isConnected ? qsTr("Подключено") : qsTr("Вы не подключены")
                            color: ConnectionController.isConnected ? '#34D399' : '#D4AF37'
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Text {
                            text: ConnectionController.isConnected ? qsTr("Ваше соединение защищено") : qsTr("Ваше соединение не защищено")
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                    }
                }
            }
            anchors.bottomMargin: 16

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
                Layout.topMargin: 8
                Layout.preferredWidth: Math.min(parent.width - 32, 340)
                implicitHeight: expiryRow.implicitHeight + 20
                radius: 26

                color: isExpired ? Qt.rgba(229/255, 72/255, 77/255, 0.14) : Qt.rgba(212/255, 175/255, 55/255, 0.16)
                border.color: isExpired ? '#E5484D' : '#D4AF37'
                border.width: 1

                RowLayout {
                    id: expiryRow

                    anchors.centerIn: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    width: parent.width - 32

                    spacing: 10

                    Text {
                        Layout.fillWidth: true

                        text: {
                            if (parent.parent.isExpired || parent.parent.aiosDaysLeft <= 0) {
                                return qsTr("Срок доступа истёк · Нажмите, чтобы продлить")
                            }
                            return qsTr("Подписка истекает · Осталось %1 дн.").arg(parent.parent.aiosDaysLeft)
                        }
                        color: parent.parent.isExpired ? '#F0858A' : '#D4AF37'
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: "›"
                        color: parent.parent.isExpired ? '#F0858A' : '#D4AF37'
                        font.pixelSize: 16
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PageController.goToPage(PageEnum.PageSettings)
                }

                Component.onCompleted: AiosProfileController.refresh()
            }

            BasicButtonType {
                id: loggingButton
                objectName: "loggingButton"

                property bool isLoggingEnabled: SettingsController.isLoggingEnabled

                Layout.alignment: Qt.AlignHCenter

                implicitHeight: 36

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                disabledColor: AmneziaStyle.color.mutedGray
                textColor: AmneziaStyle.color.mutedGray
                borderWidth: 0

                visible: isLoggingEnabled ? true : false
                text: qsTr("Logging enabled")

                Keys.onEnterPressed: this.clicked()
                Keys.onReturnPressed: this.clicked()

                onClicked: {
                    PageController.goToPage(PageEnum.PageSettingsLogging)
                }
            }

            BasicButtonType {
                id: devGatewayButton
                objectName: "devGatewayButton"

                property bool isDevGatewayEnabled: SettingsController.isDevGatewayEnv

                Layout.alignment: Qt.AlignHCenter

                implicitHeight: 36

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                disabledColor: AmneziaStyle.color.mutedGray
                textColor: AmneziaStyle.color.mutedGray
                borderWidth: 0

                visible: SettingsController.isDevModeEnabled && isDevGatewayEnabled
                text: qsTr("Dev gateway enabled")

                Keys.onEnterPressed: this.clicked()
                Keys.onReturnPressed: this.clicked()

                onClicked: {
                    PageController.goToPage(PageEnum.PageDevMenu)
                }
            }

            ConnectButton {
                id: connectButton
                objectName: "connectButton"

                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter
            }

            BasicButtonType {
                id: splitTunnelingButton
                objectName: "splitTunnelingButton"

                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                leftPadding: 16
                rightPadding: 16

                implicitHeight: 36

                defaultColor: AmneziaStyle.color.transparent
                hoveredColor: AmneziaStyle.color.translucentWhite
                pressedColor: AmneziaStyle.color.sheerWhite
                disabledColor: AmneziaStyle.color.mutedGray
                textColor: AmneziaStyle.color.mutedGray
                borderWidth: 0

                buttonTextLabel.lineHeight: 20
                buttonTextLabel.font.pixelSize: 14
                buttonTextLabel.font.weight: 500

                property bool isSplitTunnelingEnabled: IpSplitTunnelingController.isSplitTunnelingEnabled || AppSplitTunnelingController.isSplitTunnelingEnabled ||
                                                       ServersUiController.isDefaultServerDefaultContainerHasSplitTunneling

                text: isSplitTunnelingEnabled ? qsTr("Split tunneling enabled") : qsTr("Split tunneling disabled")

                leftImageSource: isSplitTunnelingEnabled ? "qrc:/images/controls/split-tunneling.svg" : ""
                leftImageColor: ""
                rightImageSource: "qrc:/images/controls/chevron-down.svg"

                Keys.onEnterPressed: this.clicked()
                Keys.onReturnPressed: this.clicked()

                onClicked: {
                    homeSplitTunnelingDrawer.openTriggered()
                }

                HomeSplitTunnelingDrawer {
                    id: homeSplitTunnelingDrawer
                    objectName: "homeSplitTunnelingDrawer"

                    parent: root
                }
            }

            AdLabel {
                id: adLabel

                Layout.fillWidth: true
                Layout.preferredHeight: adLabel.contentHeight
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 22
            }
        }
    }

    DrawerType2 {
        id: drawer
        objectName: "drawerProtocol"

        anchors.fill: parent

        collapsedStateContent: Item {
            objectName: "ProtocolDrawerCollapsedContent"

            implicitHeight: Qt.platform.os !== "ios" ? root.height * 0.9 : screen.height * 0.77
            Component.onCompleted: {
                drawer.expandedHeight = implicitHeight
            }

            ColumnLayout {
                id: collapsed
                objectName: "collapsedColumnLayout"

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Component.onCompleted: {
                    drawer.collapsedHeight = collapsed.implicitHeight
                }

                onImplicitHeightChanged: {
                    drawer.collapsedHeight = collapsed.implicitHeight
                }

                DividerType {
                    Layout.topMargin: 10
                    Layout.fillWidth: false
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 2
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                RowLayout {
                    objectName: "rowLayout"

                    Layout.topMargin: 14
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    spacing: 0

                    Connections {
                        objectName: "drawerConnections"

                        target: drawer
                        function onCursorEntered() {
                            if (drawer.isCollapsedStateActive) {
                                collapsedButtonChevron.backgroundColor = collapsedButtonChevron.hoveredColor
                                collapsedButtonHeader.opacity = 0.8
                            } else {
                                collapsedButtonHeader.opacity = 1
                            }
                        }

                        function onCursorExited() {
                            if (drawer.isCollapsedStateActive) {
                                collapsedButtonChevron.backgroundColor = collapsedButtonChevron.defaultColor
                                collapsedButtonHeader.opacity = 1
                            } else {
                                collapsedButtonHeader.opacity = 1
                            }
                        }

                        function onPressed(pressed, entered) {
                            if (drawer.isCollapsedStateActive) {
                                collapsedButtonChevron.backgroundColor = pressed ? collapsedButtonChevron.pressedColor : entered ? collapsedButtonChevron.hoveredColor : collapsedButtonChevron.defaultColor
                                collapsedButtonHeader.opacity = 0.7
                            } else {
                                collapsedButtonHeader.opacity = 1
                            }
                        }
                    }

                    Header1TextType {
                        id: collapsedButtonHeader
                        objectName: "collapsedButtonHeader"

                        Layout.maximumWidth: drawer.width - 48 - 18 - 12

                        maximumLineCount: 2
                        elide: Qt.ElideRight

                        text: ServersUiController.defaultServerName
                        horizontalAlignment: Qt.AlignHCenter

                        Behavior on opacity {
                            PropertyAnimation { duration: 200 }
                        }
                    }

                    ImageButtonType {
                        id: collapsedButtonChevron
                        objectName: "collapsedButtonChevron"

                        Layout.leftMargin: 8

                        visible: drawer.isCollapsedStateActive()

                        hoverEnabled: false
                        image: "qrc:/images/controls/chevron-down.svg"
                        imageColor: AmneziaStyle.color.paleGray

                        icon.width: 18
                        icon.height: 18
                        backgroundRadius: 16
                        horizontalPadding: 4
                        topPadding: 4
                        bottomPadding: 3

                        Keys.onEnterPressed: this.clicked()
                        Keys.onReturnPressed: this.clicked()

                        onClicked: {
                            if (drawer.isCollapsedStateActive()) {
                                drawer.openTriggered()
                            }
                        }
                    }
                }

                RowLayout {
                    objectName: "rowLayoutLabel"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: root.isOutdatedAwgWarningVisible
                                         ? 8
                                         : (root.isApiProtocolSelectionVisible ? 8 : (drawer.isCollapsedStateActive ? 44 : ServersUiController.isDefaultServerFromApi ? 61 : 16))
                    spacing: 0

                    BasicButtonType {
                        enabled: (ServersUiController.defaultServerImagePathCollapsed !== "") && drawer.isCollapsedStateActive
                        hoverEnabled: enabled

                        implicitHeight: 36

                        leftPadding: 16
                        rightPadding: 16

                        defaultColor: AmneziaStyle.color.transparent
                        hoveredColor: AmneziaStyle.color.translucentWhite
                        pressedColor: AmneziaStyle.color.sheerWhite
                        disabledColor: AmneziaStyle.color.transparent
                        textColor: AmneziaStyle.color.mutedGray

                        buttonTextLabel.lineHeight: 16
                        buttonTextLabel.font.pixelSize: 13
                        buttonTextLabel.font.weight: 400

                        text: drawer.isCollapsedStateActive ? ServersUiController.defaultServerDescriptionCollapsed : ServersUiController.defaultServerDescriptionExpanded
                        leftImageSource: ServersUiController.defaultServerImagePathCollapsed
                        leftImageColor: ""
                        changeLeftImageSize: false

                        rightImageSource: hoverEnabled ? "qrc:/images/controls/chevron-down.svg" : ""

                        Keys.onEnterPressed: this.clicked()
                        Keys.onReturnPressed: this.clicked()

                        onClicked: {
                            ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)

                            if (ServersUiController.isServerFromApi(ServersUiController.processedServerId)) {
                                if (ServersUiController.isServerCountrySelectionAvailable(ServersUiController.processedServerId)) {
                                    PageController.goToPage(PageEnum.PageSettingsApiAvailableCountries)
                                } else {
                                    PageController.showBusyIndicator(true)
                                    let result = SubscriptionUiController.getAccountInfo(ServersUiController.processedServerId, false)
                                    PageController.showBusyIndicator(false)
                                    if (!result) {
                                        return
                                    }

                                    PageController.goToPage(PageEnum.PageSettingsApiServerInfo)
                                }
                            } else {
                                PageController.goToPage(PageEnum.PageSettingsServerInfo)
                            }
                        }
                    }
                }

                WarningType {
                    objectName: "outdatedContainerWarning"

                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 24

                    visible: root.isOutdatedAwgWarningVisible

                    backGroundColor: AmneziaStyle.color.transparent
                    iconPath: "qrc:/images/controls/alert-circle.svg"
                    imageColor: AmneziaStyle.color.goldenApricot
                    textColor: AmneziaStyle.color.goldenApricot
                    textString: qsTr("AWG 2.0 is outdated and no longer supported. Continued use requires a fresh installation of the AWG 3.1 container.")
                }

                RowLayout {
                    objectName: "protocolRowLayout"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.bottomMargin: drawer.isCollapsedStateActive ? 44 : 61
                    spacing: 0

                    visible: root.isApiProtocolSelectionVisible

                    BasicButtonType {
                        id: protocolButton
                        objectName: "protocolButton"

                        enabled: root.apiAvailableProtocols.length > 1
                        hoverEnabled: enabled

                        implicitHeight: 36

                        leftPadding: 16
                        rightPadding: 16

                        defaultColor: AmneziaStyle.color.transparent
                        hoveredColor: AmneziaStyle.color.translucentWhite
                        pressedColor: AmneziaStyle.color.sheerWhite
                        disabledColor: AmneziaStyle.color.transparent
                        textColor: AmneziaStyle.color.mutedGray

                        buttonTextLabel.lineHeight: 16
                        buttonTextLabel.font.pixelSize: 13
                        buttonTextLabel.font.weight: 400

                        text: root.apiAvailableProtocols.length > 1
                            ? root.protocolDisplayName(root.apiCurrentProtocol)
                            : root.protocolDisplayName(root.apiAvailableProtocols[0])
                        leftImageSource: "qrc:/images/controls/arrow-left-right.svg"
                        leftImageColor: AmneziaStyle.color.mutedGray

                        rightImageSource: enabled ? "qrc:/images/controls/chevron-down.svg" : ""

                        Keys.onEnterPressed: this.clicked()
                        Keys.onReturnPressed: this.clicked()

                        onClicked: {
                            if (ConnectionController.isConnectionInProgress) {
                                PageController.showNotificationMessage(qsTr("Unable change protocol while trying to make an active connection"))
                                return
                            }
                            if (ConnectionController.isConnected) {
                                PageController.showNotificationMessage(qsTr("Cannot change protocol during active connection"))
                                return
                            }
                            protocolSelectionDrawer.openTriggered()
                        }
                    }
                }
            }

            // AIOS: единственная карточка «Мой сервер» (без списка серверов)
            Rectangle {
                id: aiosServerCard
                objectName: "aiosServerCard"

                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                Layout.bottomMargin: 24
                Layout.preferredWidth: Math.min(parent.width - 32, 340)
                implicitHeight: aiosServerCardColumn.implicitHeight + 32
                radius: 16

                color: '#16161A'
                border.color: '#2A2A2F'
                border.width: 1

                ColumnLayout {
                    id: aiosServerCardColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 36; height: 36; radius: 10
                            color: '#D4AF37'
                            Text {
                                anchors.centerIn: parent
                                text: "\u25B2"
                                color: '#0B0B0D'
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text {
                                text: qsTr("Мой сервер")
                                color: '#FFFFFF'
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                            Text {
                                text: ConnectionController.isConnected ? qsTr("Онлайн") : qsTr("Доступен")
                                color: ConnectionController.isConnected ? '#34D399' : '#8E8E93'
                                font.pixelSize: 12
                            }
                        }
                        Text {
                            text: "AIOS VPN"
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                    }

                    DividerType { Layout.fillWidth: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Протокол")
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "AWG"
                            color: '#FFFFFF'
                            font.pixelSize: 12
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("Статус")
                            color: '#8E8E93'
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: ConnectionController.isConnected ? qsTr("Подключено") : qsTr("Не подключено")
                            color: ConnectionController.isConnected ? '#34D399' : '#D4AF37'
                            font.pixelSize: 12
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        PageController.goToPage(PageEnum.PageSettingsServerInfo)
                    }
                }
            }
        }
    }

    DrawerType2 {
        id: protocolSelectionDrawer
        objectName: "protocolSelectionDrawer"

        anchors.fill: parent

        expandedStateContent: Item {
            id: protocolDrawerContainer

            implicitHeight: root.height * 0.5

            Component.onCompleted: {
                protocolSelectionDrawer.expandedHeight = protocolDrawerContainer.implicitHeight
            }

            ColumnLayout {
                id: protocolDrawerHeader

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 16

                BackButtonType {
                    id: protocolDrawerBackButton

                    Layout.fillWidth: true

                    backButtonImage: "qrc:/images/controls/arrow-left.svg"
                    backButtonFunction: function() { protocolSelectionDrawer.closeTriggered() }
                }

                Header2Type {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16

                    headerText: qsTr("VPN protocol")
                }
            }

            ListViewType {
                id: protocolDrawerListView

                anchors.top: protocolDrawerHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 16

                model: root.apiAvailableProtocols

                ButtonGroup {
                    id: protocolDrawerButtonGroup
                }

                delegate: Item {
                    implicitWidth: protocolDrawerListView.width
                    implicitHeight: protocolDrawerDelegate.implicitHeight

                    ColumnLayout {
                        id: protocolDrawerDelegate

                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        VerticalRadioButton {
                            id: protocolDrawerRadioButton

                            Layout.fillWidth: true

                            text: root.protocolDisplayName(modelData)

                            ButtonGroup.group: protocolDrawerButtonGroup

                            checkable: !ConnectionController.isConnected
                            checked: modelData === root.apiCurrentProtocol

                            onClicked: {
                                protocolSelectionDrawer.closeTriggered()

                                if (modelData === root.apiCurrentProtocol) {
                                    return
                                }

                                if (ConnectionController.isConnected) {
                                    PageController.showNotificationMessage(qsTr("Cannot change protocol during active connection"))
                                    return
                                }

                                PageController.showBusyIndicator(true)
                                ServersUiController.setProcessedServerId(ServersUiController.defaultServerId)
                                SubscriptionUiController.setCurrentProtocol(ServersUiController.defaultServerId, modelData)
                                if (!SubscriptionUiController.updateServiceFromGateway(ServersUiController.defaultServerId, "", "", true)) {
                                    SubscriptionUiController.setCurrentProtocol(ServersUiController.defaultServerId, root.apiCurrentProtocol)
                                }
                                root.updateApiProtocolState()
                                PageController.showBusyIndicator(false)
                            }

                            Keys.onEnterPressed: protocolDrawerRadioButton.clicked()
                            Keys.onReturnPressed: protocolDrawerRadioButton.clicked()
                        }

                        DividerType {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
