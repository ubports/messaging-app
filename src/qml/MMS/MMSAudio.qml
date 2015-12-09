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
import Ubuntu.Components.Themes.Ambiance 1.3
import messagingapp.private 0.1
import ".."
import "../dateUtils.js" as DateUtils

MMSBase {
    id: audioDelegate

    height: units.gu(5)
    width: units.gu(28)
    property string textColor: incoming ? "#5D5D5D" : "#FFFFFF"
    swipeLocked: audioPlayer.playing

    onAttachmentChanged: {
        var tmpFile = FileOperations.getTemporaryFile(".ogg")
        if (FileOperations.link(attachment.filePath, tmpFile)) {
            audioPlayer.source = tmpFile;
        } else {
            console.log("MMSAudio: Failed to link", attachment.filePath, "to", tmpFile)
        }
    }

    Rectangle {
        id: shape
        radius: units.gu(1)
        smooth: true
        anchors.top: parent.top
        width: parent.width
        height: parent.height
        color: incoming ? "#FFFFFF" : "#3fb24f"
        border.color: incoming ? "#888888" : "transparent"
    }

    Audio {
        id: audioPlayer
        objectName: "audioPlayer"

        readonly property bool playing: audioPlayer.playbackState == Audio.PlayingState
        readonly property bool paused: audioPlayer.playbackState == Audio.PausedState
        readonly property bool stopped: audioPlayer.playbackState == Audio.StoppedState
    }

    TransparentButton {
        id: playButton
        objectName: "playButton"

        anchors {
            left: parent.left
            leftMargin: units.gu(1)
            verticalCenter: shape.verticalCenter
        }

        spacing: units.gu(1)
        sideBySide: true
        enabled: audioPlayer.source != ""
        iconColor: audioDelegate.textColor
        iconName: audioPlayer.playing ? "media-playback-pause" : "media-playback-start"

        textSize: FontUtils.sizeToPixels("x-small")
        textColor: audioDelegate.textColor
        text: {
            if (audioPlayer.playing || audioPlayer.paused) {
                return DateUtils.formattedTime(audioPlayer.position/ 1000)
            }
            if (audioPlayer.duration > 0) {
                return DateUtils.formattedTime(audioPlayer.duration / 1000)
            }
            return ""
        }

        onClicked: {
            if (audioPlayer.playing) {
                audioPlayer.pause()
            } else {
                audioPlayer.play()
            }
        }
    }

    Slider {
        id: slider
        Connections {
            target: audioPlayer
            onDurationChanged: {
                if (slider.maximumValue == 100) {
                    slider.maximumValue = audioPlayer.duration
                }
            }
        }
        style: SliderStyle {
            Component.onCompleted: thumb.visible = false
            Connections {
                target: audioPlayer
                onPlaybackStateChanged: {
                    thumb.visible = !audioPlayer.stopped
                    if (!thumb.visible) {
                        audioPlayer.seek(0)
                    }
                }
            }
        }
        enabled: !audioPlayer.stopped
        function formatValue(v) { return DateUtils.formattedTime(v/1000) }
        anchors {
            left: playButton.right
            right: deliveryStatus.left
            leftMargin: units.gu(1)
            rightMargin: units.gu(2)
            verticalCenter: shape.verticalCenter
        }
        height: units.gu(3)
        minimumValue: 0.0
        maximumValue: 100
        value: audioPlayer.position
        activeFocusOnPress: false
        onPressedChanged: {
            if (!pressed) {
                if (audioPlayer.playing || audioPlayer.paused) {
                    audioPlayer.seek(value)
                } else {
                    audioPlayer.muted = true
                    // we only get the duration while playing
                    audioPlayer.play()
                    audioPlayer.pause()
                    if (audioPlayer.duration == 100) {
                        audioPlayer.seek((audioPlayer.duration*value)/100)
                    } else {
                        audioPlayer.seek(value)
                    }
                    audioPlayer.muted = false
                    
                }
                value = Qt.binding(function(){ return audioPlayer.position})
            }
        }
    }

    DeliveryStatus {
       id: deliveryStatus
       status: textMessageStatus
       enabled: showDeliveryStatus
       anchors {
           right: parent.right
           rightMargin: units.gu(0.5)
           verticalCenter: slider.verticalCenter
       }
    }
}
