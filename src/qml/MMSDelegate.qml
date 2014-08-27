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

MessageDelegate {
    id: root

    property var attachments: messageData.textMessageAttachments
    property var dataAttachments: []
    property var textAttachements: []
    property string messageText: ""

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
        eventModel.removeEvent(messageData.accountId,
                               messageData.threadId,
                               messageData.eventId,
                               messageData.type)
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
            attachment.push(item.attachmentId)
            attachment.push(item.contentType)
            attachment.push(item.filePath)
            newAttachments.push(attachment)
        }
        eventModel.removeEvent(messageData.accountId,
                               messageData.threadId,
                               messageData.eventId,
                               messageData.type)
        // FIXME: export this information for MessageDelegate
        chatManager.sendMMS(participants, textMessage, newAttachments, messages.account.accountId)
    }

    function copyMessage()
    {
        Clipboard.push(root.messageText)
    }

    onAttachmentsChanged: {
        root.dataAttachments = []
        root.textAttachements = []
        for (var i=0; i < attachments.length; i++) {
            var attachment = attachments[i]
            if (startsWith(attachment.contentType, "text/plain") ) {
                root.textAttachements.push(attachment)
            } else if (startsWith(attachment.contentType, "image/")) {
                root.dataAttachments.push({"type": "image",
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
                root.dataAttachments.push({"type": "vcard",
                                      "data": attachment,
                                      "delegateSource": "MMS/MMSContact.qml"
                                    })
            } else {
                console.log("No MMS render for " + attachment.contentType)
            }
        }
        attachmentsRepeater.model = root.dataAttachments
        if (root.textAttachements.length > 0) {
            root.messageText = application.readTextFile(root.textAttachements[0].filePath)
            bubbleLoader.active = true
        }
    }
    height: attachmentsView.height
    _lastItem: bubbleLoader.active ? bubbleLoader : attachmentsRepeater.itemAt(attachmentsRepeater.count - 1)
    Column {
        id: attachmentsView

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: childrenRect.height

        spacing: units.gu(0.5)
        Repeater {
            id: attachmentsRepeater

            Loader {
                id: attachmentLoader

                states: [
                    State {
                        when: root.incoming
                        name: "incoming"
                        AnchorChanges {
                            target: attachmentLoader
                            anchors.left: parent ? parent.left : undefined
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
                            anchors.right: parent ? parent.right : undefined
                        }
                        PropertyChanges {
                            target: attachmentLoader
                            anchors.leftMargin: 0
                            anchors.rightMargin: units.gu(1)
                        }
                    }
                ]
                source: modelData.delegateSource
                Binding {
                    target: attachmentLoader.item ? attachmentLoader.item : null
                    property: "attachment"
                    value: modelData.data
                    when: attachmentLoader.status === Loader.Ready
                }
                Binding {
                    target: attachmentLoader.item ? attachmentLoader.item : null
                    property: "lastItem"
                    value: (index === (attachmentsRepeater.count - 1)) && (root.textAttachements.length === 0)
                    when: attachmentLoader.status === Loader.Ready
                }
            }
        }

        Loader {
            id: bubbleLoader

            source: Qt.resolvedUrl("MMSMessageBubble.qml")
            active: false

            states: [
                State {
                    when: incoming
                    name: "incoming"
                    AnchorChanges {
                        target: bubbleLoader
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "outgoing"
                    when: !incoming
                    AnchorChanges {
                        target: bubbleLoader
                        anchors.right: parent.right
                    }
                }
            ]

            Binding {
                target: bubbleLoader.item
                property: "messageText"
                value: root.messageText.length > 0 ? root.messageText : i18n.tr("Missing message data")
                when: bubbleLoader.status === Loader.Ready
            }
        }
    }
}
