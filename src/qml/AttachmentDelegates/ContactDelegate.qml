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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import ".."

BaseDelegate {
    id: vcardDelegate

    readonly property bool error: (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming
    readonly property int contactsCount:vcardParser.contacts ? vcardParser.contacts.length : 0
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
        var result = vcardDelegate.contactDisplayName
        if (vcardDelegate.contactsCount > 1) {
            return result + " (+%1)".arg(vcardDelegate.contactsCount-1)
        } else {
            return result
        }
    }

    previewer: vcardDelegate.contactsCount > 1 ? "AttachmentDelegates/PreviewerMultipleContacts.qml" : "AttachmentDelegates/PreviewerSingleContact.qml"
    height: units.gu(9.5)
    width: units.gu(27)

    Rectangle {
        id: bubble

        anchors.fill: parent
        color: {
            if (error) {
                return theme.palette.normal.negative
            } else if (sending) {
                return theme.palette.normal.base
            } else if (incoming) {
                return theme.palette.normal.background
            } else {
                return theme.palette.normal.positive
            }
        }
        border.color: incoming ? theme.palette.normal.base : "transparent"
        radius: units.gu(1)

        ContactAvatar {
            id: avatar

            contactElement: (vcardDelegate.contactsCount === 1) ? vcardDelegate.vcard.contacts[0] : null
            anchors {
                top: parent.top
                topMargin: units.gu(1)
                bottom: parent.bottom
                bottomMargin: units.gu(2.5)
                left: parent.left
                leftMargin: units.gu(1)
            }
            fallbackAvatarUrl: vcardDelegate.contactsCount === 1 ? "image://theme/contact" : "image://theme/contact-group"
            fallbackDisplayName: vcardDelegate.contactsCount === 1 ? vcardDelegate.contactDisplayName : ""
            width: height
        }

        Label {
            id: contactName

            anchors {
                left: avatar.right
                leftMargin: units.gu(1)
                top: avatar.top
                bottom: avatar.bottom
                right: parent.right
                rightMargin: units.gu(1)
            }

            verticalAlignment: Text.AlignVCenter
            text: vcardDelegate.title
            elide: Text.ElideMiddle
            color: incoming ? theme.palette.normal.backgroundText : "#ffffff"
        }

        Label {
            anchors{
                left: parent.left
                bottom: parent.bottom
                leftMargin: incoming ? units.gu(2) : units.gu(1)
                bottomMargin: units.gu(0.5)
            }
            fontSize: "xx-small"
            text: Qt.formatTime(timestamp).toLowerCase()
            color: incoming ? theme.palette.normal.backgroundSecondaryText : "white"
        }
    }

    VCardParser {
        id: vcardParser

        vCardUrl: attachment ? Qt.resolvedUrl(attachment.filePath) : ""
    }

    DeliveryStatus {
       id: deliveryStatus
       messageStatus: textMessageStatus
       enabled: showDeliveryStatus
       anchors {
           right: parent.right
           rightMargin: units.gu(0.5)
           bottom: parent.bottom
           bottomMargin: units.gu(0.5)
       }
    }
}
