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
    property bool incoming: false
    property alias sender: senderName.text
    property string messageText
    property var messageTimeStamp

    readonly property bool error: (messageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (messageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     messageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming

    function selectBubble() {
        var fileName = "assets/conversation_";
        if (error) {
            fileName += "error.sci"
        } else if (sending) {
            fileName += "pending.sci"
        } else if (incoming) {
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

    onIncomingChanged: source = selectBubble()
    source: selectBubble()
    height: childrenRect.height + units.gu(2)
    width: childrenRect.width + units.gu(3)

    Label {
        id: senderName

        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: incoming ? units.gu(2) : units.gu(1)

        }
        visible: text !== ""
        height: text === "" ? 0 : paintedHeight
        fontSize: "large"
        //color: Ubuntu.Colors.
    }

    Label {
        id: textLabel

        anchors {
            top: senderName.bottom
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: incoming ? units.gu(2) : units.gu(1)
            //rightMargin: incoming ? units.gu(1) : units.gu(1)
        }
        fontSize: "medium"
        height: text === "" ? 0 : paintedHeight
        onLinkActivated:  Qt.openUrlExternally(link)
        text: root.parseText(messageText)
        wrapMode: Text.Wrap
        color: root.incoming ? UbuntuColors.darkGrey : "white"
    }

    Label {
        id: textTimestamp

        anchors{
            top: textLabel.bottom
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: incoming ? units.gu(2) : units.gu(1)
        }

        visible: !root.sending
        height: visible ? paintedHeight : 0
        fontSize: "x-small"
        color: root.incoming ? UbuntuColors.lightGrey : "white"
        opacity: root.incoming ? 1.0 : 0.8
        text: Qt.formatDateTime(messageTimeStamp, "hh:mm AP")
    }
}
