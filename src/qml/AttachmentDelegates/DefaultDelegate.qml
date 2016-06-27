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

import QtQuick 2.2
import Ubuntu.Components 1.3
import ".."

BaseDelegate {
    id: defaultDelegate

    property string unknownLabel: {
        if (startsWith(attachment.contentType, "audio/") ) {
            return i18n.tr("Audio attachment not supported")
            root.textAttachements.push(attachment)
        } else if (startsWith(attachment.contentType, "video/")) {
            return i18n.tr("Video attachment not supported")
        }
        return i18n.tr("File type not supported") 
    }
    height: units.gu(15)
    width: Math.max(unknownAttachmentLabel.paintedWidth+units.gu(2), units.gu(27))

    Image {
        id: unknownAttachmentImage
        fillMode: Image.PreserveAspectFit
        anchors.centerIn: shape
        anchors.verticalCenterOffset: -unknownAttachmentLabel.height/2
        smooth: true
        source: Qt.resolvedUrl("../assets/transfer-unsupported01.svg")
        asynchronous: false
        height: Math.min(implicitHeight, units.gu(8))
        width: Math.min(implicitWidth, units.gu(27))
        cache: false
    }

    Label {
        id: unknownAttachmentLabel
        color: "gray"
        text: unknownLabel
        anchors.horizontalCenter: unknownAttachmentImage.horizontalCenter
        anchors.top: unknownAttachmentImage.bottom
    }

    UbuntuShape {
        id: shape
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        color: "gray"
        opacity: 0.2
    }
}
