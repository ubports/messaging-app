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

import "dateUtils.js" as DateUtils

MessageDelegate {
    id: root

    function deleteMessage()
    {
        eventModel.removeEvent(accountId, threadId, eventId, type)
    }

    function resendMessage()
    {
        eventModel.removeEvent(accountId, threadId, eventId, type)
        chatManager.sendMessage(messages.participants, textMessage, messages.accountId)
    }

    function copyMessage()
    {
        Clipboard.push(bubble.messageText)
    }

    height: bubble.height
    _lastItem: bubble

    MessageBubble {
        id: bubble

        anchors {
            top: parent.top
            left: incoming ? parent.left : undefined
            right: incoming ? undefined : parent.right
        }
        visible: (root.text !== "")
        incoming: root.incoming
        messageText: root.text
        messageTimeStamp: root.timestamp
        messageStatus: root.messageStatus
    }
}
