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
import "3rd_party/ba-linkify.js" as BaLinkify


BorderImage {
    id: root

    property bool incoming
    property bool error: false
    property alias sender: senderName.text
    property string messageText
    readonly property double textWidth: Math.min(units.gu(27), textLabel.text.length * units.gu(1)) + border.left + border.right

    function selectBubble() {
        var fileName = "assets/conversation_";
        if (error) {
            fileName += "error.sci"
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
    height: senderName.height + textLabel.height + border.top + border.bottom
    width: textWidth

    Label {
        id: senderName

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: border.left
        }
        height: text === "" ? 0 : paintedHeight
        fontSize: "large"
        //color: Ubuntu.Colors.
    }

    Label {
        id: textLabel

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: border.left
            right: parent.right
            rightMargin: border.right
        }
        fontSize: "medium"
        height: text === "" ? 0 : paintedHeight
        onLinkActivated:  Qt.openUrlExternally(link)
        text: root.parseText(messageText)
        wrapMode: Text.Wrap
        color: root.incoming ? UbuntuColors.darkGrey : "white"
    }

//    Label {
//        id: textTimestamp

//        anchors{
//            bottom: parent.bottom
//            left: parent.left
//            leftMargin: border.left
//        }

//        height: paintedHeight + units.gu(0.5)
//        fontSize: "x-small"
//        color: "#333333"
//        text: {
//            if (indicator.visible)
//                i18n.tr("Sending...")
//            else if (warningButton.visible)
//                i18n.tr("Failed")
//            else
//                DateUtils.friendlyDay(timestamp) + " " + Qt.formatDateTime(timestamp, "hh:mm AP")
//        }
//    }
}
