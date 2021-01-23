/*
 * Copyright 2020 Ubports Foundation
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
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3
import ".."

BaseDelegate {
    id: imageDelegate

    previewer: "AttachmentDelegates/PreviewerImage.qml"
    height: imageAttachment.height
    width: imageAttachment.width

    function calculateVisibility() {
        // check if item is truly visible
        var itemPosY = imageDelegate.mapToItem(messageList,0,0).y
        var isVisible = (itemPosY >= 0 && itemPosY + imageDelegate.height <= messageList.height)

        if (isVisible) {
            // do not autoplay it twice when scrolling up and down in the same conversation
            if (!attachment.played && mainView.autoplayAnimatedImage) {
                imageAttachment.playing = true
                attachment.played = true
                // prevent from infinite playing
                autoStopAnimation.start()
             }
        } else {
            imageAttachment.playing = false
            autoStopAnimation.stop()
        }

    }

    onAttachmentChanged: {
        if (!attachment.played) attachment.played = false
    }

    Connections {
        target: messageList
        onContentYChanged: {
            // just to avoid calculation on each messageList.contentY
            if (Math.round(messageList.contentY) % 8 === 0) {
                calculateVisibility()
            }
        }
    }

    // delay the calculation at image ready to have correct positions ( needed for initial load )
    Timer {
        id: delayAction
        interval: 100; running: false; repeat: false
        onTriggered: calculateVisibility()
    }

    // autoplay will end after 10 secondes max
    Timer {
        id: autoStopAnimation
        interval: 10000; running: false; repeat: false
        onTriggered: imageAttachment.playing = false
    }

    property bool isFullyVisible: (yoff > list.y && yoff + height < list.y + list.height)


    UbuntuShape {
        id: bubble
        anchors.top: parent.top
        width: imageAttachment.width
        height: imageAttachment.height

        image: AnimatedImage {
            id: imageAttachment
            objectName: "imageAttachment"

            fillMode: Image.PreserveAspectCrop
            playing: false
            source: attachment.filePath
            asynchronous: true
            height: units.gu(14)
            width:units.gu(27)
            cache: false

            onStatusChanged:  {
                if (status === Image.Error) {
                    source = "image://theme/image-missing"
                    width = 128
                    height = 128
                } else if (status == Image.Ready) {
                    delayAction.start()
                }
            }
        }

        UbuntuShape {
            id: playbackBtn
            anchors {
                right: imageAttachment.right
                bottom: imageFooter.top
                rightMargin: units.gu(1)
            }
            width: units.gu(3)
            height: width
            backgroundColor: Qt.rbga(255,255,255)
            radius: "large"

            Icon {
                anchors.fill: parent
                name: imageAttachment.playing ? "media-playback-pause" :  "media-playback-start"
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    imageAttachment.playing ? imageAttachment.playing = false: imageAttachment.playing = true
                }
            }

        }


        Rectangle {
            id: imageFooter
            visible: imageDelegate.lastItem
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
