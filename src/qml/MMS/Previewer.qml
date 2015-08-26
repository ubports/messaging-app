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
    id: previewer
    title: ""
    property variant attachment
    signal actionTriggered
    tools: ToolbarItems {
        ToolbarButton {
            objectName: "saveButton"
            action: Action {
                text: i18n.tr("Save")
                iconSource: "image://theme/save"
                onTriggered: {
                    mainStack.addPageToCurrentColumn(previewer, picker, {"url": attachment.filePath, "handler": ContentHandler.Destination});
                    actionTriggered()
                }
            }
        }

        ToolbarButton {
            objectName: "shareButton"
            action: Action {
                iconSource: "image://theme/share"
                text: i18n.tr("Share")
                onTriggered: {
                    mainStack.addPageToCurrentColumn(previewer, picker, {"url": attachment.filePath, "handler": ContentHandler.Share});
                    actionTriggered()
                }
            }
        }
    }

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
            target: picker.curTransfer !== null ? picker.curTransfer : null
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
