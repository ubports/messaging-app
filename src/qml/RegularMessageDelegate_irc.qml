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

        for (var i = 0; i < dataAttachments.length; i++) {
            var attachment = dataAttachments[i].data
            var item = {"text":"", "url":""}
            var contentType = application.fileMimeType(String(attachment.filePath))
            // we dont include smil files. they will be auto generated
            if (startsWith(contentType.toLowerCase(), "application/smil")) {
                continue
            }
            item["url"] = "file://" + attachment.filePath
            items.push(item)
        }

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
        var newAttachments = []
        for (var i = 0; i < attachments.length; i++) {
            var attachment = []
            var item = attachments[i]
            // we dont include smil files. they will be auto generated
            if (item.contentType.toLowerCase() === "application/smil") {
                continue
            }
            // text messages will be sent as textMessage. skip it
            // to avoid duplication
            if (item.contentType.toLowerCase() === "text/plain") {
                continue
            }
            attachment.push(item.attachmentId)
            attachment.push(item.contentType)
            attachment.push(item.filePath)
            newAttachments.push(attachment)
        }

        messages.validator.validateMessageAndSend(textMessage, messages.participantIds, newAttachments, {"x-canonical-tmp-files": true}, [messageDelegate.deleteMessage])
    }

    width: messageList.width
    height: label.contentHeight
    divider.visible: false
    contentItem.clip: false

    Label {
        id: label

        property string sender: {
            if (messages.chatType == HistoryThreadModel.ChatTypeRoom || messageData.participants.length > 1) {
                if (messageData.sender && incoming) {
                    if (messageData.sender.alias !== undefined && messageData.sender.alias !== "") {
                        return messageData.sender.alias
                    } else if (messageData.sender.identifier !== undefined && messageData.sender.identifier !== "") {
                        return messageData.sender.identifier
                    } else if (messageData.senderId !== "") {
                        return messageData.senderId
                    }
                }
            }
            return account.selfContactId
        }


        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(1)
        }
        text: "<font color=\"%1\">[%2]</font>\t%3"
            .arg(incoming ? "green" : "blue")
            .arg(sender)
            .arg(messageDelegate.messageText)
        font.bold: (messages.chatType === HistoryThreadModel.ChatTypeRoom) &&
                   messageDelegate.incoming &&
                   (_accountRegex && text.match(_accountRegex))
        wrapMode: Text.WordWrap
    }

    //highlightColor: "transparent"

    leadingActions: ListItemActions {
        actions: [
            Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered: deleteMessage()
            }
        ]
        delegate: Rectangle {
            width: height + units.gu(4.5)
            color: UbuntuColors.red
            Icon {
                name: action.iconName
                width: units.gu(3)
                height: width
                color: "white"
                anchors.centerIn: parent
            }
        }
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
                    var messageType = attachments.length > 0 ? i18n.tr("MMS") : i18n.tr("SMS")
                    var messageInfo = {"type": messageType,
                                       "senderId": messageData.senderId,
                                       "sender": messageData.sender,
                                       "timestamp": messageData.timestamp,
                                       "textReadTimestamp": messageData.textReadTimestamp,
                                       "status": messageData.textMessageStatus,
                                       "participants": messages.participants}
                    messageInfoDialog.showMessageInfo(messageInfo)
                }
            }
        ]
    }

    Component.onCompleted: {
        if (messageData.newEvent) {
            messages.markMessageAsRead(messageData.accountId, threadId, eventId, type);
        }
    }
}
