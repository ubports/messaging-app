/*
 * Copyright 2015 Canonical Ltd.
 *
 * Authors:
 *  Arthur Mello <arthur.mello@canonical.com>
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
import QtTest 1.0
import Ubuntu.Test 0.1

import '../../src/qml/MMS'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(40)

    PreviewerImage {
        id: previewerImage
        objectName: "previewerImage"

        property var application: {
            "fullscreen": false
        }

        anchors.fill: parent
    }

    UbuntuTestCase {
        id: previewerImageTestCase
        name: 'peviewerImageTestCase'

        when: windowShown

        function initTestCase() {
             previewerImage.attachment = {
                "contentType": "image/png",
                "filePath": Qt.resolvedUrl("./data/sample.png")
            }
        }

        function test_load_image() {
            var activityIndicator = findChild(previewerImage, "imageActivityIndicator")
            verify(activityIndicator != null)
            tryCompare(activityIndicator, "visible", false)

            var thumbnail = findChild(previewerImage, "thumbnailImage")
            verify(thumbnail != null)
            tryCompare(thumbnail, "opacity", 1.0)

            var highRes = findChild(previewerImage, "highResolutionImage")
            verify(highRes != null)
            compare(highRes.source, "")
        }

        function test_zoom_in_out() {
            var activityIndicator = findChild(previewerImage, "imageActivityIndicator")
            verify(activityIndicator != null)
            tryCompare(activityIndicator, "visible", false)

            var thumbnail = findChild(previewerImage, "thumbnailImage")
            verify(thumbnail != null)
            tryCompare(thumbnail, "opacity", 1.0)

            var highRes = findChild(previewerImage, "highResolutionImage")
            verify(highRes != null)
            compare(highRes.source, "")

            mouseDoubleClick(thumbnail)
            verify(highRes.source !== "")

            mouseDoubleClick(thumbnail)
            compare(highRes.source, "")
        }

        function test_toggle_fullscreen() {
            var activityIndicator = findChild(previewerImage, "imageActivityIndicator")
            verify(activityIndicator != null)
            tryCompare(activityIndicator, "visible", false)

            var thumbnail = findChild(previewerImage, "thumbnailImage")
            verify(thumbnail != null)

            verify(previewerImage.application.fullscreen)
            mouseClick(thumbnail)
            tryCompare(previewerImage.application, "fullscreen", false)
        }
    }
}
