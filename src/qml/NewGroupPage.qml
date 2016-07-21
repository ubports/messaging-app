/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import ".."

Page {
    id: newGroupPage
    property bool multimedia: false
    property bool creationInProgress: false
    property var basePage: null
    property var recipients: []
    function onPhonePickedDuringSearch(phoneNumber) {
        multiRecipient.addRecipient(phoneNumber)
        multiRecipient.clearSearch()
        multiRecipient.forceActiveFocus()
    }

    header: PageHeader {
        id: pageHeader
        title: creationInProgress ? i18n.tr("Creating Group...") : i18n.tr("New Group")
    }


    ChatEntry {
        id: chatEntry
        accountId: {
            for (var i in telepathyHelper.accounts) {
                var account = telepathyHelper.accounts[i]
                if (account.type == AccountEntry.MultimediaAccount && account.connected) {
                    return account.accountId
                }
            }
        }
        title: groupTitle.text
        autoRequest: false
        chatType: HistoryThreadModel.ChatTypeRoom
        onChatReady: {
            // give history service time to create the thread
            creationTimer.start()
        }
        participantIds: multiRecipient.recipients
        onStartChatFailed: {
            application.showNotificationMessage(i18n.tr("Failed to create group"), "dialog-error-symbolic")
            mainStack.removePage(newGroupPage)
        }
    }
    Timer {
        id: creationTimer
        interval: 1000
        onTriggered: {
            var properties ={}
            properties["accountId"] = chatEntry.accountId
            properties["threadId"] = chatEntry.chatId
            properties["chatType"] = chatEntry.chatType

            mainView.emptyStack()
            mainView.startChat(properties)
        }
    }

    Flickable {
        clip: true
        flickableDirection: Flickable.VerticalFlick
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            topMargin: units.gu(2)
            bottom: bottomPanel.top
        }
        contentWidth: parent.width
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            height: childrenRect.height
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)
            enabled: !creationInProgress
            anchors.horizontalCenter: parent.horizontalCenter

            ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: creationInProgress
                visible: running
            }
            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
        
                Label {
                    height: units.gu(4)
                    verticalAlignment: Text.AlignVCenter
                    text: i18n.tr("Group name:")
                }
                TextField {
                    id: groupTitle
                    height: units.gu(4)
                    placeholderText: i18n.tr("Type a name...")
                }
            }
            MultiRecipientInput {
                id: multiRecipient
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                defaultHint: i18n.tr("Members..")
                height: units.gu(4)
                Component.onCompleted: {
                    for (var i in newGroupPage.recipients) {
                        addRecipient(newGroupPage.recipients[i])
                    }
                }
                Icon {
                    name: "add"
                    height: units.gu(2)
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Qt.inputMethod.hide()
                            mainStack.addFileToCurrentColumnSync(basePage,  Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": multiRecipient})
                        }
                        z: 2
                    }
                }
            }
            Loader {
                id: searchListLoader

                property int resultCount: (status === Loader.Ready) ? item.count : 0

                source: (multiRecipient.searchString !== "") && multiRecipient.focus ?
                        Qt.resolvedUrl("ContactSearchList.qml") : ""
                visible: source != ""
                // TODO: make this variable depending on the size of the screen
                anchors.top: multiRecipient.bottom
                height: visible ? units.gu(15) : 0
                width: multiRecipient.width
                clip: true
                Behavior on height {
                    UbuntuNumberAnimation { }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.palette.normal.background
                }

                Binding {
                    target: searchListLoader.item
                    property: "filterTerm"
                    value: multiRecipient.searchString
                    when: (searchListLoader.status === Loader.Ready)
                }

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.phonePicked.connect(newGroupPage.onPhonePickedDuringSearch)
                    }
                }
            }
        }
    }

    Row {
        id: bottomPanel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: keyboard.top
        anchors.bottomMargin: units.gu(2)
	spacing: units.gu(10)
        Button {
            objectName: "cancelCreateDialog"
            text: i18n.tr("Cancel")
            color: UbuntuColors.orange
            onClicked: {
                mainStack.removePage(newGroupPage)
            }
        }
        Button {
            objectName: "okCreateDialog"
            text: i18n.tr("Create")
            color: UbuntuColors.orange
            enabled: (groupTitle.text != "" || groupTitle.inputMethodComposing) && multiRecipient.recipients.length > 0
            onClicked: {
                newGroupPage.creationInProgress = true
                chatEntry.startChat()
            }
        }
    }

    KeyboardRectangle {
       id: keyboard
    }
}
