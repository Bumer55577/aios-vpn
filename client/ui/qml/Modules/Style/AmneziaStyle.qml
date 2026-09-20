pragma Singleton

import QtQuick

QtObject {
    property QtObject color: QtObject {
        readonly property color transparent: 'transparent'
        readonly property color paleGray: '#D7D8DB'
        readonly property color lightGray: '#C1C2C5'
        readonly property color mutedGray: '#878B91'
        readonly property color charcoalGray: '#494B50'
        readonly property color slateGray: '#2C2D30'
        readonly property color onyxBlack: '#1C1D21'
        readonly property color midnightBlack: '#060609' // AIOS: фон прототипа
        readonly property color goldenApricot: goldenApricotString // AIOS: золото #E6B64C
        readonly property color benefitsPanelBackground: '#1C1C1E'
        readonly property color softViolet: '#A87BE2'
        readonly property color burntOrange: '#A85809'
        readonly property color mutedBrown: '#84603D'
        readonly property color richBrown: '#633303'
        readonly property color deepBrown: '#402102'
        readonly property color vibrantRed: '#EB5757'
        readonly property color vibrantGreen: '#3FBF6B'
        readonly property color deepMagenta: '#950051'
        readonly property color darkCharcoal: '#261E1A'
        readonly property color pearlGray: '#EAEAEC'

        readonly property color sheerWhite: Qt.rgba(1, 1, 1, 0.12)
        readonly property color translucentWhite: Qt.rgba(1, 1, 1, 0.08)
        readonly property color barelyTranslucentWhite: Qt.rgba(1, 1, 1, 0.05)
        readonly property color translucentMidnightBlack: Qt.rgba(14/255, 14/255, 17/255, 0.8)
        readonly property color softGoldenApricot: Qt.rgba(251/255, 178/255, 106/255, 0.3)
        readonly property color mistyGray: Qt.rgba(215/255, 216/255, 219/255, 0.8)
        readonly property color cloudyGray: Qt.rgba(215/255, 216/255, 219/255, 0.65)
        readonly property color translucentRichBrown: Qt.rgba(99/255, 51/255, 3/255, 0.26)
        readonly property color translucentSlateGray: Qt.rgba(85/255, 86/255, 92/255, 0.13)
        readonly property color translucentOnyxBlack: Qt.rgba(28/255, 29/255, 33/255, 0.13)

        readonly property string goldenApricotString: '#E6B64C' // AIOS gold

        // AIOS: производные оттенки золота из прототипа
        readonly property color goldLight: '#F4D98B'
        readonly property color goldDark: '#C9962E'
        readonly property color goldInk: '#231806'
        readonly property color goldBorder: Qt.rgba(230/255, 182/255, 76/255, 0.13)

        readonly property color backgroundBase: '#060609' // AIOS: глубокий чёрный
        readonly property color surfaceBase: '#101015'
        readonly property color surfaceHovered: '#17171D'
        readonly property color surfacePressed: '#2C2D30'
        readonly property color surfaceInverse: '#E4E4E7'
        readonly property color surfaceInverseHovered: '#D4D4D8'
        readonly property color surfaceInversePressed: '#A1A1AA'
        readonly property color textPrimary: '#F3EEE1' // AIOS: тёплый кремовый текст
        readonly property color textTertiary: '#98917F' // AIOS: приглушённый тёплый серый
        readonly property color textInverted: '#09090B'
        readonly property color textStaticWhite: '#FFFFFF'
        readonly property color borderSoft: '#3F3F46'
        readonly property color accentSuccess: '#3DDC84' // AIOS: зелёный статус
        readonly property color accentWarning: '#E6B64C' // AIOS: золото вместо жёлтого
    }
}
