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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import ".."

Page {
    id: newGroupPage
    property bool mmsGroup: true
    property bool creationInProgress: false
    property var participants: []
    property var account: null
    readonly property bool allowCreateGroup: {
        if (newGroupPage.creationInProgress) {
            return false
        }
        if (account.protocolInfo.joinExistingChannels && groupTitleField.text != "") {
            return true
        }
        if (participantsModel.count == 0) {
            return false
        }
        if (!mmsGroup) {
            return ((groupTitleField.text != "" || groupTitleField.inputMethodComposing) && participantsModel.count > 1)
        }
        return participantsModel.count > 1
    }

    function addRecipient(identifier, contact) {
        var alias = contact.displayLabel.label
        if (alias == "") {
            alias = identifier
        }
        addRecipientFromSearch(identifier, alias, contact.avatar.imageUrl)
    }

    function addRecipientFromSearch(identifier, alias, avatar) {
        for (var i=0; i < participantsModel.count; i++) {
            if (identifier == participantsModel.get(i).identifier) {
                application.showNotificationMessage(i18n.tr("This recipient was already selected"), "dialog-error-symbolic")
                return
            }
        }
        searchItem.text = ""
        participantsModel.append({"identifier": identifier, "alias": alias, "avatar": avatar })
    }

    function commit() {
        if (allowCreateGroup) {
            Qt.inputMethod.commit()
            newGroupPage.creationInProgress = true
            if (account.protocolInfo.joinExistingChannels) {
               chatEntry.chatId = groupTitleField.text
            }
            chatEntry.startChat()
        }
    }

    header: PageHeader {
        title: {
            if (creationInProgress) {
                return i18n.tr("Creating Group...")
            }
            if (mmsGroup) {
                return i18n.tr("New MMS Group")
            } else {
                // FIXME: temporary workaround
                if (account && account.protocolInfo.name == "irc") {
                    return i18n.tr("Join IRC channel:")
                }
                var protocolDisplayName = account.protocolInfo.serviceDisplayName;
                if (protocolDisplayName === "") {
                   protocolDisplayName = account.protocolInfo.serviceName;
                }
                return i18n.tr("New %1 Group").arg(protocolDisplayName);
            }
        }
        leadingActionBar {
            actions: [
                Action {
                    objectName: "cancelAction"
                    iconName: "close"
                    shortcut: "Esc"
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
                    id: createAction
                    objectName: "createAction"
                    enabled: newGroupPage.allowCreateGroup
                    iconName: "ok"
                    onTriggered: newGroupPage.commit()
                }
            ]
        }

        extension: Sections {
            id: newGroupHeaderSections
            objectName: "newGroupHeaderSections"
            height: !visible ? 0 : undefined
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            visible: {
                // only show if we have more than one sim card
                return account.type == AccountEntry.PhoneAccount && mainView.multiplePhoneAccounts
            }
            enabled: visible
            model: visible ? [account.displayName] : undefined
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
        accountId: newGroupPage.account.accountId
        title: groupTitleField.text
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
            properties["participantIds"] = chatEntry.participantIds

            mainView.emptyStack()
            mainView.startChat(properties)
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
            bottom: keyboard.top
        }
        contentWidth: parent.width
        contentHeight: contentColumn.height

        FocusScope {
            id: contentColumn
            property var topItemsHeight: groupNameItem.height+searchItem.height
            height: childrenRect.height
            anchors.left: parent.left
            anchors.right: parent.right
            enabled: !creationInProgress

            Item {
                id: groupNameItem
                clip: true
                height: mmsGroup ? 0 : units.gu(6)
                anchors {
                    top: contentColumn.top
                    left: parent.left
                    right: parent.right
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }
                Label {
                    id: groupNameLabel
                    height: units.gu(2)
                    verticalAlignment: Text.AlignVCenter
                    anchors.verticalCenter: groupTitleField.verticalCenter
                    anchors.left: parent.left
                    text: {
                        // FIXME: temporary workaround
                        if (account && account.protocolInfo.name == "irc") {
                            return i18n.tr("Channel name:")
                        }
                        return i18n.tr("Group name:")
                    }
                }
                TextField {
                    id: groupTitleField
                    anchors {
                        left: groupNameLabel.right
                        leftMargin: units.gu(2)
                        right: parent.right
                        topMargin: units.gu(1)
                        top: parent.top
                    }
                    height: units.gu(4)
                    placeholderText: {
                        // FIXME: temporary workaround
                        if (account && account.protocolInfo.name == "irc") {
                            return i18n.tr("#channelName")
                        }
                        return i18n.tr("Type a name...")
                    }
                    inputMethodHints: Qt.ImhNoPredictiveText
                    Keys.onReturnPressed: newGroupPage.commit()
                    Keys.onEnterPressed: newGroupPage.commit()
                    Timer {
                        interval: 1
                        onTriggered: {
                            if (mmsGroup) {
                                return
                            }
                            groupTitleField.forceActiveFocus()
                        }
                        Component.onCompleted: start()
                    }
                }
            }
            Rectangle {
               id: separator
               anchors {
                   left: parent.left
                   right: parent.right
                   bottom: groupNameItem.bottom
               }
               height: 1
               color: theme.palette.selected.base
               z: 2
            }
            ContactSearchWidget {
                id: searchItem
                parentPage: newGroupPage
                visible: !account.protocolInfo.joinExistingChannels
                searchResultsHeight: flick.emptySpaceHeight
                onContactPicked: addRecipientFromSearch(identifier, alias, avatar)
                anchors {
                    left: parent.left
                    right: parent.right
                    top: groupNameItem.bottom
                }
            }
            Rectangle {
               id: separator2
               visible: !account.protocolInfo.joinExistingChannels
               anchors {
                   left: parent.left
                   right: parent.right
                   bottom: searchItem.bottom
               }
               height: 1
               color: theme.palette.selected.base
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
                anchors.top: searchItem.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                visible: !account.protocolInfo.joinExistingChannels
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

    onActiveChanged: {
        if (active)
            searchItem.forceActiveFocus()
    }

    Component.onCompleted: searchItem.forceActiveFocus()
}
