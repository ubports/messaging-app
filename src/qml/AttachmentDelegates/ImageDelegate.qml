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
import QtGraphicalEffects 1.0
import ".."

BaseDelegate {
    id: imageDelegate

    previewer: "AttachmentDelegates/PreviewerImage.qml"
    height: bubble.height + messageFooter.height + units.gu(0.5)
    width: bubble.width

    UbuntuShape {
        id: bubble
        anchors.top: parent.top
        width: imageAttachment.width
        height: imageAttachment.height

        image: Image {
            id: imageAttachment
            objectName: "imageAttachment"
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: attachment.filePath
            visible: false
            asynchronous: messageList.moving ? true: false
            width: Math.min(implicitWidth, units.gu(27))
            cache: false
            sourceSize.width: units.gu(27)

            onStatusChanged:  {
                if (status === Image.Error) {
                    source = "image://theme/image-missing"
                    width = 128
                    height = 128
                }
            }
        }      

        Row {
            id: messageFooter
            visible: imageDelegate.lastItem
            spacing: units.gu(1)

            anchors {
                top: parent.bottom
                topMargin: units.gu(0.5)
                right: parent.right
                rightMargin: units.gu(1)
            }

            Label {
                id: dateLbl
                anchors.bottom: parent.bottom
                fontSize: "xx-small"
                text: Qt.formatTime(timestamp).toLowerCase()
            }

            DeliveryStatus {
               id: deliveryStatus
               anchors.verticalCenter: dateLbl.verticalCenter
               messageStatus: textMessageStatus
               enabled: showDeliveryStatus

               ColorOverlay {
                   anchors.fill: deliveryStatus
                   source: deliveryStatus
                   color: dateLbl.color
               }
            }
        }
    }
}
