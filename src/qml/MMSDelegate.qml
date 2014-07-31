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

MessageDelegate {
    id: root

    property var dataAttachments: []
    property var textAttachements: []

    function clicked(mouse)
    {
        var childPoint = root.mapToItem(attachmentsView, mouse.x, mouse.y)
        var attachment = attachmentsView.childAt(childPoint.x, childPoint.y)
        if (attachment && attachment.item && attachment.item.previewer) {
            var properties = {}
            properties["attachment"] = attachment.item.attachment
            mainStack.push(Qt.resolvedUrl(attachment.item.previewer), properties)
        }
    }

    function deleteMessage()
    {
        eventModel.removeEvent(accountId, threadId, eventId, type)
    }

    function resendMessage()
    {
        var newAttachments = []
        for (var i = 0; i < attachments.length; i++) {
            var attachment = []
            var item = textMessageAttachments[i]
            // we dont include smil files. they will be auto generated
            if (item.contentType.toLowerCase() == "application/smil") {
                continue
            }
            attachment.push(item.attachmentId)
            attachment.push(item.contentType)
            attachment.push(item.filePath)
            newAttachments.push(attachment)
        }
        eventModel.removeEvent(accountId, threadId, eventId, type)
        chatManager.sendMMS(participants, textMessage, newAttachments, messages.accountId)
    }

    function copyMessage()
    {
        if (bubble.visible) {
            Clipboard.push(bubble.messageText)
        }
    }

    onAttachmentsChanged: {
        dataAttachments = []
        textAttachements = []
        for (var i=0; i < attachments.length; i++) {
            var attachment = attachments[i]
            if (startsWith(attachment.contentType, "text/plain") ) {
                textAttachements.push(attachment)
            } else if (startsWith(attachment.contentType, "image/")) {
                dataAttachments.push({"type": "image",
                                      "data": attachment,
                                      "delegateSource": "MMS/MMSImage.qml",
                                    })
            } else if (startsWith(attachment.contentType, "video/")) {
// TODO: implement proper video attachment support
//                dataAttachments.push({type: "video",
//                                  data: attachment,
//                                  delegateSource: "MMS/MMSVideo.qml",
//                                 })
            } else if (startsWith(attachment.contentType, "application/smil") ||
                       startsWith(attachment.contentType, "application/x-smil")) {
// TODO: implement support for this kind of attachment
//                dataAttachments.push({type: "application",
//                                  data: attachment,
//                                  delegateSource: "",
//                                 })
            } else if (startsWith(attachment.contentType, "text/vcard") ||
                       startsWith(attachment.contentType, "text/x-vcard")) {
                dataAttachments.push({"type": "vcard",
                                      "data": attachment,
                                      "delegateSource": "MMS/MMSContact.qml"
                                    })
            } else {
                console.log("No MMS render for " + attachment.contentType)
            }
        }
    }
    height: attachmentsView.height
    _lastItem: bubble.visible ? bubble : attachmentsRepeater.itemAt(attachmentsRepeater - 1)
    Column {
        id: attachmentsView

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: childrenRect.height

        Repeater {
            id: attachmentsRepeater
            model: dataAttachments

            Loader {
                id: attachmentLoader
                states: [
                    State {
                        when: root.incoming
                        name: "incoming"
                        AnchorChanges {
                            target: attachmentLoader
                            anchors.left: parent.left
                            anchors.right: undefined
                        }
                        PropertyChanges {
                            target: attachmentLoader
                            anchors.leftMargin: units.gu(1)
                            anchors.rightMargin: 0
                        }
                    },
                    State {
                        when: !root.incoming
                        name: "outgoing"
                        AnchorChanges {
                            target: attachmentLoader
                            anchors.left: undefined
                            anchors.right: parent.right
                        }
                        PropertyChanges {
                            target: attachmentLoader
                            anchors.leftMargin: 0
                            anchors.rightMargin: units.gu(1)
                        }
                    }
                ]

                height: attachmentLoader.item ? attachmentLoader.item.height : 0
                width: attachmentLoader.item ? attachmentLoader.item.width : 0
                source: modelData.delegateSource
                onStatusChanged: {
                    if (status === Loader.Ready) {
                        attachmentLoader.item.incoming = root.incoming
                        attachmentLoader.item.attachment = modelData.data
                        if (index === (attachmentsRepeater.count -1)) {
                            root._lastItem = attachmentLoader.item
                        }
                    }
                }
//                Connections {
//                    target: status === Loader.Ready ? item : null
//                    onItemRemoved: {
//                        if (root.attachments.length === 1) {
//                            // this is the last attachment. remove the whole event
//                            eventModel.removeEvent(accountId, threadId, eventId, type)
//                        } else {
//                            eventModel.removeEventAttachment(accountId, threadId, eventId, type, modelData.attachmentId)
//                        }
//                    }
//                }
//                Connections {
//                    target: item
//                    onItemClicked: {
//                        var properties = {}
//                        properties["attachment"] = item.attachment
//                        mainStack.push(Qt.resolvedUrl(item.previewer), properties)
//                    }
//                }
            }
        }

        // TODO: is possible to have more than one text ???
        MessageBubble {
            id: bubble

            anchors {
                left: root.incoming ? parent.left : undefined
                right: root.incoming ? undefined : parent.right
            }
            visible: (root.textAttachements.length > 0)
            messageText: visible ? application.readTextFile(root.textAttachements[0].filePath) : ""
            messageTimeStamp: timestamp
            messageStatus: textMessageStatus
        }
    }
}
