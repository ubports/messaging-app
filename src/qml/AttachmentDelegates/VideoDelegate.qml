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
import Ubuntu.Thumbnailer 0.1
import ".."

BaseDelegate {
    id: videoDelegate

    previewer: "AttachmentDelegates/PreviewerVideo.qml"
    height: videoAttachment.height
    width: videoAttachment.width

    UbuntuShape {
        id: bubble
        anchors.top: parent.top
        width: image.width
        height: image.height

        image: Image {
            id: videoAttachment
            objectName: "videoAttachment"

            fillMode: Image.PreserveAspectCrop
            smooth: true
            source: "image://thumbnailer/" + attachment.filePath
            visible: false
            asynchronous: true
            height: Math.min(implicitHeight, units.gu(14))
            width: Math.min(implicitWidth, units.gu(27))
            cache: false

            sourceSize.width: units.gu(27)
            sourceSize.height: units.gu(27)

            onStatusChanged:  {
                if (status === Image.Error) {
                    source = "image://theme/image-missing"
                    width = 128
                    height = 128
                }
            }
        }

        Icon {
            objectName: "playbackStartIcon"
            width: units.gu(3)
            height: units.gu(3)
            anchors.centerIn: parent
            name: "media-playback-start"
            color: "white"
            opacity: 0.8
        }

        Rectangle {
            visible: videoDelegate.lastItem
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "gray" }
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: units.gu(2)
            radius: bubble.height * 0.1
            Label {
                anchors{
                    left: parent.left
                    bottom: parent.bottom
                    leftMargin: incoming ? units.gu(2) : units.gu(1)
                    bottomMargin: units.gu(0.5)
                }
                fontSize: "xx-small"
                text: Qt.formatTime(timestamp).toLowerCase()
                color: "white"
            }
        }
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
