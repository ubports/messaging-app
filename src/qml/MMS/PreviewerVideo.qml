/*
 * Copyright 2012, 2013, 2014, 2015 Canonical Ltd.
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
import QtMultimedia 5.0
import Ubuntu.Components 1.3
import Ubuntu.Content 0.1
import Ubuntu.Thumbnailer 0.1
import messagingapp.private 0.1
import ".."

Previewer {
    title: i18n.tr("Video Preview")
    clip: true

    onAttachmentChanged: {
        var tmpFile = FileOperations.getTemporaryFile(".mp4")
        if (FileOperations.link(attachment.filePath, tmpFile)) {
            videoPlayer.source = tmpFile;
        } else {
            console.log("MMSVideo: Failed to link", attachment.filePath, "to", tmpFile)
        }
    }

    Video {
        id: videoPlayer
        anchors.fill: parent
        autoPlay: true
    }

    MouseArea {
        id: playArea
        anchors.fill: parent
        onPressed: {
            if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                videoPlayer.pause()
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom

        width: videoPlayer.width
        height: units.gu(7)

        color: "black"
        opacity: videoPlayer.status != MediaPlayer.Loading && videoPlayer.playbackState !== MediaPlayer.PlayingState ? 0.8 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0
 
        Row {
            anchors.centerIn: parent
            spacing: units.gu(2)
            Icon {
                width: units.gu(5)
                height: units.gu(5)
                name: "media-playback-start"
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: videoPlayer.play();
                }
            }
            Icon {
                width: units.gu(5)
                height: units.gu(5)
                name: "reload"
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        videoPlayer.stop();
                        videoPlayer.play();
                    }
                }
            }
        }
    }
}
