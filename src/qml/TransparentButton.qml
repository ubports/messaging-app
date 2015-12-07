import QtQuick 2.0
import Ubuntu.Components 1.2

Item {
    id: button

    width: sideBySide ? iconShape.width + spacing + label.width : iconShape.width
    height: sideBySide ? iconShape.height : iconShape.height + label.height + spacing

    property alias iconName: icon.name
    property alias iconSource: icon.source
    property alias iconColor: icon.color
    property int iconSize: units.gu(2)
    property alias iconRotation: icon.rotation
    property alias text: label.text
    property alias textSize: label.font.pixelSize
    property alias textColor: label.color
    property int spacing: 0
    property bool sideBySide: false
    property bool iconPulsate: false

    property alias drag: mouseArea.drag

    signal clicked()
    signal pressed()
    signal released()

    Item {
        id: iconShape
        height: iconSize
        width: iconSize
        anchors {
            left: parent.left
            right: sideBySide ? undefined : parent.right
            top: parent.top
        }
        Icon {
            id: icon
            anchors.centerIn: parent
            height: iconSize
            width: height
            color: "gray"
            Behavior on rotation {
                UbuntuNumberAnimation { }
            }
            SequentialAnimation {
                running: iconPulsate
                loops: Animation.Infinite
                NumberAnimation { target: icon; property: "scale"; from: 1; to: 0.7; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { target: icon; property: "scale"; from: 0.7; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors {
            fill: iconShape
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
            left: sideBySide ? iconShape.right : parent.left
            right: sideBySide ? undefined : parent.right
            bottom: sideBySide ? undefined : parent.bottom
            verticalCenter: sideBySide ? iconShape.verticalCenter : undefined
            leftMargin: sideBySide ? spacing : undefined
        }
        horizontalAlignment: sideBySide ? undefined : Text.AlignHCenter
        verticalAlignment: sideBySide ? Text.AlignVCenter : Text.AlignBottom
        font.family: "Ubuntu"
        font.pixelSize: FontUtils.sizeToPixels("small")
    }
}
