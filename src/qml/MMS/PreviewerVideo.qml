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
    id: videoPreviewer

    title: i18n.tr("Video Preview")
    clip: true

    Component.onCompleted: {
        application.fullscreen = true
        // Load Video player after toggling fullscreen to reduce flickering
        videoLoader.active = true
    }
    Component.onDestruction: application.fullscreen = false

    Connections {
        target: application
        onFullscreenChanged: {
            videoPreviewer.head.visible = !application.fullscreen
            toolbar.collapsed = application.fullscreen
        }
    }

    Loader {
        id: videoLoader

        anchors.fill: parent
        active: false
        sourceComponent: videoComponent

        onStatusChanged: {
            if (status == Loader.Ready) {
                var tmpFile = FileOperations.getTemporaryFile(".mp4")
                if (FileOperations.link(attachment.filePath, tmpFile)) {
                    videoLoader.item.source = tmpFile
                } else {
                    console.log("MMSVideo: Failed to link", attachment.filePath, "to", tmpFile)
                }
            }
        }

        Component {
            id: videoComponent

            Video {
                id: videoPlayer
                anchors.fill: parent
                autoPlay: true
            }
        }
    }

    MouseArea {
        anchors {
            top: parent.top
            bottom: toolbar.top
            left: parent.left
            right: parent.right
        }
        onPressed: application.fullscreen = !application.fullscreen
    }

    Rectangle {
        id: toolbar

        property bool collapsed: false

        anchors.bottom: parent.bottom

        width: parent.width
        height: collapsed ? 0 : units.gu(7)
        Behavior on height { UbuntuNumberAnimation {} }

        color: "black"
        opacity: 0.8

        Row {
            anchors.centerIn: parent
            height: units.gu(5)
            spacing: units.gu(2)

            Icon {
                width: units.gu(5)
                height: width
                name: videoLoader.item && videoLoader.item.playbackState == MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (videoLoader.item.playbackState == MediaPlayer.PlayingState) {
                            videoLoader.item.pause()
                        } else {
                            videoLoader.item.play()
                        }
                    }
                }
            }
            Icon {
                width: units.gu(5)
                height: width
                name: "media-playback-stop"
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        videoLoader.item.stop()
                    }
                }
            }
        }
    }
}
