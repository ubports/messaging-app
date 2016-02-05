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
import Ubuntu.Components.Themes.Ambiance 1.3
import "dateUtils.js" as DateUtils

Item {
    id: playbackBar

    signal resetRequested()
    property string source: ""
    property int duration: audioPlayer.duration
    readonly property bool playing: audioPlayer.playing

    Loader {
        id: audioPlayer
        readonly property bool playing: ready ? item.playing : false
        readonly property bool paused: ready ? item.paused : false
        readonly property bool stopped: ready ? item.stopped : false
        readonly property int position: ready ? item.position : 0
        readonly property int duration: ready ? item.duration : 0
        readonly property bool ready: status == Loader.Ready
        readonly property int playbackState: ready ? item.playbackState : Audio.StoppedState
        function play() { 
            audioPlayer.active = true
            item.play() 
        }
        function stop() {
            item.stop()
            audioPlayer.active = false
        }
        function pause() { item.pause() }
        function seek(pos) { item.seek(pos) }
        active: false
        sourceComponent: audioPlayerComponent
    }

    Component {
        id: audioPlayerComponent
        Audio {
            id: audioPlayer1
            readonly property bool playing: audioPlayer1.playbackState == Audio.PlayingState
            readonly property bool paused: audioPlayer1.playbackState == Audio.PausedState
            readonly property bool stopped: audioPlayer1.playbackState == Audio.StoppedState
            source: playbackBar.source
        }
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
            iconName: audioPlayer.playing ? "media-playback-pause" : "media-playback-start"

            textSize: FontUtils.sizeToPixels("x-small")
            text: {
                if (audioPlayer.playing || audioPlayer.paused) {
                    return DateUtils.formattedTime(audioPlayer.position/ 1000)
                }
                return DateUtils.formattedTime(playbackBar.duration / 1000)
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
                    slider.maximumValue = audioPlayer.duration
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
                top: parent.top
                bottom: parent.bottom
                left: playButton.right
                right: parent.right
                leftMargin: units.gu(1)
            }
            height: units.gu(3)
            minimumValue: 0.0
            maximumValue: 100
            value: audioPlayer.stopped ? 0 : audioPlayer.position
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
                    value = Qt.binding(function(){ return audioPlayer.stopped ? 0 : audioPlayer.position })
                }
            }
        }
    }
}

