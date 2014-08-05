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
import QtMultimedia 5.0
import ".."

MMSBase {
    id: videoDelegate
    property var attachment
    property bool incoming
    property string previewer: "MMS/PreviewerVideo.qml"
    anchors.left: parent.left
    anchors.right: parent.right
    onItemClicked: {
        if (checkClick(bubble, mouse)) {
            attachmentClicked()
        }
    }
    state: incoming ? "incoming" : "outgoing"
    states: [
        State {
            name: "incoming"
            AnchorChanges {
                target: bubble
                anchors.left: parent.left
                anchors.right: undefined
            }
            PropertyChanges {
                target: bubble
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
            }
        },
        State {
            name: "outgoing"
            AnchorChanges {
                target: bubble
                anchors.left: undefined
                anchors.right: parent.right
            }
            PropertyChanges {
                target: bubble
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
            }
        }
    ]
    height: bubble.height + units.gu(1)
    clip: true
    Item {
        id: bubble
        anchors.top: parent.top
        width: videoOutput.width + units.gu(3)
        height: videoOutput.height + units.gu(2)

        MediaPlayer {
            id: video
            autoLoad: true
            autoPlay: false
            source: attachment.filePath
            onStatusChanged: {
                if (status === MediaPlayer.Loaded) {
                    // FIXME: there is no way to show the thumbnail
                    video.play(); video.stop();

                    // resize videoOutput, as width is not set
                    // properly when using PreserveAspectFit
                    if (videoOutput.height > units.gu(25)) {
                        var percentageResized = units.gu(25)*100/(metaData.resolution.height)
                        videoOutput.height = units.gu(25)
                        videoOutput.width = (metaData.resolution.width*percentageResized)/100
                    }
                    if (videoOutput.width > units.gu(35)) {
                        percentageResized = units.gu(35)*100/(metaData.resolution.width)
                        videoOutput.width = units.gu(35)
                        videoOutput.height = (metaData.resolution.height*percentageResized)/100
                    }
                }
            }
        }
        VideoOutput {
            id: videoOutput
            source: video
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: incoming ? units.gu(0.5) : -units.gu(0.5)
        }

        Rectangle {
            color: "black"
            opacity: 0.8
            anchors.fill: videoOutput
            Icon {
                name: "media-playback-start"
                width: units.gu(4)
                height: units.gu(4)
                anchors.centerIn: parent
            }
        }
    }
}
