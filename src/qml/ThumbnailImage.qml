import QtQuick 2.0
import Ubuntu.Components 1.2

UbuntuShape {
    id: thumbnail
    property int index
    property string filePath

    signal pressAndHold()

    width: childrenRect.width
    height: childrenRect.height

    image: Image {
        id: avatarImage
        width: units.gu(8)
        height: units.gu(8)
        sourceSize.height: height
        sourceSize.width: width
        fillMode: Image.PreserveAspectCrop
        source: filePath
        asynchronous: true
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            thumbnail.pressAndHold()
        }
    }
}
