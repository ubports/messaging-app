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

import QtQuick 2.2
import Ubuntu.Components 1.1
import QtMultimedia 5.0
import ".."

Previewer {
    title: i18n.tr("Video Preview")
    // This previewer implements only basic video controls: play/pause/rewind
    onActionTriggered: video.pause()
    MediaPlayer {
        id: video
        autoLoad: true
        autoPlay: true
        source: attachment.filePath
    }
    VideoOutput {
        id: videoOutput
        source: video
        anchors.fill: parent
    }

    MouseArea {
        id: playArea
        anchors.fill: parent
        onPressed: {
            if (video.playbackState === MediaPlayer.PlayingState) {
                video.pause()
            }
        }
    }

    Rectangle {
        color: "black"
        visible: video.playbackState !== MediaPlayer.PlayingState
        opacity: 0.8
        anchors.fill: videoOutput
        Row {
            anchors.centerIn: parent
            Icon {
                name: "media-playback-pause"
                width: units.gu(5)
                height: units.gu(5)
                MouseArea {
                    anchors.fill: parent
                    onClicked: video.play();
                }
            }
            Icon {
                name: "media-seek-backward"
                width: units.gu(5)
                height: units.gu(5)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        video.stop();
                        video.play();
                    }
                }
            }
        }
    }
}
