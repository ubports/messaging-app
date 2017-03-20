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

import QtQuick 2.2
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneNumber

import "3rd_party/ba-linkify.js" as BaLinkify

ListItem {
    id: messageDelegate
    objectName: "messageDelegate"

    // To be used by actions
    property int _index: index

    property var messageData: null
    property string messageText: messageData ? messageData.textMessage : ""
    property bool incoming: (messageData && messageData.senderId !== "self")
    property string accountLabel: ""
    property var account: null
    property var _accountRegex: account && (account.selfContactId != "") ? new RegExp('\\b' + account.selfContactId + '\\b', 'g') : null

    function getCountryCode() {
        var localeName = Qt.locale().name
        return localeName.substr(localeName.length - 2, 2)
    }

    function deleteMessage()
    {
        eventModel.removeEvents([messageData.properties]);
    }

    function forwardMessage()
    {
        var properties = {}
        var items = [{"text": textMessage, "url":""}]
        emptyStack()
        var transfer = {}
        transfer["items"] = items
        properties["sharedAttachmentsTransfer"] = transfer

        mainView.showMessagesView(properties)
    }

    function copyMessage()
    {
        Clipboard.push(messageText)
        application.showNotificationMessage(i18n.tr("Text message copied to clipboard"), "edit-copy")
    }

    function resendMessage()
    {
       messages.validator.validateMessageAndSend(textMessage, messages.participantIds, [], {"x-canonical-tmp-files": true}, [messageDelegate.deleteMessage])
    }

    width: messageList.width
    height: label.contentHeight
    divider.visible: false
    contentItem.clip: false

    Label {
        id: label

        function parseText(text) {
            if (!text) {
                return text;
            }

            // remove html tags
            text = text.replace(/</g,'&lt;').replace(/>/g,'<tt>&gt;</tt>');
            // wrap text in a div to keep whitespaces and new lines from collapsing
            text = '<div style="white-space: pre-wrap;">' + text + '</div>';
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

            if ((messages.chatType !== HistoryThreadModel.ChatTypeRoom) ||
                !messageDelegate.incoming ||
                !_accountRegex) {
            }

            return text.replace(_accountRegex, "<b>" + account.selfContactId + "</b>")
        }

        property string sender: {
            if (messageData.sender && incoming) {
                if (messageData.sender.alias !== undefined && messageData.sender.alias !== "") {
                    return messageData.sender.alias
                } else if (messageData.sender.identifier !== undefined && messageData.sender.identifier !== "") {
                    return messageData.sender.identifier
                } else if (messageData.senderId !== "") {
                    return messageData.senderId
                }
            } else if (account.selfContactId == "") {
                // Return first part of display name if account id is empty
                var displayName = account.displayName.substring(0, account.displayName.indexOf('@'))
                return displayName
            } else {
                return account.selfContactId
            }
        }


        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(1)
        }
        text: "%1 <font color=\"%2\">[%3]</font>\t%4"
            .arg(Qt.formatTime(messageData.timestamp, Qt.DefaultLocaleShortDate))
            .arg(incoming ? "green" : "blue")
            .arg(sender)
            .arg(parseText(messageDelegate.messageText))

        wrapMode: Text.WordWrap

        onLinkActivated: Qt.openUrlExternally(link)
    }

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered: deleteMessage()
            }
        ]
    }

    trailingActions: ListItemActions {
        actions: [
            Action {
                id: retryAction

                iconName: "reload"
                text: i18n.tr("Retry")
                visible: messageData.textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed
                onTriggered: messageDelegate.resendMessage()
            },
            Action {
                id: copyAction

                iconName: "edit-copy"
                text: i18n.tr("Copy")
                visible: messageText !== ""
                onTriggered: messageDelegate.copyMessage()
            },
            Action {
                id: forwardAction

                iconName: "mail-forward"
                text: i18n.tr("Forward")
                onTriggered: messageDelegate.forwardMessage()
            },
            Action {
                id: infoAction

                iconName: "info"
                text: i18n.tr("Info")
                onTriggered: {
                   var messageInfo = {"type": i18n.tr("IRC"),
                                       "senderId": messageData.senderId,
                                       "sender": messageData.sender,
                                       "timestamp": messageData.timestamp,
                                       "textReadTimestamp": messageData.textReadTimestamp,
                                       "status": messageData.textMessageStatus,
                                       "participants": messages.participants }
                    messageInfoDialog.showMessageInfo(messageInfo)
                }
            }
        ]
    }
}
