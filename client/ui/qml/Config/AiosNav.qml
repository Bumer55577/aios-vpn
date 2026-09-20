pragma Singleton

import QtQuick

// AIOS: внутренняя навигация между вкладками нижнего бара.
// Сигналы ловятся в PageStart.qml (tabBarStackView).
QtObject {
    signal goToHomeTab()
    signal goToServersTab()
    signal goToProfileTab()
}
