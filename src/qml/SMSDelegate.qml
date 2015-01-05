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
import Ubuntu.Components 1.1

import "dateUtils.js" as DateUtils

MessageDelegate {
    id: root

    function deleteMessage()
    {
        eventModel.removeEvents([root.messageData.properties]);
    }

    function resendMessage()
    {
        if (!sendMessageSanityCheck()) {
            return
        }

        eventModel.removeEvents([root.messageData.properties]);
        // FIXME: export this information for MessageDelegate
        chatManager.sendMessage(messages.participants, textMessage, messages.account.accountId)
    }

    function copyMessage()
    {
        Clipboard.push(bubble.messageText)
    }

    height: bubble.height
    _lastItem: bubble

    MessageBubble {
        id: bubble

        states: [
            State {
                name: "incoming"
                when: root.incoming
                AnchorChanges {
                    target: bubble
                    anchors.left: parent.left
                }
            },
            State {
                name: "outgoing"
                when: !root.incoming
                AnchorChanges {
                    target: bubble
                    anchors.right: parent.right
                }
            }

        ]
        visible: (messageText !== "")
        messageIncoming: root.incoming
        messageText: root.messageData.textMessage
        messageTimeStamp: root.messageData.timestamp
        accountName: root.accountLabel
        messageStatus: root.messageData.textMessageStatus
    }
}
