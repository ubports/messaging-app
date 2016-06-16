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

ListItemWithActions {
    id: messageDelegate
    objectName: "messageDelegate"

    // To be used by actions
    property int _index: index

    property var messageData: null
    property string messageText: {
        if (attachmentsLoader.item && attachmentsLoader.item.messageText !== "") {
            return attachmentsLoader.item.messageText
        } else if (messageData) {
            return messageData.textMessage
        }
        return ""
    }
    property var attachments: messageData.textMessageAttachments
    property var dataAttachments: []
    property var textAttachments: []
    property bool incoming: (messageData && messageData.senderId !== "self")
    property string accountLabel: ""
    property var _lastItem: textBubble.visible ? textBubble : attachmentsLoader.item.lastItem
    property bool swipeLocked: attachmentsLoader.item && attachmentsLoader.item.swipeLocked

    function deleteMessage()
    {
        eventModel.removeEvents([messageData.properties]);
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
        messages.sendMessage(textMessage, messages.participantIds, newAttachments, {"x-canonical-tmp-files": true})
        deleteMessage();
    }

    function clicked(mouse)
    {
        // we only have actions for attachment items, so forward the click
        if (attachmentsLoader.item) {
            attachmentsLoader.item.clicked(mouse)
        }
    }

    color: "transparent"
    locked: swipeLocked

    width: messageList.width
    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: deleteMessage()
    }

    rightSideActions: [
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

    height: attachmentsLoader.height + textBubble.height + units.gu(1)
    internalAnchors {
        topMargin: units.gu(0.5)
        bottomMargin: units.gu(0.5)
    }

    onItemClicked: {
        if (!selectionMode) {
            messageDelegate.clicked(mouse)
        }
    }

    Loader {
        id: attachmentsLoader

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        source: Qt.resolvedUrl("AttachmentsDelegate.qml")
        active: attachments.length > 0
        height: status == Loader.Ready ? item.height : 0
        Binding {
            target: attachmentsLoader.item
            property: "attachments"
            value: attachments
            when: (attachmentsLoader.status === Loader.Ready)
        }
        Binding {
            target: attachmentsLoader.item
            property: "accountLabel"
            value: accountLabel
            when: (attachmentsLoader.status === Loader.Ready)
        }
        Binding {
            target: attachmentsLoader.item
            property: "incoming"
            value: incoming
            when: (attachmentsLoader.status === Loader.Ready)
        }
    }

    MessageBubble {
        id: textBubble
        anchors {
            top: attachmentsLoader.bottom
            topMargin: attachmentsLoader.active ? units.gu(1) : 0
        }

        states: [
            State {
                name: "incoming"
                when: messageDelegate.incoming && visible
                AnchorChanges {
                    target: textBubble
                    anchors.left: parent.left
                }
            },
            State {
                name: "outgoing"
                when: !messageDelegate.incoming && visible
                AnchorChanges {
                    target: textBubble
                    anchors.right: parent.right
                }
            },
            State {
                name: "invisible"
                when: !visible
                PropertyChanges {
                    target: textBubble
                    height: 0
                }
            }
        ]
        visible: (messageText !== "")
        messageIncoming: messageDelegate.incoming
        messageText: messageDelegate.messageText
        messageTimeStamp: messageData.timestamp
        accountName: messageDelegate.accountLabel
        messageStatus: messageData.textMessageStatus
        sender: (messages.threads[0].chatType == HistoryThreadModel.ChatTypeRoom || messageData.participants.length > 1) ? messageData.sender.alias !== "" ? messageData.sender.alias : messageData.senderId : ""
        showDeliveryStatus: true
    }

    Item {
        id: statusIcon

        height: units.gu(4)
        width: units.gu(4)
        parent: messageDelegate._lastItem
        onParentChanged: {
            // The spinner gets stuck once parent changes, this is a workaround
            indicator.running = false
            // if temporarily failed or unknown status, then show the spinner
            indicator.running = Qt.binding(function(){ return !incoming && 
                    (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                     textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed)});
        }
        anchors {
            verticalCenter: parent ? parent.verticalCenter : undefined
            right: parent ? parent.left : undefined
            rightMargin: units.gu(2)
        }

        visible: !incoming && !selectionMode
        ActivityIndicator {
            id: indicator

            anchors.centerIn: parent
            height: units.gu(2)
            width: units.gu(2)
            visible: running && !selectionMode
        }

        Item {
            id: retrybutton

            anchors.fill: parent
            Icon {
                id: icon

                name: "reload"
                color: "red"
                height: units.gu(2)
                width: units.gu(2)
                anchors {
                    centerIn: parent
                    verticalCenterOffset: units.gu(-1)
                }
            }

            Label {
                text: i18n.tr("Failed!")
                fontSize: "small"
                color: "red"
                anchors {
                    horizontalCenter: retrybutton.horizontalCenter
                    top: icon.bottom
                }
            }
            visible: (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
            MouseArea {
                id: retrybuttonMouseArea

                anchors.fill: parent
                onClicked: messageDelegate.resendMessage()
            }
        }
    }
}
