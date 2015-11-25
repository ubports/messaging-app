import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1

Item {
    id: attachment

    readonly property int contactsCount:vcardParser.contacts ? vcardParser.contacts.length : 0
    property int index
    property string filePath
    property alias vcard: vcardParser
    property string contactDisplayName: {
        if (contactsCount > 0)  {
            var contact = vcard.contacts[0]
            if (contact.displayLabel.label && (contact.displayLabel.label != "")) {
                return contact.displayLabel.label
            } else if (contact.name) {
                var contacFullName  = contact.name.firstName
                if (contact.name.midleName) {
                    contacFullName += " " + contact.name.midleName
                }
                if (contact.name.lastName) {
                    contacFullName += " " + contact.name.lastName
                }
                return contacFullName
            }
            return i18n.tr("Unknown contact")
        }
        return ""
    }
    property string title: {
        var result = attachment.contactDisplayName
        if (attachment.contactsCount > 1) {
            return result + " (+%1)".arg(attachment.contactsCount-1)
        } else {
            return result
        }
    }

    height: units.gu(6)
    width: textEntry.width

    ContactAvatar {
        id: avatar

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        contactElement: attachment.contactsCount === 1 ? attachment.vcard.contacts[0] : null
        fallbackAvatarUrl: attachment.contactsCount === 1 ? "image://theme/contact" : "image://theme/contact-group"
        fallbackDisplayName: attachment.contactsCount === 1 ? attachment.contactDisplayName : ""
        width: height
    }
    Label {
        id: label

        anchors {
            left: avatar.right
            leftMargin: units.gu(1)
            top: avatar.top
            bottom: avatar.bottom
            right: parent.right
            rightMargin: units.gu(1)
        }

        verticalAlignment: Text.AlignVCenter
        text: attachment.title
        elide: Text.ElideMiddle
        color: UbuntuColors.lightAubergine
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            Qt.inputMethod.hide()
            activeAttachmentIndex = index
            PopupUtils.open(attachmentPopover, parent)
        }
    }
    VCardParser {
        id: vcardParser

        vCardUrl: attachment ? Qt.resolvedUrl(attachment.filePath) : ""
    }
}

