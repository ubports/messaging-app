import QtQuick 2.0
import Ubuntu.Components 1.3

BottomEdge {
    id: bottomEdge
    height: parent.height
    hint.text: i18n.tr("+")
    contentComponent: Messages { height: mainPage.height }
}

