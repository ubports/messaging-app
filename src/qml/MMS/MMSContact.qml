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
import ".."

MMSBase {
    id: vcardDelegate
    property string previewer: "MMS/PreviewerContact.qml"

    height: bubble.height + units.gu(2)

    Item {
        id: bubble
        anchors.top: parent.top
        width: image.width + units.gu(4)
        height: image.height + units.gu(2)
        Icon {
            id: image
            height: units.gu(6)
            width: units.gu(6)
            name: "contact"
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: incoming ? units.gu(0.5) : -units.gu(0.5)
        }
    }
    Label {
        id: contactName
        property string name: application.contactNameFromVCard(attachment.filePath)
        anchors.bottom: bubble.bottom
        anchors.left: incoming ? bubble.right : undefined
        anchors.right: !incoming ? bubble.left : undefined
        text: name !== "" ? name : i18n.tr("Unknown contact")
        height: paintedHeight
        width: paintedWidth
    }
}
