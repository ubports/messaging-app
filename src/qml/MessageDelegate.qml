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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Content 0.1
import Ubuntu.Contacts 0.1

import "dateUtils.js" as DateUtils

Item {
    id: messageDelegate

    property alias incoming: bubble.incoming
    property string textColor: incoming ? "#333333" : "white"
    property bool unread: false
    property variant activeAttachment
    property string mmsText: ""
    property string mmsTextId: ""
    property string accountLabel: ""
    property bool selectionMode: false
    property bool selected: false

    signal resend()
    signal itemPressAndHold(QtObject obj)
    signal itemClicked(QtObject obj)

    anchors {
        left: parent ? parent.left : undefined
        right: parent ? parent.right: undefined
    }
    height: attachments.height + bubbleItem.height

    Column {
        id: attachments
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: childrenRect.height

        Repeater {
            id: attachmentsRepeater

            model: textMessageAttachments
            Loader {
                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                }
                height: item ? item.height : 0
                source: {
                    if (startsWith(modelData.contentType, "image/")) {
                        return "MMS/MMSImage.qml"
                    } else if (startsWith(modelData.contentType, "video/")) {
                        return "MMS/MMSVideo.qml"
                    } else if (startsWith(modelData.contentType, "application/smil") ||
                              startsWith(modelData.contentType, "application/x-smil")) {
                        return ""
                    } else if (startsWith(modelData.contentType, "text/plain") ) {
                        mmsText = application.readTextFile(modelData.filePath)
                        mmsTextId = modelData.attachmentId
                        return ""
                    } else if (startsWith(modelData.contentType, "text/vcard") ||
                              startsWith(modelData.contentType, "text/x-vcard")) {
                        return "MMS/MMSContact.qml"
                    } else {
                        console.log("No MMS render for " + modelData.contentType)
                        return "MMS/MMSDefault.qml"
                    }
                }
                onStatusChanged: {
                    if (status == Loader.Ready) {
                        item.attachment = modelData
                        item.incoming = incoming
                    }
                }
                Connections {
                    target: item
                    onItemRemoved: {
                        console.log("attachment removed: " + modelData.attachmentId)
                        if (textMessageAttachments.length == 1) {
                            // this is the last attachment. remove the whole event
                            eventModel.removeEvent(accountId, threadId, eventId, type)
                            return
                        }
                        eventModel.removeEventAttachment(accountId, threadId, eventId, type, modelData.attachmentId)
                    }
                }
                Connections {
                    target: item
                    onItemPressAndHold: {
                        activeAttachment = modelData
                        PopupUtils.open(popoverSaveAttachmentComponent, item)
                    }
                }
                Binding {
                    target: item
                    property: "parentSelected"
                    value: messageDelegate.selected
                }
                Connections {
                    target: item
                    onItemClicked: {
                        if (item.previewer === "") {
                            activeAttachment = modelData
                            PopupUtils.open(popoverSaveAttachmentComponent, item)
                            return
                        }

                        var properties = {}
                        properties["attachment"] = item.attachment
                        mainStack.push(Qt.resolvedUrl(item.previewer), properties)
                    }
                }
            }
        }
    }

    ListItemWithActions {
        id: bubbleItem

        anchors {
            top: attachments.bottom
            left: parent.left
            right: parent.right
        }
        height: bubble.visible ? bubble.height + units.gu(2) : 0
        leftSideAction: Action {
            iconName: "delete"
            text: i18n.tr("Delete")
            onTriggered: {
                // check if this is an mms text and we have more attachments
                if (mmsText !== "" && textMessageAttachments.length > 1) {
                    // remove only the text attachment if we have more attachments
                    eventModel.removeEventAttachment(accountId, threadId, eventId, type, mmsTextId)
                    mmsText = ""
                    mmsTextId = ""
                    return
                }
                eventModel.removeEvent(accountId, threadId, eventId, type)
            }
        }

        selected: messageDelegate.selected
        selectionMode: messageDelegate.selectionMode
        onItemPressAndHold: messageDelegate.itemPressAndHold(bubbleItem)
        onItemClicked: messageDelegate.itemClicked(bubbleItem)
        onSwippingChanged: messageList.updateSwippedItem(bubbleItem)
        onSwipeStateChanged: messageList.updateSwippedItem(bubbleItem)

        MessageBubble {
            id: bubble

            anchors {
                top: parent.top
                left: incoming ? parent.left : undefined
                right: incoming ? undefined : parent.right
            }
            visible: (messageText !== "")
            messageText: textMessage !== "" ? textMessage : mmsText
            messageTimeStamp: timestamp
            messageStatus: textMessageStatus
        }
    }

    Item {
        id: statusIcon

        property var itemToAnchor: bubble.height > 0 ? bubble : attachmentsRepeater.itemAt(attachmentsRepeater.count - 1)

        height: units.gu(4)
        width: units.gu(4)
        x: itemToAnchor ? (parent.width - itemToAnchor.width) - width - units.gu(3) : 0
        y: itemToAnchor ? (parent.height - itemToAnchor.height - units.gu(3)) + (itemToAnchor.height / 2) : 0
        visible: !incoming && !messageDelegate.selectionMode

        ActivityIndicator {
            id: indicator

            anchors.centerIn: parent
            height: units.gu(2)
            width: units.gu(2)
            visible: running && !selectionMode
            // if temporarily failed or unknown status, then show the spinner
            running: (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                      textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed)
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
                onClicked: messageDelegate.resend()
            }
        }
    }
}
