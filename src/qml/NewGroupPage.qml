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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import ".."

Page {
    id: newGroupPage
    property bool multimedia: false
    property bool creationInProgress: false
    property var basePage: null
    property var participants: []

    function addRecipient(identifier, contact) {
        var alias = contact.displayLabel.label
        if (alias == "") {
            alias = identifier
        }
        onContactPickedDuringSearch(identifier, alias, contact.avatar.imageUrl)
    }

    function onContactPickedDuringSearch(identifier, alias, avatar) {
        for (var i=0; i < participantsModel.count; i++) {
            if (identifier == participantsModel.get(i).identifier) {
                application.showNotificationMessage(i18n.tr("This recipient was already selected"), "dialog-error-symbolic")
                return
            }
        }
        contactSearch.text = ""
        participantsModel.append({"identifier": identifier, "alias": alias, "avatar": avatar })
    }

    header: PageHeader {
        id: pageHeader
        title: creationInProgress ? i18n.tr("Creating Group...") : i18n.tr("New Group")
    }

    ListModel {
        id: participantsModel
        dynamicRoles: true
        property var participantIds: {
            var ids = []
            for (var i=0; i < participantsModel.count; i++) {
                console.log(participantsModel.get(i).identifier)
                ids.push(participantsModel.get(i).identifier)
            }
            return ids
        }
        Component.onCompleted: {
            for (var i in newGroupPage.participants) {
                console.log(participants[i].identifier)
                participantsModel.append(newGroupPage.participants[i])
            }
        }
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
        participantIds: participantsModel.participantIds
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

        Item {
            id: contentColumn
            height: childrenRect.height
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: units.gu(2)
            enabled: !creationInProgress

/*            ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: creationInProgress
                visible: running
            }*/
            Row {
                id: groupTitleRow
                spacing: units.gu(4)
                anchors.topMargin: units.gu(2)
                anchors {
                    top: contentColumn.top
                    left: parent.left
                    right: parent.right
                }
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
            TextField {
                id: contactSearch
                anchors.top: groupTitleRow.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                height: units.gu(4)
                style: null
                hasClearButton: false
                placeholderText: i18n.tr("Number or contact name")
                inputMethodHints: Qt.ImhNoPredictiveText
                Keys.onReturnPressed: {
                    if (text == "")
                        return
                    onContactPickedDuringSearch(text, "","")
                    text = ""
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
                            mainStack.addFileToCurrentColumnSync(basePage,  Qt.resolvedUrl("NewRecipientPage.qml"), {"itemCallback": newGroupPage})
                        }
                        z: 2
                    }
                }
            }
            Loader {
                id: searchListLoader

                property int resultCount: (status === Loader.Ready) ? item.count : 0

                source: (contactSearch.text !== "") && contactSearch.focus ?
                        Qt.resolvedUrl("ContactSearchList.qml") : ""
                visible: source != ""
                anchors.top: contactSearch.bottom
                height: item ? item.childrenRect.height : 0
                width: contactSearch.width
                clip: true
                z: 2
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
                    value: contactSearch.text
                    when: (searchListLoader.status === Loader.Ready)
                }

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.contactPicked.connect(newGroupPage.onContactPickedDuringSearch)
                    }
                }
            }
            ListItemActions {
                id: participantLeadingActions
                actions: [
                    Action {
                        iconName: "delete"
                        text: i18n.tr("Delete")
                        onTriggered: {
                            participantsModel.remove(value)
                        }
                    }
                ]
            }
            Column {
                anchors.top: contactSearch.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                Repeater {
                    id: participantsRepeater
                    model: participantsModel

                    delegate: ParticipantDelegate {
                        id: participantDelegate
                        participant: participantsModel.get(index)
                        leadingActions: participantLeadingActions
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
            color: UbuntuColors.green
            enabled: (groupTitle.text != "" || groupTitle.inputMethodComposing) && participantsModel.count > 0
            onClicked: {
                Qt.inputMethod.commit()
                newGroupPage.creationInProgress = true
                chatEntry.startChat()
            }
        }
    }

    KeyboardRectangle {
       id: keyboard
    }
}
