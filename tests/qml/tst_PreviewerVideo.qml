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
import Ubuntu.Content 0.1
import Ubuntu.Test 0.1

import '../../src/qml/MMS'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(40)

    PreviewerVideo {
        id: previewerVideo
        objectName: "previewerVideo"

        QtObject {
            id: application
            property bool fullscreen: false
        }

        function getContentType(filePath) {
            return ContentType.Videos
        }

        anchors.fill: parent

        attachment: {
            "contentType": "video/mp4",
            "filePath": Qt.resolvedUrl("./data/sample.mp4")
        }
    }

    UbuntuTestCase {
        id: previewerVideoTestCase
        name: 'peviewerVideoTestCase'

        when: windowShown

        function test_load_video() {
            var videoPlayer = findChild(previewerVideo, "videoPlayer")
            verify(videoPlayer != null)
            tryCompare(videoPlayer, "visible", true)

            var toolbar = findChild(previewerVideo, "toolbar")
            verify(toolbar != null)
            tryCompare(toolbar, "collapsed", true)
        }

        function test_toggle_toolbar() {
            var videoPlayer = findChild(previewerVideo, "videoPlayer")
            verify(videoPlayer != null)
            tryCompare(videoPlayer, "visible", true)

            var toolbar = findChild(previewerVideo, "toolbar")
            verify(toolbar != null)
            tryCompare(toolbar, "collapsed", true)
 
            mouseClick(videoPlayer)
            tryCompare(toolbar, "collapsed", false)

            mouseClick(videoPlayer)
            tryCompare(toolbar, "collapsed", true)
        }
    }
}
