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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

MMSBase {
    id: vcardDelegate

    readonly property bool error: (messageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (messageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     messageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming

    previewer: "MMS/PreviewerContact.qml"
    height: bubble.height
    width: bubble.width

    Rectangle {
        id: bubble

        width: avatar.width + contactName.width + units.gu(3)
        height: avatar.height + units.gu(2)
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
        radius: height * 0.1

        ContactAvatar {
            id: avatar

            anchors {
                top: parent.top
                topMargin: units.gu(1)
                left: parent.left
                leftMargin: units.gu(1)
            }
            fallbackAvatarUrl: "image://theme/contact"
            fallbackDisplayName: contactName.name
            height: units.gu(6)
            width: units.gu(6)
        }

        Label {
            id: contactName

            property string name: application.contactNameFromVCard(attachment.filePath)

            anchors {
                verticalCenter: avatar.verticalCenter
                left: avatar.right
                leftMargin: units.gu(1)
            }

            text: name !== "" ? name : i18n.tr("Unknown contact")
            elide: Text.ElideRight
            height: paintedHeight
            width: Math.min(units.gu(27) - avatar.width,  text.length * units.gu(1))
            color: vcardDelegate.incoming ? UbuntuColors.darkGrey : "white"
        }
    }
}
