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

import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.3

Item {
    id: playbackBar

    signal resetRequested()
    property alias source: audioPlayer.source
    property int duration: 0
    property alias playing: audioPlayer.playing

    function formattedTime(time) {
        var d = new Date(0, 0, 0, 0, 0, time)
        return d.getHours() == 0 ? Qt.formatTime(d, "mm:ss") : Qt.formatTime(d, "h:mm:ss")
    }

    Audio {
        id: audioPlayer
        readonly property bool playing: audioPlayer.playbackState == Audio.PlayingState
    }

    TransparentButton {
        id: closeButton
        objectName: "closeButton"

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }

        iconName: "close"

        onClicked: {
            playbackBar.resetRequested()
        }
    }

    Item {
        id: audioPreview
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: closeButton.right
            right: parent.right
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            leftMargin: units.gu(3)
            rightMargin: units.gu(1)
        }

        TransparentButton {
            id: playButton

            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(0.5)
            }

            iconColor: "grey"
            iconName: audioPlayer.playing ? "media-playback-stop" : "media-playback-start"

            textSize: FontUtils.sizeToPixels("x-small")
            text: {
                if (audioPlayer.playing) {
                    return playbackBar.formattedTime(audioPlayer.position/ 1000)
                }
                return playbackBar.formattedTime(playbackBar.duration / 1000)
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
                top: parent.top
                bottom: parent.bottom
                left: playButton.right
                right: parent.right
                leftMargin: units.gu(1)
            }

            source: Qt.resolvedUrl("./assets/sine.svg")
        }
    }


}

