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
            participantList.push(participant)
        }
        for (var i in localPendingParticipants) {
            var participant = localPendingParticipants[i]
            participant["state"] = 1
            participantList.push(participant)
        }
        for (var i in remotePendingParticipants) {
            var participant = remotePendingParticipants[i]
            participant["state"] = 2
            participantList.push(participant)
        }

        if (chatRoom) {
            var participant = {"alias": i18n.tr("You"), "identifier": "self", "avatar":""}
            if (chatEntry.active) {
                participant["state"] = 0
                participant["roles"] = chatEntry.selfContactRoles
                participantList.push(participant)
            } else  if (chatRoomInfo.Joined) {
                participant["state"] = 0
                participant["roles"] = chatRoomInfo.SelfRoles
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
            enabled: chatEntry.active

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
                            if (mainView.multimediaAccount !== null && chatEntry.participants.length === 1 /*the active participant to remove now*/) {
                                var properties = {}
                                properties["selectedIndex"] = value
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
                        console.log(chatEntry.selfContactRoles)
                        if (!groupChatInfoPage.chatRoom /*not a group*/
                                || !chatEntry.active /*not active*/
                                || modelData.roles & 2 /*not admin*/
                                || modelData.state === 2 /*remote pending*/) {
                            return false
                        }
                        return (chatEntry.groupFlags & ChatEntry.ChannelGroupFlagCanRemove)
                    }
                    participant: modelData
                    leadingActions: canRemove() ? participantLeadingActions : undefined
                }
            }
            Item {
               id: padding
               height: units.gu(3)
               anchors.left: parent.left
               anchors.right: parent.right
            }
            Row {
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
                    onClicked: {
                        var result = chatEntry.destroyRoom()
                        if (!result) {
                            application.showNotificationMessage(i18n.tr("Failed to delete group"), "dialog-error-symbolic")
                        } else {
                            application.showNotificationMessage(i18n.tr("Successfully removed group"), "tick")
                            mainView.emptyStack()
                        }

                        // FIXME: show a dialog in case of failure
                    }
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

