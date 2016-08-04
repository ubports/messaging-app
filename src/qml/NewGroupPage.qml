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
    property var participants: []
    property var account: null

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
        title: {
            if (creationInProgress) {
                return i18n.tr("Creating Group...")
            }
            if (multimedia) {
                return i18n.tr("New %1 Group").arg(mainView.multimediaAccount.displayName)
            } else {
                return i18n.tr("New MMS Group")
            }
        }
        leadingActionBar {
            actions: [
                Action {
                    objectName: "cancelAction"
                    iconName: "close"
                    onTriggered: {
                        Qt.inputMethod.commit()
                        mainStack.removePages(newGroupPage)
                    }
                }
            ]
        }
        trailingActionBar {
            actions: [
                Action {
                    objectName: "createAction"
                    enabled: {
                        if (participantsModel.count == 0) {
                            return false
                        }
                        if (multimedia) {
                            return ((groupTitleField.text != "" || groupTitleField.inputMethodComposing) && participantsModel.count > 0)
                        }
                        return participantsModel.count > 1
                    }
                    iconName: "ok"
                    onTriggered: {
                        Qt.inputMethod.commit()
                        newGroupPage.creationInProgress = true
                        chatEntry.startChat()
                    }
                }
            ]
        }

        extension: Sections {
            id: newGroupHeaderSections
            objectName: "newGroupHeaderSections"
            height: !visible ? 0: undefined
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            visible: {
                if (newGroupPage.account.type == AccountEntry.GenericType) {
                    return true
                }
                console.log("mainView.multiplePhoneAccounts", mainView.multiplePhoneAccounts)
                // only show if we have more than one sim card
                return mainView.multiplePhoneAccounts
            }
            enabled: visible
            model: [account.displayName]
        }
    }

    ListModel {
        id: participantsModel
        dynamicRoles: true
        property var participantIds: {
            var ids = []
            for (var i=0; i < participantsModel.count; i++) {
                ids.push(participantsModel.get(i).identifier)
            }
            return ids
        }
        Component.onCompleted: {
            for (var i in newGroupPage.participants) {
                participantsModel.append(newGroupPage.participants[i])
            }
        }
    }

    ChatEntry {
        id: chatEntry
        accountId: {
            if (newGroupPage.multimedia) {
                return mainView.multimediaAccount.accountId
            }
            return newGroupPage.account.accountId
        }
        title: groupTitleField.text
        autoRequest: false
        chatType: newGroupPage.multimedia ? HistoryThreadModel.ChatTypeRoom : HistoryThreadModel.ChatTypeNone
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
            properties["participantIds"] = chatEntry.participantIds

            mainView.emptyStack()
            mainView.startChat(properties)
        }
    }

    Loader {
        id: searchListLoader

        property int resultCount: (status === Loader.Ready) ? item.count : 0

        source: (contactSearch.text !== "") && contactSearch.focus ?
                Qt.resolvedUrl("ContactSearchList.qml") : ""
        visible: source != ""
        height: flick.emptySpaceHeight
        anchors.left: parent.left
        anchors.bottom: keyboard.top
        width: contactSearch.width
        clip: true
        z: 2
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

    Flickable {
        id: flick
        clip: true
        property var emptySpaceHeight: height - contentColumn.topItemsHeight+flick.contentY
        flickableDirection: Flickable.VerticalFlick
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            topMargin: units.gu(1)
            bottom: keyboard.top
        }
        contentWidth: parent.width
        contentHeight: contentColumn.height

        FocusScope {
            id: contentColumn
            property var topItemsHeight: groupTitleItem.height+membersLabel.height+contactSearch.height+units.gu(1)
            height: childrenRect.height
            anchors.left: parent.left
            anchors.right: parent.right
            enabled: !creationInProgress

/*            ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: creationInProgress
                visible: running
            }*/
            Item {
                id: groupTitleItem
                clip: true 
                height: multimedia ? childrenRect.height : 0
                anchors {
                    top: contentColumn.top
                    left: parent.left
                    right: parent.right
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }
                Label {
                    id: groupNameLabel
                    height: units.gu(4)
                    verticalAlignment: Text.AlignVCenter
                    anchors.left: parent.left
                    text: i18n.tr("Group name:")
                }
                TextField {
                    id: groupTitleField
                    anchors {
                        left: groupNameLabel.right
                        leftMargin: units.gu(2)
                        right: parent.right
                    }
                    height: units.gu(4)
                    placeholderText: i18n.tr("Type a name...")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    Timer {
                        interval: 1
                        onTriggered: {
                            if (!multimedia) {
                                return
                            }
                            groupTitleField.forceActiveFocus()
                        }
                        Component.onCompleted: start()
                    }
                }
            }
            Label {
                id: membersLabel
                anchors.top: groupTitleItem.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                height: units.gu(4)
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("Members:")
            }
            TextField {
                id: contactSearch
                anchors.top: membersLabel.bottom
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.right: parent.right
                height: units.gu(5)
                style: TransparentTextFieldStype { }
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
                            mainStack.addPageToCurrentColumn(newGroupPage, Qt.resolvedUrl("NewRecipientPage.qml"), {"itemCallback": newGroupPage})
                        }
                        z: 2
                    }
                    Timer {
                        interval: 1
                        onTriggered: {
                            if (!multimedia) {
                                return
                            }
                            groupTitleField.forceActiveFocus()
                        }
                        Component.onCompleted: start()
                    }
                }
            }
            Rectangle {
               anchors {
                   left: parent.left
                   right: parent.right
                   top: contactSearch.top
               }
               height: 1
               color: UbuntuColors.lightGrey
               z: 2
            }
            Rectangle {
               anchors {
                   left: parent.left
                   right: parent.right
                   bottom: contactSearch.bottom
               }
               height: 1
               color: UbuntuColors.lightGrey
               z: 2
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
                id: participantsColumn
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

    KeyboardRectangle {
       id: keyboard
    }
}
