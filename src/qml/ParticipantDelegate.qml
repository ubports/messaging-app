/*
 * Copyright 2016 Canonical Ltd.
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

ListItem {
    id: participantDelegate

    property variant participant: null

    anchors {
        left: parent.left
        right: parent.right
        rightMargin: units.gu(1)
    }
    height: layout.height

    ListItemLayout {
        id: layout
        enabled: participant.state !== 2 //disable pending participants
        title.text: participant.alias !== "" ? participant.alias : participant.identifier
        subtitle.text: {
            // FIXME: use enums instead of hardcoded values
            if (participant.roles == 3) {
                return i18n.tr("Admin")
            }
            if (participant.state == 2) {
                return i18n.tr("Pending")
            }
            return ""
        }

        ContactAvatar {
            id: avatar
            enabled: true
            fallbackAvatarUrl: {
                if (participant && participant.avatar && participant.avatar !== "") {
                    console.log(participant.avatar)
                    return participant.avatar
                } else if (participant && participant.alias === "") {
                    return "image://theme/contact"
                }
                return ""
            }
            fallbackDisplayName: participant.alias
            showAvatarPicture: fallbackAvatarUrl !== ""
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(6)
            width: units.gu(6)
            SlotsLayout.position: SlotsLayout.Leading
        }
    }
}

