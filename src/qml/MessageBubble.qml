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
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneNumber

import "dateUtils.js" as DateUtils
import "3rd_party/ba-linkify.js" as BaLinkify

Rectangle {
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

    // XXXX: should be hoisted
    function getCountryCode() {
        var localeName = Qt.locale().name
        return localeName.substr(localeName.length - 2, 2)
    }

    function formatTelSchemeWith(phoneNumber) {
        return '<a href="tel:///' + phoneNumber + '">' + phoneNumber + '</a>'
    }

    function parseText(text) {
        // remove html tags
        text = text.replace(/</g,'&lt;').replace(/>/g,'<tt>&gt;</tt>');
        // replace line breaks
        text = text.replace(/(\n)+/g, '<br />');
        // check for links
        var htmlText = BaLinkify.linkify(text);
        if (htmlText !== text) {
            return htmlText
        }

        // linkify phone numbers if no web links were found
        var phoneNumbers = PhoneNumber.PhoneUtils.matchInText(text, getCountryCode())
        for (var i = 0; i < phoneNumbers.length; ++i) {
            var currentNumber = phoneNumbers[i]
            text = text.replace(currentNumber, formatTelSchemeWith(currentNumber))
        }
        return text
    }

    color: {
        if (error) {
            return "#fc4949"
        } else if (sending) {
            return "#b2b2b2"
        } else if (messageIncoming) {
            return "#ffffff"
        } else {
            return "#3fb24f"
        }
    }
    radius: 9
    height: senderName.height + textLabel.height + textTimestamp.height + units.gu(1)
    width:  Math.min(units.gu(27),
                     Math.max(textLabel.contentWidth, textTimestamp.contentWidth))
            + units.gu(3)
    anchors{
        leftMargin:  units.gu(1)
        rightMargin: units.gu(1)
    }

    Label {
        id: senderName

        anchors {
            top: parent.top
            topMargin: units.gu(0.5)
            left: parent.left
            leftMargin: root.messageIncoming ? units.gu(2) : units.gu(1)
        }
        height: text === "" ? 0 : paintedHeight
        fontSize: "large"
    }

    Label {
        id: textLabel
        objectName: "messageText"

        anchors {
            top: sender == "" ? parent.top : senderName.bottom
            topMargin: sender == "" ? units.gu(0.5) : units.gu(1)
            left: parent.left
            leftMargin: units.gu(1)
        }
        width: paintedWidth > maxDelegateWidth ? maxDelegateWidth : undefined
        fontSize: "medium"
        height: contentHeight
        onLinkActivated:  Qt.openUrlExternally(link)
        text: root.parseText(messageText)
        textFormat: Text.RichText
        wrapMode: Text.Wrap
        color: root.messageIncoming ? UbuntuColors.darkGrey : "white"
    }

    Label {
        id: textTimestamp
        objectName: "messageDate"

        anchors{
            top: textLabel.bottom
            topMargin: units.gu(0.5)
            left: parent.left
            leftMargin: units.gu(1)
        }

        visible: !root.sending
        height: units.gu(2)
        width: visible ? maxDelegateWidth : 0
        fontSize: "xx-small"
        color: root.messageIncoming ? UbuntuColors.lightGrey : "white"
        opacity: root.messageIncoming ? 1.0 : 0.8
        elide: Text.ElideRight
        text: {
            if (messageTimeStamp === "")
                return ""

            var str = Qt.formatTime(messageTimeStamp, Qt.DefaultLocaleShortDate)
            if (root.accountName.length === 0 || !root.messageIncoming) {
                return str
            }
            str += " @ %1".arg(root.accountName)
            return str
        }
    }

    ColoredImage {
        id: bubbleArrow

        source: Qt.resolvedUrl("./assets/conversation_bubble_arrow.png")
        color: root.color
        asynchronous: false
        anchors {
            bottom: parent.bottom
            bottomMargin: units.gu(2)
        }
        width: units.gu(1)
        height: units.gu(1.5)

        states: [
            State {
                when: root.messageIncoming
                name: "incoming"
                AnchorChanges {
                    target: bubbleArrow
                    anchors.right: root.left
                }
            },
            State {
                when: !root.messageIncoming
                name: "outgoing"
                AnchorChanges {
                    target: bubbleArrow
                    anchors.left: root.right
                }
                PropertyChanges {
                    target: bubbleArrow
                    mirror: true
                }
            }
        ]
    }
}
