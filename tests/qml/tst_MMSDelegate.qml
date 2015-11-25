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
        property var messageData: {
            "textMessage": "Message Delegate QML Test",
            "timestamp": new Date(),
            "textMessageStatus": 1,
            "senderId": "self",
            "textReadTimestamp": new Date(),
            "textMessageAttachments": [{},{}],
            "newEvent": false,
            "participants": []
        }
        property var attachments: [{"contentType": "image/jpeg", "path": "/home/user/foo.jpg"}, {}]
            
        anchors.fill: parent
    }

    UbuntuTestCase {
        id: mmsDelegateTestCase
        name: 'mmsDelegateTestCase'

        when: windowShown

        function init() {
        }

        function cleanup() {
        }

        function test_foo() {
            wait(5000)
        }
    }
}
