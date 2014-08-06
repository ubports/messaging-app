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
import Ubuntu.History 0.1

import "dateUtils.js" as DateUtils
import "3rd_party/ba-linkify.js" as BaLinkify

BorderImage {
    id: root

    property int messageStatus: -1
    property bool messageIncoming: false
    property alias sender: senderName.text
    property string messageText
    property var messageTimeStamp
    property int maxDelegateWidth: units.gu(27)
    property string accountName

    readonly property bool error: (messageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (messageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     messageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !messageIncoming

    function selectBubble() {
        var fileName = "assets/conversation_";
        if (error) {
            fileName += "error.sci"
        } else if (sending) {
            fileName += "pending.sci"
        } else if (messageIncoming) {
            fileName += "incoming.sci";
        } else {
            fileName += "outgoing.sci";
        }
        return fileName;
    }

    function parseText(text) {
        var phoneExp = /(\+?([0-9]+[ ]?)?\(?([0-9]+)\)?[-. ]?([0-9]+)[-. ]?([0-9]+)[-. ]?([0-9]+))/img;
        // remove html tags
        text = text.replace(/</g,'&lt;').replace(/>/g,'<tt>&gt;</tt>');
        // replace line breaks
        text = text.replace(/(\n)+/g, '<br />');
        // check for links
        text = BaLinkify.linkify(text);
        // linkify phone numbers
        return text.replace(phoneExp, '<a href="tel:///$1">$1</a>');
    }

    onMessageIncomingChanged: source = selectBubble()
    source: selectBubble()
    height: senderName.height + textLabel.height + textTimestamp.height + units.gu(3)
    width:  Math.min(units.gu(27),
                     Math.max(textLabel.contentWidth, textTimestamp.width))
            + border.left + border.right
    Label {
        id: senderName

        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: root.messageIncoming ? units.gu(2) : units.gu(1)
        }
        height: text === "" ? 0 : paintedHeight
        fontSize: "large"
        //color: Ubuntu.Colors.
    }

    Label {
        id: textLabel
        objectName: "messageText"

        anchors {
            top: sender == "" ? parent.top : senderName.bottom
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: root.messageIncoming ? units.gu(2) : units.gu(1)
        }
        width: maxDelegateWidth
        fontSize: "medium"
        height: text === "" ? 0 : paintedHeight
        onLinkActivated:  Qt.openUrlExternally(link)
        text: root.parseText(messageText)
        wrapMode: Text.Wrap
        color: root.messageIncoming ? UbuntuColors.darkGrey : "white"
    }

    Label {
        id: textTimestamp
        objectName: "messageDate"

        anchors{
            top: textLabel.bottom
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: root.messageIncoming ? units.gu(2) : units.gu(1)
        }

        visible: !root.sending
        height: visible ? paintedHeight : 0
        width: visible ? paintedWidth : 0
        fontSize: "xx-small"
        color: root.messageIncoming ? UbuntuColors.lightGrey : "white"
        opacity: root.messageIncoming ? 1.0 : 0.8
        text: {
            var str = Qt.formatDateTime(messageTimeStamp, "hh:mm AP")
            if (root.accountName.length === 0) {
                return str
            }

            if (root.messageIncoming) {
                str += " to %1".arg(root.accountName)
            } else {
                str += " @ %1".arg(root.accountName)
            }
            return str
        }
    }
}
