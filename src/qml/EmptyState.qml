import QtQuick 2.0
import Ubuntu.Components 1.3

Item {
    id: emptyStateScreen

    property alias labelVisible: emptyStateLabel.visible

    anchors {
        left: parent.left
        leftMargin: units.gu(6)
        right: parent.right
        rightMargin: units.gu(6)
        verticalCenter: parent.verticalCenter
    }
    height: childrenRect.height
    Icon {
        id: emptyStateIcon
        anchors.top: emptyStateScreen.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: units.gu(5)
        width: height
        opacity: 0.3
        name: "message"
    }
    Label {
        id: emptyStateLabel
        anchors.top: emptyStateIcon.bottom
        anchors.topMargin: units.gu(2)
        anchors.left: parent.left
        anchors.right: parent.right
        text: i18n.tr("Compose a new message by swiping up from the bottom of the screen.")
        color: "#5d5d5d"
        fontSize: "x-large"
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
