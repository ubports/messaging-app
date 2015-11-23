import QtQuick 2.0
import Ubuntu.Components 1.2
import Ubuntu.Contacts 0.1

Item {
    id: attachment

    property int index
    property string filePath
    property var vcardInfo: application.contactNameFromVCard(attachment.filePath)

    signal pressAndHold()

    height: units.gu(6)
    width: textEntry.width

    ContactAvatar {
        id: avatar

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        fallbackAvatarUrl: "image://theme/contact"
        fallbackDisplayName: label.name
        width: height
    }
    Label {
        id: label

        property string name: attachment.vcardInfo["name"] !== "" ?
                                  attachment.vcardInfo["name"] :
                                  i18n.tr("Unknown contact")

        anchors {
            left: avatar.right
            leftMargin: units.gu(1)
            top: avatar.top
            bottom: avatar.bottom
            right: parent.right
            rightMargin: units.gu(1)
        }

        verticalAlignment: Text.AlignVCenter
        text: {
            if (attachment.vcardInfo["count"] > 1) {
                return label.name + " (+%1)".arg(attachment.vcardInfo["count"]-1)
            } else {
                return label.name
            }
        }
        elide: Text.ElideMiddle
        color: UbuntuColors.lightAubergine
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            attachment.pressAndHold()
        }
    }
}

