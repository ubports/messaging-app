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
import Ubuntu.Telephony 0.1

Column {
    id: attachmentsView

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }
    height: childrenRect.height
    property var attachments: []
    property var dataAttachments: []
    property bool incoming: false
    property bool isMultimedia: false
    property bool swipeLocked: {
        for (var i=0; i < attachmentsView.children.length; i++) {
            if (attachmentsView.children[i].item && attachmentsView.children[i].item.swipeLocked) {
                return true
            }
        }
        return false
    }
    property string messageText: ""
    property var lastItem: children.length > 0 ? children[children.length - 1] : null

    function clicked(mouse)
    {
        if (attachmentsRepeater.count === 0) {
            return
        }

        var childPoint = parent.mapToItem(attachmentsView, mouse.x, mouse.y)
        var attachment = attachmentsView.childAt(childPoint.x, childPoint.y)
        if (attachment && attachment.item && attachment.item.previewer) {
            var properties = {}
            properties["attachment"] = attachment.item.attachment
            properties["thumbnail"] = attachment.item
            mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl(attachment.item.previewer), properties)
            Qt.inputMethod.hide()
        }
    }

    onAttachmentsChanged: {
        attachmentsView.dataAttachments = []
        var textAttachments = []
        for (var i=0; i < attachments.length; i++) {
            var attachment = attachments[i]
            if (startsWith(attachment.contentType, "text/plain") ) {
                textAttachments.push(attachment)
            } else if (startsWith(attachment.contentType, "audio/")) {
                attachmentsView.dataAttachments.push({"type": "audio",
                                      "data": attachment,
                                      "delegateSource": "AttachmentDelegates/AudioDelegate.qml",
                                    })
            } else if (startsWith(attachment.contentType, "image/")) {
                attachmentsView.dataAttachments.push({"type": "image",
                                      "data": attachment,
                                      "delegateSource": "AttachmentDelegates/ImageDelegate.qml",
                                    })
            } else if (startsWith(attachment.contentType, "application/smil") ||
                       startsWith(attachment.contentType, "application/x-smil")) {
                // smil files will always be ignored here
            } else if (startsWith(attachment.contentType, "text/vcard") ||
                       startsWith(attachment.contentType, "text/x-vcard")) {
                attachmentsView.dataAttachments.push({"type": "vcard",
                                      "data": attachment,
                                      "delegateSource": "AttachmentDelegates/ContactDelegate.qml"
                                    })
            } else if (startsWith(attachment.contentType, "video/")) {
                attachmentsView.dataAttachments.push({"type": "video",
                                      "data": attachment,
                                      "delegateSource": "AttachmentDelegates/VideoDelegate.qml",
                                    })
            } else {
                attachmentsView.dataAttachments.push({"type": "default",
                                      "data": attachment,
                                      "delegateSource": "AttachmentDelegates/DefaultDelegate.qml"
                                    })
            }
        }
        attachmentsRepeater.model = attachmentsView.dataAttachments
        if (textAttachments.length > 0) {
            attachmentsView.messageText = application.readTextFile(textAttachments[0].filePath)
        }
    }

    spacing: units.gu(1)
    Repeater {
        id: attachmentsRepeater

        Loader {
            id: attachmentLoader

            states: [
                State {
                    when: attachmentsView.incoming
                    name: "incoming"
                    AnchorChanges {
                        target: attachmentLoader
                        anchors.left: parent ? parent.left : undefined
                    }
                },
                State {
                    when: !attachmentsView.incoming
                    name: "outgoing"
                    AnchorChanges {
                        target: attachmentLoader
                        anchors.right: parent ? parent.right : undefined
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
                value: attachmentsView.lastItem === attachmentLoader
                when: attachmentLoader.status === Loader.Ready
            }
            Binding {
                target: attachmentLoader.item ? attachmentLoader.item : null
                property: "isMultimedia"
                value: isMultimedia
                when: attachmentLoader.status === Loader.Ready
            }
        }
    }
}
