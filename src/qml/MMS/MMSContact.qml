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
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

MMSBase {
    id: vcardDelegate

    property var vcardInfo: application.contactNameFromVCard(attachment.filePath)
    readonly property bool error: (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming

    previewer: "MMS/PreviewerContact.qml"
    height: units.gu(8)
    width: units.gu(27)


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
        radius: height * 0.1

        ContactAvatar {
            id: avatar

            anchors {
                top: parent.top
                topMargin: units.gu(1)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
                left: parent.left
                leftMargin: units.gu(1)
            }
            fallbackAvatarUrl: "image://theme/contact"
            fallbackDisplayName: contactName.name
            width: height
        }

        Label {
            id: contactName


            property string name: vcardDelegate.vcardInfo["name"] !== "" ?
                                      vcardDelegate.vcardInfo["name"] :
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
                if (vcardDelegate.vcardInfo["count"] > 1) {
                    return contactName.name + " (+%1)".arg(vcardDelegate.vcardInfo["count"]-1)
                } else {
                    return contactName.name
                }
            }
            elide: Text.ElideMiddle
            color: incoming ? UbuntuColors.darkGrey : "#ffffff"
        }
    }
}
