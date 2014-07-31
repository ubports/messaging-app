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
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1
import ".."

MMSBase {
    id: imageDelegate
    property string previewer: "MMS/PreviewerImage.qml"
    onItemClicked: {
        if(!bubble.contains(Qt.point(mouse.x, mouse.y))) {
            attachmentClicked()
        }
    }

    height: imageAttachment.height
    UbuntuShape {
        id: bubble
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: image.width
        height: image.height

        image: Image {
            id: imageAttachment

            width: sourceSize.width > units.gu(30) ? units.gu(30) : sourceSize.width
            height: Math.min(sourceSize.height, units.gu(14))
            fillMode: Image.PreserveAspectCrop
            smooth: true
            source: attachment.filePath
            visible: false
        }
    }

    Loader {
        active: (index == visibleAttachments-1) && !incoming && mmsText == "" && (inProgress || failed)
        visible: active
        height: active ? item.height : 0
        sourceComponent: statusIcon
        anchors.right: bubble.left
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: bubble.verticalCenter
    }
}
