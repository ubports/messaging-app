/*
 * Copyright 2015 Canonical Ltd.
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
import messagingapp.private 0.1
import ".."

MMSBase {
    id: audioDelegate

    height: units.gu(7)
    width: units.gu(20)

    function formattedTime(time) {
        var d = new Date(0, 0, 0, 0, 0, time)
        return d.getHours() == 0 ? Qt.formatTime(d, "mm:ss") : Qt.formatTime(d, "h:mm:ss")
    }

    onAttachmentChanged: {
        var tmpFile = FileOperations.getTemporaryFile(".ogg")
        if (FileOperations.link(attachment.filePath, tmpFile)) {
            audioPlayer.source = tmpFile;
        } else {
            console.log("MMSAudio: Failed to link", attachment.filePath, "to", tmpFile)
        }
    }

    Audio {
        id: audioPlayer

        readonly property bool playing: audioPlayer.playbackState == Audio.PlayingState
    }

    TransparentButton {
        id: playButton

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: shape.verticalCenter
        }

        enabled: audioPlayer.source != ""
        iconColor: "grey"
        iconName: audioPlayer.playing ? "media-playback-stop" : "media-playback-start"

        textSize: FontUtils.sizeToPixels("x-small")
        text: {
            if (audioPlayer.playing) {
                return audioDelegate.formattedTime(audioPlayer.position/ 1000)
            }
            if (audioPlayer.duration > 0) {
                return audioDelegate.formattedTime(audioPlayer.duration / 1000)
            }
            return ""
        }

        onClicked: {
            if (audioPlayer.playing) {
                audioPlayer.stop()
            } else {
                audioPlayer.play()
            }
        }
    }

    Image {
        anchors {
            left: playButton.right
            right: parent.right
            leftMargin: units.gu(1)
            rightMargin: units.gu(2)
            verticalCenter: shape.verticalCenter
        }

	height: units.gu(3)

        source: Qt.resolvedUrl("../assets/sine.svg")
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
