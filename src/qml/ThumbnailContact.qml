/*
 * Copyright 2012-2016 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1

Item {
    id: attachment

    readonly property int contactsCount:vcardParser.contacts ? vcardParser.contacts.length : 0
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
        color: Theme.palette.normal.backgroundText
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            attachment.pressAndHold()
        }
    }
    VCardParser {
        id: vcardParser

        vCardUrl: attachment ? Qt.resolvedUrl(attachment.filePath) : ""
    }
}

