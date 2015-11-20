import QtQuick 2.0
import Ubuntu.Components 1.3

Item {
    id: button

    width: icon.width
    height: icon.height + label.height + spacing

    property alias iconName: icon.name
    property alias iconSource: icon.source
    property alias iconColor: icon.color
    property int iconSize: units.gu(2)
    property alias iconRotation: icon.rotation
    property alias text: label.text
    property alias textSize: label.font.pixelSize
    property int spacing: 0

    signal clicked()
    signal pressed()
    signal released()

    Icon {
        id: icon

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: iconSize
        width: iconSize
        color: "gray"
        Behavior on rotation {
            UbuntuNumberAnimation { }
        }
    }

    MouseArea {
        anchors {
            fill: parent
            margins: units.gu(-2)
        }
        onClicked: {
            mouse.accepted = true
            button.clicked()
        }

        onPressed: button.pressed()
        onReleased: button.released()
    }

    Text {
        id: label
        color: "gray"
        height: text !== "" ? paintedHeight : 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
        font.family: "Ubuntu"
        font.pixelSize: FontUtils.sizeToPixels("small")
    }
}
