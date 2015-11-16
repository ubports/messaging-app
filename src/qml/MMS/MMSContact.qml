/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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

import QtQuick 2.2
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

MMSBase {
    id: vcardDelegate

    readonly property bool error: (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming

    previewer: vcardParser.contacts.length > 1 ? "MMS/PreviewerMultipleContacts.qml" : "MMS/PreviewerSingleContact.qml"
    height: units.gu(8)
    width: units.gu(27)

    function contactName(contact)
    {
        if (contact.displayLabel.label != "") {
            return contact.displayLabel.label
        } else {
            var contacFullName  = contact.name.firstName
            if (contact.name.midleName) {
                conactFullName += " " + contact.name.midleName
            }
            if (contact.name.lastName) {
                conactFullName += " " + contact.name.lastName
            }
            return contactFullName
        }
    }

    Rectangle {
        id: bubble

        anchors.fill: parent
        color: {
            if (error) {
                return "#fc4949"
            } else if (sending) {
                return "#b2b2b2"
            } else if (incoming) {
                return "#ffffff"
            } else {
                return "#3fb24f"
            }
        }
        border.color: "#ACACAC"
        radius: height * 0.1

        ContactAvatar {
            id: avatar

            contactElement: (vcardParser.contacts.length === 1) ? vcardParser.contacts[0] : null
            anchors {
                top: parent.top
                topMargin: units.gu(1)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
                left: parent.left
                leftMargin: units.gu(1)
            }
            fallbackAvatarUrl: (vcardParser.contacts.length === 1) ? "image://theme/contact" : "image://theme/contact-group"
            fallbackDisplayName: (vcardParser.contacts.length === 1) ? vcardDelegate.contactName(vcardParser.contacts[0]) : ""
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
            text: {
                if (vcardParser.contacts.length > 1) {
                    return vcardDelegate.contactName(vcardParser.contacts[0]) + " (+%1)".arg(vcardParser.contacts.length-1)
                } else if (vcardParser.contacts.length === 1) {
                    return vcardDelegate.contactName(vcardParser.contacts[0])
                }
            }
            elide: Text.ElideMiddle
            color: incoming ? UbuntuColors.darkGrey : "#ffffff"
        }
    }

    VCardParser {
        id: vcardParser

        vCardUrl: attachment ? Qt.resolvedUrl(attachment.filePath) : ""
    }
}
