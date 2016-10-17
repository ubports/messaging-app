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
import QtMultimedia 5.0
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import Ubuntu.Thumbnailer 0.1
import messagingapp.private 0.1
import ".."

Previewer {
    id: videoPreviewer

    property size thumbnailSize: Qt.size(viewer.width * 1.05, viewer.height * 1.05)

    title: i18n.tr("Video Preview")
    clip: true

    // FIXME: this won't work correctly in windowed mode
    Component.onCompleted: {
        application.fullscreen = true
        // Load Video player after toggling fullscreen to reduce flickering
        videoLoader.active = true
    }
    Component.onDestruction: application.fullscreen = false

    onWidthChanged: {
        // Only change thumbnailSize if width increases more than 5%
        // that way we do not reload image for small resizes
        if (width > thumbnailSize.width) {
            thumbnailSize = Qt.size(width * 1.05, height * 1.05);
        }
    }

    onHeightChanged: {
        // Only change thumbnailSize if height increases more than 5%
        // that way we do not reload image for small resizes
        if (height > thumbnailSize.height) {
            thumbnailSize = Qt.size(width * 1.05, height * 1.05);
        }
    }

    Connections {
        target: application
        onFullscreenChanged: {
            videoPreviewer.header.visible = !application.fullscreen
            toolbar.collapsed = application.fullscreen
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
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
                    console.log("PreviewerVideo: Failed to link", attachment.filePath, "to", tmpFile)
                }
            }
        }

        Component {
            id: videoComponent

            Item {
                id: videoPlayer
                objectName: "videoPlayer"

                property alias source: player.source
                property alias playbackState: player.playbackState

                function play() { player.play() }
                function pause() { player.pause() }
                function stop() { player.stop() }
 
                anchors.fill: parent

                MediaPlayer {
                    id: player
                    autoPlay: true
                }

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    source: player
                }

                Rectangle {
                    id: thumbnail

                    anchors.fill: parent
                    visible: player.status == MediaPlayer.EndOfMedia

                    color: "black"

                    ActivityIndicator {
                        anchors.centerIn: parent
                        visible: running
                        running: image.status != Image.Ready
                    }

                    Image {
                        id: image

                        anchors.fill: parent
                        visible: status == Image.Ready
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { UbuntuNumberAnimation {} }

                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: "image://thumbnailer/" + player.source.toString().replace("file://", "")

                        asynchronous: true
                        cache: true

                        sourceSize {
                            width: videoPreviewer.thumbnailSize.width
                            height: videoPreviewer.thumbnailSize.height
                        }
                    }
                }
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
        onClicked: application.fullscreen = !application.fullscreen
    }

    Rectangle {
        id: toolbar
        objectName: "toolbar"

        property bool collapsed: false

        anchors.bottom: parent.bottom

        width: parent.width
        height: collapsed ? 0 : units.gu(7)
        Behavior on height { UbuntuNumberAnimation {} }

        color: "gray"
        opacity: 0.8

        Row {
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            spacing: units.gu(2)

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: toolbar.collapsed ? 0 : units.gu(5)
                height: width
                Behavior on width { UbuntuNumberAnimation {} }
                Behavior on height { UbuntuNumberAnimation {} }
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
                anchors.verticalCenter: parent.verticalCenter
                width: toolbar.collapsed ? 0 : units.gu(5)
                height: width
                Behavior on width { UbuntuNumberAnimation {} }
                Behavior on height { UbuntuNumberAnimation {} }
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
