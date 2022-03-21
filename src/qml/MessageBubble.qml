/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneNumber

import "dateUtils.js" as DateUtils
import "3rd_party/ba-linkify.js" as BaLinkify

Item {
    id: root

    property int messageStatus: -1
    property bool messageIncoming: false
    property alias sender: senderName.text
    property string messageText
    property var messageTimeStamp
    readonly property int maxDelegateWidth: units.gu(27)
    property string accountName
    property var account
    property var _accountRegex: account && (account.selfContactId != "" && !account.selfContactId.includes("+")) ? new RegExp('\\b' + account.selfContactId + '\\b', 'g') : null
    property bool isMultimedia: false
    // FIXME for now we just display the delivery status if it's greater than Accepted
    property bool showDeliveryStatus: false
    property bool deliveryStatusAvailable: showDeliveryStatus && (statusDelivered || statusRead)

    readonly property bool error: (messageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
    readonly property bool sending: (messageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                     messageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed) && !messageIncoming
    readonly property bool statusDelivered: (messageStatus === HistoryThreadModel.MessageStatusDelivered)
    readonly property bool statusRead: (messageStatus === HistoryThreadModel.MessageStatusRead)

    // XXXX: should be hoisted
    function getCountryCode() {
        var localeName = Qt.locale().name
        return localeName.substr(localeName.length - 2, 2)
    }

    function formatTelSchemeWith(phoneNumber) {
        return '<a href="tel:///' + phoneNumber + '">' + phoneNumber + '</a>'
    }

    function parseText(text) {
        if (!text) {
            return text;
        }

        // remove html tags
        text = text.replace(/<[^>]*>?/gm, '');
        // escape '&' char
        text = text.replace(/&/g, '&amp;');
        // preserve new lines
        text = text.replace(/\n/g, '<br>');
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

        // hightlight participants names
        if (_accountRegex)
            text = text.replace(_accountRegex, "<b>" + account.selfContactId + "</b>")

        return text
    }

    property string color: {
        if (error) {
            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "lightRed" : "red"
        } else if (sending) {
            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "lightGrey" : "grey"
        } else if (messageIncoming) {
            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "black" : "white"
        } else if (isMultimedia) {
            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "lightBlue" : "blue"
        } else {
            return theme.name === "Ubuntu.Components.Themes.SuruDark" ? "lightGreen" : "green"
        }
    }

    // FIXME: maybe we should put everything inside a container to make width and height calculation easier
    height: messageText != "" ? senderName.height + senderName.anchors.topMargin + textLabel.implicitHeight + textLabel.anchors.topMargin + units.gu(0.5) + (oneLine ? 0 : messageFooter.height + messageFooter.anchors.topMargin) : 0
    width:  Math.min(maxDelegateWidth,
                     Math.max(oneLine ? oneLineWidth : textLabel.implicitWidth,
                              messageFooter.width,
                              senderName.contentWidth))
            + units.gu(3)

    // if possible, put the timestamp and the delivery status in the same line as the text
    property int oneLineWidth: textLabel.implicitWidth + messageFooter.width
    property bool oneLine: oneLineWidth <= maxDelegateWidth

    UbuntuShape {

        anchors.fill: root
        backgroundColor: root.color

        Label {
            id: senderName
            clip: true
            elide: Text.ElideRight

            anchors {
                top: parent.top
                topMargin: height != 0 ? units.gu(0.5) : 0
                left: parent.left
                leftMargin: units.gu(1)
            }
            height: text === "" ? 0 : paintedHeight
            width: paintedWidth > root.maxDelegateWidth ? root.maxDelegateWidth : undefined
            fontSize: "small"
        }

        Label {
            id: textLabel
            objectName: "messageText"

            anchors {
                top: sender == "" ? parent.top : senderName.bottom
                topMargin: sender == "" ? units.gu(0.5) : units.gu(1)
                left: parent.left
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            fontSize: "medium"
            onLinkActivated:  Qt.openUrlExternally(link)
            text: root.parseText(messageText)
            width: root.oneLine ? implicitWidth : maxDelegateWidth

            // It needs to be Text.StyledText to use linkColor: https://api-docs.ubports.com/sdk/apps/qml/QtQuick/Text.html#sdk-qtquick-text-linkcolor
            textFormat: Text.StyledText
            wrapMode: Text.Wrap
            color: root.messageIncoming ? Theme.palette.normal.backgroundText :
                                          Theme.palette.normal.positiveText

            linkColor: root.messageIncoming ? theme.palette.normal.activity : theme.palette.normal.positiveText
        }

        Row {
            id: messageFooter
            width: childrenRect.width
            spacing: units.gu(1)

            anchors {
                top: oneLine ? textLabel.top : textLabel.bottom
                topMargin: units.gu(0.5)
                right: parent.right
                rightMargin: units.gu(1)
            }

            Label {
                id: textTimestamp
                objectName: "messageDate"

                anchors.bottom: parent.bottom
                visible: !root.sending
                height: units.gu(2)
                width: paintedWidth > maxDelegateWidth ? maxDelegateWidth : undefined
                fontSize: "x-small"
                color: root.messageIncoming ? Theme.palette.normal.backgroundSecondaryText :
                                              Theme.palette.normal.positiveText
                opacity: root.messageIncoming ? 1.0 : 0.8
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                text: {
                    if (root.messageTimeStamp === "")
                        return ""

                    var str = Qt.formatTime(root.messageTimeStamp, Qt.DefaultLocaleShortDate)
                    if (root.accountName.length === 0 || !root.messageIncoming) {
                        return str
                    }
                    str += " @ %1".arg(root.accountName)
                    return str
                }
            }

            DeliveryStatus {
                id: deliveryStatus
                messageStatus: root.messageStatus
                enabled: root.deliveryStatusAvailable
                anchors.verticalCenter: textTimestamp.verticalCenter
            }
        }
    }
}
