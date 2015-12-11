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
import Ubuntu.Components 1.3
import Ubuntu.Content 0.1
import ".."

Page {
    id: previewerPage

    property variant attachment
    property variant thumbnail

    signal actionTriggered

    function handleAttachment(filePath, handlerType)
    {
        mainStack.push(picker, {"url": filePath, "handler": handlerType});
        actionTriggered()
    }

    function saveAttachment()
    {
        previewerPage.handleAttachment(attachment.filePath, ContentHandler.Destination)
    }

    function shareAttchment()
    {
        previewerPage.handleAttachment(attachment.filePath, ContentHandler.Share)
    }

    function backAction()
    {
        mainStack.pop()
    }

    title: ""
    state: "default"
    states: [
        PageHeadState {
            name: "default"
            head: previewerPage.head
            backAction: Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: previewerPage.backAction()
            }
            actions: [
                Action {
                    objectName: "saveButton"
                    text: i18n.tr("Save")
                    iconSource: "image://theme/save"
                    onTriggered: previewerPage.saveAttachment()
                },
                Action {
                    objectName: "shareButton"
                    iconSource: "image://theme/share"
                    text: i18n.tr("Share")
                    onTriggered: previewerPage.shareAttchment()
                }
            ]
        }
    ]

    Component {
        id: resultComponent
        ContentItem {}
    }

    Page {
        id: picker
        visible: false
        property var curTransfer
        property var url
        property var handler
        property var contentType: getContentType(url)

        function __exportItems(url) {
            if (picker.curTransfer.state === ContentTransfer.InProgress)
            {
                picker.curTransfer.items = [ resultComponent.createObject(mainView, {"url": url}) ];
                picker.curTransfer.state = ContentTransfer.Charged;
            }
        }

        // invisible header
        header: Item { height: 0 }

        ContentPeerPicker {
            visible: parent.visible
            contentType: picker.contentType
            handler: picker.handler

            onPeerSelected: {
                picker.curTransfer = peer.request();
                mainStack.removePages(picker);
                if (picker.curTransfer.state === ContentTransfer.InProgress)
                    picker.__exportItems(picker.url);
            }
            onCancelPressed: mainStack.removePages(picker);
        }

        Connections {
            target: picker.curTransfer ? picker.curTransfer : null
            onStateChanged: {
                console.log("curTransfer StateChanged: " + picker.curTransfer.state);
                if (picker.curTransfer.state === ContentTransfer.InProgress)
                {
                    picker.__exportItems(picker.url);
                }
            }
        }
    }
}
