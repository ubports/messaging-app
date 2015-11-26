import QtQuick 2.0
import Ubuntu.Components 1.3

UbuntuShape {
    id: thumbnail
    property int index
    property string filePath

    signal pressAndHold()

    width: units.gu(8)
    height: units.gu(8)

    Icon {
        anchors.centerIn: parent
        width: units.gu(6)
        height: units.gu(6)
        name: "attachment"
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            thumbnail.pressAndHold()
        }
    }
}
