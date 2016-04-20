/*
 * Copyright 2012-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import Ubuntu.Thumbnailer 0.1
import ".."

Previewer {
    id: imagePreviewer

    // FIXME: this won't work correctly in windowed mode
    Component.onCompleted: application.fullscreen = true
    Component.onDestruction: application.fullscreen = false

    Connections {
        target: application
        onFullscreenChanged: imagePreviewer.header.visible = !application.fullscreen
    }

    title: i18n.tr("Image Preview")
    clip: true

    Rectangle {
        anchors.fill: parent
        color: "black"
    } 

    Item {
        id: imageItem
        property bool pinchInProgress: zoomPinchArea.active
        property size thumbSize: Qt.size(viewer.width * 1.05, viewer.height * 1.05)

        onWidthChanged: {
            // Only change thumbSize if width increases more than 5%
            // that way we do not reload image for small resizes
            if (width > thumbSize.width) {
                thumbSize = Qt.size(width * 1.05, height * 1.05);
            }
        }

        onHeightChanged: {
            // Only change thumbSize if height increases more than 5%
            // that way we do not reload image for small resizes
            if (height > thumbSize.height) {
                thumbSize = Qt.size(width * 1.05, height * 1.05);
            }
        }

        function zoomIn(centerX, centerY, factor) {
            flickable.scaleCenterX = centerX / (flickable.sizeScale * flickable.width);
            flickable.scaleCenterY = centerY / (flickable.sizeScale * flickable.height);
            flickable.sizeScale = factor;
        }

        function zoomOut() {
            if (flickable.sizeScale != 1.0) {
                flickable.scaleCenterX = flickable.contentX / flickable.width / (flickable.sizeScale - 1);
                flickable.scaleCenterY = flickable.contentY / flickable.height / (flickable.sizeScale - 1);
                flickable.sizeScale = 1.0;
            }
        }

        width: parent.width
        height: parent.height

        ActivityIndicator {
            objectName: "imageActivityIndicator"
            anchors.centerIn: parent
            visible: running
            running: image.status != Image.Ready
        }

        PinchArea {
            id: zoomPinchArea
            anchors.fill: parent

            property real initialZoom
            property real maximumScale: 3.0
            property real minimumZoom: 1.0
            property real maximumZoom: 3.0
            property bool active: false
            property var center

            onPinchStarted: {
                active = true;
                initialZoom = flickable.sizeScale;
                center = zoomPinchArea.mapToItem(media, pinch.startCenter.x, pinch.startCenter.y);
                imageItem.zoomIn(center.x, center.y, initialZoom);
            }
            onPinchUpdated: {
                var zoomFactor = MathUtils.clamp(initialZoom * pinch.scale, minimumZoom, maximumZoom);
                flickable.sizeScale = zoomFactor;
            }
            onPinchFinished: {
                active = false;
            }

            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: media.width
                contentHeight: media.height
                contentX: (sizeScale - 1) * scaleCenterX * width
                contentY: (sizeScale - 1) * scaleCenterY * height
                interactive: !imageItem.pinchInProgress

                property real sizeScale: 1.0
                property real scaleCenterX: 0.0
                property real scaleCenterY: 0.0

                Behavior on sizeScale {
                    enabled: !imageItem.pinchInProgress
                    UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration}
                }
                Behavior on scaleCenterX {
                    UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration}
                }
                Behavior on scaleCenterY {
                    UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration}
                }

                Item {
                    id: media

                    width: flickable.width * flickable.sizeScale
                    height: flickable.height * flickable.sizeScale

                    Image {
                        id: image
                        objectName: "thumbnailImage"
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        source: "image://thumbnailer/%1".arg(attachment.filePath.toString())
                        sourceSize {
                            width: imageItem.thumbSize.width
                            height: imageItem.thumbSize.height
                        }
                        fillMode: Image.PreserveAspectFit
                        opacity: status == Image.Ready ? 1.0 : 0.0
                        Behavior on opacity { UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration} }
                    }

                    Image {
                        id: highResolutionImage
                        objectName: "highResolutionImage"
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        source: flickable.sizeScale > 1.0 ? attachment.filePath : ""
                        sourceSize {
                            width: width
                            height: height
                        }
                        fillMode: Image.PreserveAspectFit
                    }
                }

                MouseArea {
                    id: imageMouseArea
                    anchors.fill: parent

                    property bool clickAccepted: false

                    onDoubleClicked: {
                        if (imageMouseArea.clickAccepted) {
                            return
                        }

                        clickTimer.stop()

                        if (flickable.sizeScale < zoomPinchArea.maximumZoom) {
                            imageItem.zoomIn(mouse.x, mouse.y, zoomPinchArea.maximumZoom);
                        } else {
                            imageItem.zoomOut();
                        }
                    }
                    onClicked: {
                        imageMouseArea.clickAccepted = false
                        clickTimer.start()
                    }
                }

                Timer {
                    id: clickTimer
                    interval: 200
                    onTriggered: {
                        imageMouseArea.clickAccepted = true
                        application.fullscreen = !application.fullscreen
                    }
                }
            }
        }
    }
}
