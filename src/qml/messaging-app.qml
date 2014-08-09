/*
 * Copyright 2012-2013 Canonical Ltd.
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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Content 0.1

MainView {
    id: mainView

    property string newPhoneNumber
    property bool multipleAccounts: telepathyHelper.accounts.length > 1
    property QtObject defaultAccount: {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multipleAccounts) {
            return telepathyHelper.defaultMessagingAccount
        } else {
            return telepathyHelper.accounts[0]
        }
    }

    automaticOrientation: true
    width: units.gu(40)
    height: units.gu(71)
    useDeprecatedToolbar: false
    anchorToKeyboard: false

    Component.onCompleted: {
        i18n.domain = "messaging-app"
        i18n.bindtextdomain("messaging-app", i18nDirectory)
        mainStack.push(Qt.resolvedUrl("MainPage.qml"))
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            if (multipleAccounts && !telepathyHelper.defaultMessagingAccount && 
                settings.mainViewDontAskCount < 3 && mainStack.depth === 1) {
                PopupUtils.open(noSimCardDefault)
            }
        }
    }

    Component {
        id: noSimCardDefault
        Dialog {
            id: dialogue
            title: i18n.tr("Switch to default SIM:")
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: units.gu(2)

                Row {
                    spacing: units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: paintedHeight + units.gu(3)
                    Repeater {
                        model: telepathyHelper.accounts
                        delegate: Label {
                            text: modelData.displayName
                            color: UbuntuColors.orange
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    PopupUtils.close(dialogue)
                                    telepathyHelper.setDefaultAccount(TelepathyHelper.Messaging, modelData)
                                }
                            }
                        }
                    }
                }

                Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: paintedHeight + units.gu(6)
                    verticalAlignment: Text.AlignVCenter
                    text: i18n.tr("Select a default SIM for all outgoing messages. You can always alter your choice in <a href=\"system_settings\">System Settings</a>.")
                    wrapMode: Text.WordWrap
                    onLinkActivated: {
                        PopupUtils.close(dialogue)
                        Qt.openUrlExternally("settings:///system/cellular")
                    }
                }
                Row {
                    spacing: units.gu(4)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        objectName: "noNoSimCardDefaultDialog"
                        text: i18n.tr("No")
                        color: UbuntuColors.orange
                        onClicked: {
                            settings.mainViewDontAskCount = 3
                            PopupUtils.close(dialogue)
                            Qt.inputMethod.hide()
                        }
                    }
                    Button {
                        objectName: "laterNoSimCardDefaultDialog"
                        text: i18n.tr("Later")
                        color: UbuntuColors.orange
                        onClicked: {
                            PopupUtils.close(dialogue)
                            settings.mainViewDontAskCount++
                            Qt.inputMethod.hide()
                        }

                    }
                }
            }
        }
    }


    Settings {
        id: settings
        category: "DualSim"
        property bool messagesDontAsk: false
        property int mainViewDontAskCount: 0
    }

    Component {
        id: resultComponent
        ContentItem {}
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            var properties = {}
            emptyStack()
            properties["sharedAttachmentsTransfer"] = transfer
            mainStack.currentPage.showBottomEdgePage(Qt.resolvedUrl("Messages.qml"), properties)
        }
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
                mainStack.pop();
                if (picker.curTransfer.state === ContentTransfer.InProgress)
                    picker.__exportItems(picker.url);
            }
            onCancelPressed: mainStack.pop();
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

    signal applicationReady

    function startsWith(string, prefix) {
        return string.toLowerCase().slice(0, prefix.length) === prefix.toLowerCase();
    }

    function getContentType(filePath) {
        var contentType = application.fileMimeType(String(filePath).replace("file://",""))
        if (startsWith(contentType, "image/")) {
            return ContentType.Pictures
        } else if (startsWith(contentType, "text/vcard") ||
                   startsWith(contentType, "text/x-vcard")) {
            return ContentType.Contacts
        }
        return ContentType.Unknown
    }

    function emptyStack() {
        while (mainStack.depth !== 1 && mainStack.depth !== 0) {
            mainStack.pop()
        }
    }

    function startNewMessage() {
        var properties = {}
        emptyStack()
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    function startChat(phoneNumber) {
        var properties = {}
        var participants = [phoneNumber]
        properties["participants"] = participants
        emptyStack()
        if (phoneNumber === "") {
            return;
        }
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }


    PageStack {
        id: mainStack

        objectName: "mainStack"
    }
}
