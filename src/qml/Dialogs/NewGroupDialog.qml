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
import Ubuntu.Components.Popups 1.3
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import ".."

Component {
    Dialog {
        id: dialogue
        title: creationInProgress ? i18n.tr("Creating Group...") : i18n.tr("New Group")
        property bool creationInProgress: false
        function onPhonePickedDuringSearch(phoneNumber) {
            multiRecipient.addRecipient(phoneNumber)
            multiRecipient.clearSearch()
            multiRecipient.forceActiveFocus()
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
            chatType: HistoryThreadModel.ChatTypeRoom
            onChatReady: {
                // give history service time to create the thread
                creationTimer.start()
            }
            participantIds: multiRecipient.recipients
            onStartChatFailed: {
                application.showNotificationMessage(i18n.tr("Failed to create group"), "dialog-error-symbolic")
                PopupUtils.close(dialogue)
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

                mainView.startChat(properties)
                PopupUtils.close(dialogue)
            }
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)
            enabled: !creationInProgress

            ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: creationInProgress
                visible: running
            }
            TextField {
                id: groupTitle
                anchors.left: parent.left
                anchors.right: parent.right
                placeholderText: i18n.tr("Group Title")
            }
            MultiRecipientInput {
                id: multiRecipient
                anchors.left: parent.left
                anchors.right: parent.right
                defaultHint: i18n.tr("Members..")
                height: units.gu(4)
            }
            Loader {
                id: searchListLoader

                property int resultCount: (status === Loader.Ready) ? item.count : 0

                source: (multiRecipient.searchString !== "") && multiRecipient.focus ?
                        Qt.resolvedUrl("../ContactSearchList.qml") : ""
                visible: source != ""
                // TODO: make this variable depending on the size of the screen
                height: units.gu(10)
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
                        item.phonePicked.connect(dialogue.onPhonePickedDuringSearch)
                    }
                }
            }
            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    objectName: "cancelCreateDialog"
                    text: i18n.tr("Cancel")
                    color: UbuntuColors.orange
                    onClicked: {
                        PopupUtils.close(dialogue)
                    }
                }

                Button {
                    objectName: "okCreateDialog"
                    text: i18n.tr("Create")
                    color: UbuntuColors.orange
                    onClicked: {
                        dialogue.creationInProgress = true
                        chatEntry.startChat()
                    }
                }
            }
        }
    }
}
