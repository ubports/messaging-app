/*
 * Copyright 2014 Canonical Ltd.
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

    MessageBubble {
        id: incomingMessageBubble
        objectName: 'incomingMessageBubble'

        height: parent.height / 3

        incoming: true
    }

    MessageBubble {
        id: outgoingMessageBubble
        objectName: 'outgoingMessageBubble'

        anchors.top: incomingMessageBubble.bottom
        height: parent.height / 3

        incoming: false
    }

    MessageBubble {
        id: changeIncomingMessageBubble
        objectName: 'changeIncomingMessageBubble'

        anchors.top: outgoingMessageBubble.bottom
        height: parent.height / 3

        incoming: true
    }

    UbuntuTestCase {
        id: messageBubbleTestCase
        name: 'messageBubbleTestCase'

        when: windowShown

        function init() {
            waitForRendering(incomingMessageBubble);
            waitForRendering(outgoingMessageBubble);
            waitForRendering(changeIncomingMessageBubble);
        }

        function cleanup() {
            changeIncomingMessageBubble.incoming = true;
        }

        function test_incoming_message_bubble_must_use_incoming_source() {
            var incomingMessageBubble = findChild(
                root, 'incomingMessageBubble');
            compare(
                incomingMessageBubble.source,
                'assets/conversation_incoming.sci');
        }

        function test_outgoing_message_bubble_must_use_outgoing_source() {
            var outgoingMessageBubble = findChild(
                root, 'outgoingMessageBubble');
            compare(
                outgoingMessageBubble.source,
                'assets/conversation_outgoing.sci');
        }

        function test_change_incoming_must_update_source() {
            var changeIncomingMessageBubble = findChild(
                root, 'changeIncomingMessageBubble');
            changeIncomingMessageBubble.incoming = false;
            compare(
                changeIncomingMessageBubble.source,
                'assets/conversation_outgoing.sci');
        }
    }
}
