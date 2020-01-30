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
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

ListItem {
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
    property string avatar: messageData.sender && messageData.sender.avatar ? messageData.sender.avatar : "image://theme/contact"
    property bool avatarVisible: incoming && messages.groupChat
    property var attachments: messageData.textMessageAttachments
    property var dataAttachments: []
    property var textAttachments: []
    property bool incoming: (messageData && messageData.senderId !== "self")
    property string accountLabel: ""
    property bool isMultimedia: false
    property var _lastItem: {
        if (textBubble.visible) {
            return textBubble
        }
        else if ( attachmentsLoader && attachmentsLoader.item ) {
            return attachmentsLoader.item.lastItem
        }
        else return null
    }
    property alias account: textBubble.account

    swipeEnabled: !(attachmentsLoader.item && attachmentsLoader.item.swipeLocked)

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

    color: "transparent"

    width: messageList.width
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
            color: theme.palette.normal.negative
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
                                       "participants": messages.participants,
                                       "accountLabel": accountLabel.length > 0 ? accountLabel: i18n.tr("Myself")}
                    messageInfoDialog.showMessageInfo(messageInfo)
                }
            }
        ]
    }

    height: Math.max(attachmentsLoader.height + textBubble.height, contactAvatarLoader.height) + units.gu(1)
    divider.visible: false
    contentItem.clip: false
    contentItem.anchors {
        leftMargin: units.gu(2)
        rightMargin: units.gu(2)
        topMargin: units.gu(0.5)
        bottomMargin: units.gu(0.5)
    }
    highlightColor: "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!selectMode) {
                // we only have actions for attachment items, so forward the click
                if (attachmentsLoader.item) {
                    attachmentsLoader.item.clicked(mouse)
                }
            }
        }
    }

    Loader {
        id: contactAvatarLoader
        active: avatarVisible
        visible: avatarVisible
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        height: visible ? units.gu(4) : 0
        width: visible? units.gu(4) : 0
        Component.onCompleted: {
            var properties = {"fallbackAvatarUrl": Qt.binding(function(){ return messageDelegate.avatar }),
                              "fallbackDisplayName": Qt.binding(function(){ return textBubble.sender }),
                              "showAvatarPicture": Qt.binding(function(){ return messageDelegate.avatar !== "" || initials.length === 0 })};
            contactAvatarLoader.setSource(Qt.resolvedUrl("LocalContactAvatar.qml"), properties);
        }
    }

    Loader {
        id: attachmentsLoader

        anchors {
            bottom: textBubble.top
            bottomMargin: attachmentsLoader.active && textBubble.visible ? units.gu(1) : 0
            left: contactAvatarLoader.right
            leftMargin: avatarVisible ? units.gu(1) : 0
            right: parent.right
        }
        Component.onCompleted: {
            var properties = {"attachments": Qt.binding(function(){ return messageDelegate.attachments }),
                              "accountLabel": Qt.binding(function(){ return messageDelegate.accountLabel }),
                              "incoming": Qt.binding(function(){ return messageDelegate.incoming })};
            attachmentsLoader.setSource(Qt.resolvedUrl("AttachmentsDelegate.qml"), properties);
        }

        active: attachments.length > 0
        height: status == Loader.Ready ? item.height : 0

        Binding {
            target: messageDelegate
            property: "dataAttachments"
            value: attachmentsLoader.item ? attachmentsLoader.item.dataAttachments : null
            when: (attachmentsLoader.status === Loader.Ready && attachmentsLoader.item)
        }
    }

    MessageBubble {
        id: textBubble

        isMultimedia: messageDelegate.isMultimedia
        anchors {
            bottom: parent.bottom
            leftMargin: avatarVisible ? units.gu(1) : 0
        }

        states: [
            State {
                name: "incoming"
                when: messageDelegate.incoming && visible
                AnchorChanges {
                    target: textBubble
                    anchors.left: contactAvatarLoader.right
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
        sender: {
            if (messages.chatType == HistoryThreadModel.ChatTypeRoom || messageData.participants.length > 1) {
                if (messageData.sender && messageIncoming) {
                    if (messageData.sender.alias !== undefined && messageData.sender.alias !== "") {
                        return messageData.sender.alias
                    } else if (messageData.sender.identifier !== undefined && messageData.sender.identifier !== "") {
                        return messageData.sender.identifier
                    } else if (messageData.senderId !== "") {
                        return messageData.senderId
                    }
                }
            }
            return ""
        }
        showDeliveryStatus: true
    }

    Loader {
        id: statusIconLoader
        active: !incoming && !selectMode
        Component.onCompleted: setSource(Qt.resolvedUrl("MessageStatusIcon.qml"),
                                         {"parent": Qt.binding(function(){ return messageDelegate._lastItem }),
                                          "incoming": Qt.binding(function(){ return messageDelegate.incoming }),
                                          "selectMode": Qt.binding(function(){ return messageDelegate.selectMode }),
                                          "textMessageStatus": Qt.binding(function(){ return messageData.textMessageStatus }),
                                          "messageDelegate": messageDelegate,
                                         });
    }
}
