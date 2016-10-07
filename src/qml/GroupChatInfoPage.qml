/*
 * Copyright 2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3
import Ubuntu.History 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.Keyboard 0.1
import Ubuntu.Telephony 0.1

Page {
    id: groupChatInfoPage

    property variant threads: []
    property var account: telepathyHelper.accountForId(threads[0].accountId)
    property variant participants: {
        if (chatEntry.active) {
            return chatEntry.participants
        } else if (threads.length > 0) {
            return threads[0].participants
        }
        return []
    }
    property variant localPendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.localPendingParticipants
        } else if (threads.length > 0) {
            return threads[0].localPendingParticipants
        }
        return []
    }
    property variant remotePendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.remotePendingParticipants
        } else if (threads.length > 0) {
            return threads[0].remotePendingParticipants
        }
        return []
    }
    property variant allParticipants: {
        var participantList = []

        for (var i in participants) {
            var participant = participants[i]
            participant["state"] = 0
            participant["selfContact"] = false
            participantList.push(participant)
        }
        for (var i in localPendingParticipants) {
            var participant = localPendingParticipants[i]
            participant["state"] = 1
            participant["selfContact"] = false
            participantList.push(participant)
        }
        for (var i in remotePendingParticipants) {
            var participant = remotePendingParticipants[i]
            participant["state"] = 2
            participant["selfContact"] = false
            participantList.push(participant)
        }

        if (chatRoom && (chatEntry.active || chatRoomInfo.Joined)) {
            var participant = selfContactWatcher
            if (chatEntry.active || chatRoomInfo.Joined) {
                participantList.push(participant)
            }
        }
        return participantList
    }

    property QtObject chatEntry: null
    property QtObject eventModel: null

    property var threadId: threads.length > 0 ? threads[0].threadId : ""
    property int chatType: threads.length > 0 ? threads[0].chatType : HistoryThreadModel.ChatTypeNone
    property bool chatRoom: chatType == HistoryThreadModel.ChatTypeRoom
    property var chatRoomInfo: threads.length > 0 ? threads[0].chatRoomInfo : []

    // self contact isn't provided by history or chatEntry, so we manually add it here
    Item {
        id: selfContactWatcher
        property alias identifier: internalContactWatcher.identifier
        property alias contactId: internalContactWatcher.contactId
        property alias avatar: internalContactWatcher.avatar
        property var alias: {
            if (contactId == "") {
                return i18n.tr("Me")
            }
            return internalContactWatcher.alias
        }
        property bool selfContact: true
        property int state: 0
        property int roles: {
            if(chatEntry.active) {
                return chatEntry.selfContactRoles
            } else if (chatRoomInfo.Joined) {
                return chatRoomInfo.SelfRoles
            }
            return 0
        }

        ContactWatcher {
            id: internalContactWatcher
            identifier: groupChatInfoPage.account.selfContactId
            addressableFields: groupChatInfoPage.account ? groupChatInfoPage.account.addressableVCardFields : ["tel"] // just to have a fallback there
        }
    }

    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Group Info")
        // FIXME: uncomment once the header supports subtitle
        //subtitle: i18n.tr("%1 member", "%1 members", allParticipants.length)
        flickable: contentsFlickable
    }

    function addRecipientFromSearch(identifier, alias, avatar) {
        addRecipient(identifier, null)
    }

    function addRecipient(identifier, contact) {
        for (var i=0; i < allParticipants; i++) {
            if (identifier == allParticipants[i].identifier) {
                application.showNotificationMessage(i18n.tr("This recipient was already selected"), "dialog-error-symbolic")
                return
            }
        }
        searchItem.text = ""

        chatEntry.inviteParticipants([identifier], "")
    }

    function removeParticipant(index) {
        var participantDelegate = participantsRepeater.itemAt(index)
        var participant = participantDelegate.participant
        chatEntry.removeParticipants([participant.identifier], "")
        participantDelegate.height = 0
    }

    function destroyGroup() {
        var result = chatEntry.destroyRoom()
        if (!result) {
            application.showNotificationMessage(i18n.tr("Failed to delete group"), "dialog-error-symbolic")
        } else {
            application.showNotificationMessage(i18n.tr("Group has been dissolved"), "tick")
            mainView.emptyStack()
        }
    }

    Flickable {
        id: contentsFlickable
        property var emptySpaceHeight: height - contentsColumn.topItemsHeight+contentsFlickable.contentY
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }
        contentHeight: contentsColumn.height
        clip: true

        Column {
            id: contentsColumn
            property var topItemsHeight: groupInfo.height+participantsHeader.height+searchItem.height+units.gu(1)

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            height: childrenRect.height

            Item {
                id: groupInfo
                height: visible ? groupAvatar.height + groupAvatar.anchors.topMargin + units.gu(1) : 0
                visible: chatRoom
                enabled: chatEntry.active

                anchors {
                    left: parent.left
                    right: parent.right
                }

                ContactAvatar {
                    id: groupAvatar

                    // FIXME: set to the group picture once implemented
                    //fallbackAvatarUrl:
                    fallbackDisplayName: groupName.text
                    showAvatarPicture: groupName.text.length === 0
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        top: parent.top
                        topMargin: units.gu(1)
                    }
                    height: units.gu(6)
                    width: units.gu(6)
                }

                TextField {
                    id: groupName
                    verticalAlignment: Text.AlignVCenter
                    style: TransparentTextFieldStype {}
                    text: {
                        if (chatEntry.title !== "") {
                            return chatEntry.title
                        }
                        var roomInfo = groupChatInfoPage.threads[0].chatRoomInfo
                        if (roomInfo.Title != "") {
                            return roomInfo.Title
                        } else if (roomInfo.RoomName != "") {
                            return roomInfo.RoomName
                        }
                        return ""
                    }
                    anchors {
                        left: groupAvatar.right
                        leftMargin: units.gu(1)
                        right: editIcon.left
                        rightMargin: units.gu(1)
                        verticalCenter: groupAvatar.verticalCenter
                    }
                    readOnly: !chatEntry.canUpdateConfiguration

                    InputMethod.extensions: { "enterKeyText": i18n.dtr("messaging-app", "Rename") }

                    onAccepted: {
                        chatEntry.title = groupName.text
                    }

                    Keys.onEscapePressed: {
                        groupName.text = chatEntry.title
                    }
                }
                Icon {
                    id: editIcon
                    color: Theme.palette.normal.backgroundText
                    height: units.gu(2)
                    width: units.gu(2)
                    visible: chatEntry.canUpdateConfiguration
                    enabled: chatEntry.canUpdateConfiguration
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: units.gu(2)
                    }
                    name: "edit"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: units.gu(-1)
                        onClicked: { 
                            groupName.forceActiveFocus()
                            groupName.cursorPosition = groupName.text.length
                        }
                    }
                }
            }

            ListItems.ThinDivider {
                visible: groupInfo.visible
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Item {
                id: participantsHeader
                enabled: chatEntry.active
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: units.gu(7)

                Label {
                    id: participantsLabel
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        verticalCenter: addParticipantButton.verticalCenter
                    }
                    text: !searchItem.enabled ? i18n.tr("Participants: %1").arg(allParticipants.length) : i18n.tr("Add participant:")
                }

                Button {
                    id: addParticipantButton
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        bottom: parent.bottom
                        bottomMargin: units.gu(1)
                    }

                    visible: {
                        if (!chatRoom || !chatEntry.active) {
                            return false
                        }
                        return (chatEntry.groupFlags & ChatEntry.ChannelGroupFlagCanAdd)
                    }
                    text: !searchItem.enabled ? i18n.tr("Add...") : i18n.tr("Cancel")
                    onClicked: {
                        searchItem.enabled = !searchItem.enabled
                        searchItem.text = ""
                    }
                }
            }

            ListItems.ThinDivider {
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            ContactSearchWidget {
                id: searchItem
                enabled: false
                height: enabled ? units.gu(6) : 0
                clip: true
                parentPage: groupChatInfoPage
                searchResultsHeight: contentsFlickable.emptySpaceHeight
                onContactPicked: addRecipientFromSearch(identifier, alias, avatar)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                Behavior on height {
                    UbuntuNumberAnimation {}
                }
            }

            ListItems.ThinDivider {
                visible: searchItem.enabled
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }


            ListItemActions {
                id: participantLeadingActions
                delegate: Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: contentHeight
                    width: contentWidth+units.gu(2)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n.tr("Remove")
                }
                actions: [
                    Action {
                        text: i18n.tr("Remove")
                        onTriggered: {
                            // in case account is of type Multimedia, alert if the group is going to have no active participants that the group could
                            // be dissolved by the server
                            if (chatEntry.chatType == ChatEntry.ChatTypeRoom && chatEntry.participants.length === 1 /*the active participant to remove now*/) {
                                var properties = {}
                                properties["selectedIndex"] = value
                                properties["groupName"] = groupName.text
                                PopupUtils.open(Qt.createComponent("Dialogs/EmptyGroupWarningDialog.qml").createObject(groupChatInfoPage), groupChatInfoPage, properties)
                            } else {
                                removeParticipant(value);
                            }
                        }
                    }
                ]
            }

            Repeater {
                id: participantsRepeater
                model: allParticipants

                ParticipantDelegate {
                    id: participantDelegate
                    function canRemove() {
                        if (!groupChatInfoPage.chatRoom /*not a group*/
                                || !chatEntry.active /*not active*/
                                || modelData.roles & 2 /*not admin*/
                                || modelData.state === 2 /*remote pending*/) {
                            return false
                        }
                        return (chatEntry.groupFlags & ChatEntry.ChannelGroupFlagCanRemove)
                    }
                    function removeFromGroup() {
                        leadingActions.actions[0].trigger()
                    }
                    participant: modelData
                    leadingActions: canRemove() ? participantLeadingActions : undefined
                    onClicked: {
                        if (openProfileButton.visible) {
                            mainStack.addPageToCurrentColumn(groupChatInfoPage, Qt.resolvedUrl("ParticipantInfoPage.qml"), {"delegate": participantDelegate, "chatEntry": chatEntry, "chatRoom": chatRoom})
                        }
                    }
                    Icon {
                       id: openProfileButton
                       anchors.right: parent.right
                       anchors.rightMargin: units.gu(1)
                       anchors.verticalCenter: parent.verticalCenter
                       height: units.gu(2)
                       name: "go-next"
                    }
                }
            }
            Item {
               id: padding
               height: units.gu(3)
               anchors.left: parent.left
               anchors.right: parent.right
            }
            Row {
                enabled: chatEntry.active
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                layoutDirection: Qt.RightToLeft
                spacing: units.gu(1)
                Button {
                    id: destroyButton
                    visible: chatRoom && chatEntry.active && chatEntry.selfContactRoles == 3
                    text: i18n.tr("End group")
                    color: Theme.palette.normal.negative
                    onClicked: destroyGroup()
                }
                Button {
                    id: leaveButton
                    visible: chatRoom && chatEntry.active && !(chatEntry.selfContactRoles & 2)
                    text: i18n.tr("Leave group")
                    onClicked: {
                        if (chatEntry.leaveChat()) {
                            application.showNotificationMessage(i18n.tr("Successfully left group"), "tick")
                            mainView.emptyStack()
                        } else {
                            application.showNotificationMessage(i18n.tr("Failed to leave group"), "dialog-error-symbolic")
                        }
                    }
                }
            }
        }
    }
    KeyboardRectangle {
        id: keyboard
    }
}

