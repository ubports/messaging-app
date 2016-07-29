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

import '../../src/qml/'

Item {
    id: root

    width: units.gu(40)
    height: units.gu(40)

    MMSDelegate {
        id: mmsDelegate
        objectName: "mmsDelegate"

        function startsWith(str, prefix) {
            return str.toLowerCase().slice(0, prefix.length) === prefix.toLowerCase();
        }

        anchors.fill: parent

        messageData: {
            "participants": [],
            "sender": {"alias": ""},
            "textMessageAttachments": [],
        }
    }

    UbuntuTestCase {
        id: mmsImageDelegateTestCase
        name: 'mmsImageDelegateTestCase'

        when: windowShown

        function test_load_image() {
            mmsDelegate.messageData = {
                "newEvent": false,
                "participants": [],
                "sender": {"alias": ""},
                "senderId": "self",
                "textMessage": "Message Delegate QML Test",
                "textMessageAttachments": [
                    {
                        "contentType": "image/png",
                        "filePath": Qt.resolvedUrl("./data/sample.png")
                    }
                ],
                "textMessageStatus": 1,
                "textReadTimestamp": new Date(),
                "timestamp": new Date()
            }

            var image = findChild(mmsDelegate, "imageAttachment")
            verify(image != null)
            waitForRendering(image)
            verify(image.source != "image://theme/image-missing")
        }

        function test_load_invalid_path() {
            mmsDelegate.messageData = {
                "newEvent": false,
                "participants": [],
                "sender": {"alias": ""},
                "senderId": "self",
                "textMessage": "Message Delegate QML Test",
                "textMessageAttachments": [
                    {
                        "contentType": "image/png",
                        "filePath": "/wrong/path/file.png"
                    }
                ],
                "textMessageStatus": 1,
                "textReadTimestamp": new Date(),
                "timestamp": new Date()
            }

            var image = findChild(mmsDelegate, "imageAttachment")
            verify(image != null)
            waitForRendering(image)
            tryCompare(image, "source", "image://theme/image-missing")
        }
    }

    UbuntuTestCase {
        id: mmsVideoDelegateTestCase
        name: 'mmsVideoDelegateTestCase'

        when: windowShown
            
        /* FIXME: this text is disabled because thumbnailer sometimes fails on yakkety
        function test_load_video() {
            mmsDelegate.messageData = {
                "newEvent": false,
                "participants": [],
                "sender": {"alias": ""},
                "senderId": "self",
                "textMessage": "Message Delegate QML Test",
                "textMessageAttachments": [
                    {
                        "contentType": "video/mp4",
                        "filePath": Qt.resolvedUrl("./data/sample.mp4")
                    }
                ],
                "textMessageStatus": 1,
                "textReadTimestamp": new Date(),
                "timestamp": new Date()
            }

            var video = findChild(mmsDelegate, "videoAttachment")
            verify(video != null)
            waitForRendering(video)
            verify(video, "source" != "image://theme/image-missing")

            var icon = findChild(mmsDelegate, "playbackStartIcon")
            verify(icon != null)
            waitForRendering(icon)
            verify(icon.visible)
        }*/

        function test_load_invalid_path() {
            skip("image://thumbnailer is not reporting an error for wrong file path")
            mmsDelegate.messageData = {
                "newEvent": false,
                "participants": [],
                "sender": {"alias": ""},
                "senderId": "self",
                "textMessage": "Message Delegate QML Test",
                "textMessageAttachments": [
                    {
                        "contentType": "video/mp4",
                        "filePath": "/wrong/path/file.mp4"
                    }
                ],
                "textMessageStatus": 1,
                "textReadTimestamp": new Date(),
                "timestamp": new Date()
            }

            var video = findChild(mmsDelegate, "videoAttachment")
            verify(video != null)
            waitForRendering(video)
            compare(video.source, "image://theme/image-missing")
        }
    }

    UbuntuTestCase {
        id: mmsAudioDelegateTestCase
        name: 'mmsAudioDelegateTestCase'

        when: windowShown
            
        function test_load_audio() {
            mmsDelegate.messageData = {
                "newEvent": false,
                "participants": [],
                "sender": {"alias": ""},
                "senderId": "self",
                "textMessage": "Message Delegate QML Test",
                "textMessageAttachments": [
                    {
                        "contentType": "audio/ogg",
                        "filePath": Qt.resolvedUrl("./data/sample.ogg")
                    }
                ],
                "textMessageStatus": 1,
                "textReadTimestamp": new Date(),
                "timestamp": new Date()
            }

            var playButton = findChild(mmsDelegate, "playButton")
            verify(playButton != null)
            tryCompare(playButton, "visible", true)
        }
    }
}
