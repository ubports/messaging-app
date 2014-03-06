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
import QtQuick.Window 2.0
import QtContacts 5.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0


Page {
    id: messages
    objectName: "messagesPage"
    property string threadId: getCurrentThreadId()
    property string accountId: ""
    property variant participants: []
    property bool groupChat: participants.length > 1
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property bool pendingMessage: false
    flickable: null
    title: {
        if (landscape) {
            return ""
        }
        if (participants.length > 0) {
            var firstRecipient = ""
            if (contactWatcher.isUnknown) {
                firstRecipient = contactWatcher.phoneNumber
            } else {
                firstRecipient = contactWatcher.alias
            }
            if (participants.length == 1) {
                return firstRecipient
            } else {
                var numOther = participants.length-1
                return firstRecipient + " +" + i18n.tr("%1 other", "%1 others", numOther).arg(numOther)
            }
        }
        return i18n.tr("New Message")
    }
    tools: messagesToolbar
    onSelectionModeChanged: messagesToolbar.opened = false

    function getCurrentThreadId() {
        if (participants.length == 0)
            return ""
        return eventModel.threadIdForParticipants(accountId,
                                                              HistoryThreadModel.EventTypeText,
                                                              participants,
                                                              HistoryThreadModel.MatchPhoneNumber)
    }

    function markMessageAsRead(accountId, threadId, eventId, type) {
        return eventModel.markEventAsRead(accountId, threadId, eventId, type);
    }

    Component {
        id: participantsPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                Repeater {
                    model: participants
                    Item {
                        height: childrenRect.height
                        width: popover.width
                        ListItem.Standard { 
                            id: listItem
                            text: contactWatcher.isUnknown ? contactWatcher.phoneNumber : contactWatcher.alias
                        }
                        ContactWatcher {
                            id: contactWatcher
                            phoneNumber: modelData
                        }
                    }
                }
            }
        }
    }

    Item {
        id: headerContent
        visible: groupChat
        anchors.fill: parent

        Label {
            text: messages.title
            fontSize: "x-large"
            font.weight: Font.Light
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            anchors {
                left: parent.left
                leftMargin: units.gu(1)
                top: parent.top
                bottom: parent.bottom
                right: participantsButton.left
            }
        }

        Icon {
            id: participantsButton
            name: "navigation-menu"
            width: visible ? units.gu(6) : 0
            height: units.gu(6)
            visible: groupChat
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PopupUtils.open(participantsPopover, participantsButton)
            }
        }
    }

    Binding {
        target: messages.header
        property: "contents"
        value: groupChat ? headerContent : null
        when: messages.header && !landscape && messages.active
    }


    Component {
         id: newContactDialog
         Dialog {
             id: dialogue
             title: i18n.tr("Save contact")
             text: i18n.tr("How do you want to save the contact?")
             Button {
                 text: i18n.tr("Add to existing contact")
                 color: UbuntuColors.orange
                 onClicked: {
                     PopupUtils.open(addPhoneNumberToContactSheet)
                     PopupUtils.close(dialogue)
                 }
             }
             Button {
                 text: i18n.tr("Create new contact")
                 color: UbuntuColors.orange
                 onClicked: {
                     Qt.openUrlExternally("addressbook:///create?phone=" + encodeURIComponent(contactWatcher.phoneNumber));
                     PopupUtils.close(dialogue)
                 }
             }
             Button {
                 text: i18n.tr("Cancel")
                 color: UbuntuColors.warmGrey
                 onClicked: {
                     PopupUtils.close(dialogue)
                 }
             }
         }
    }

    ContactWatcher {
        id: contactWatcher
        phoneNumber: participants.length > 0 ? participants[0] : ""
    }

    onParticipantsChanged: {
        threadId = getCurrentThreadId()
    }

    Component {
        id: addPhoneNumberToContactSheet
        DefaultSheet {
            // FIXME: workaround to set the contact list
            // background to black
            Rectangle {
                anchors.fill: parent
                anchors.margins: -units.gu(1)
                color: "#221e1c"
            }
            id: sheet
            title: "Add Contact"
            doneButton: false
            modal: true
            contentsHeight: parent.height
            contentsWidth: parent.width
            ContactListView {
                anchors.fill: parent
                onContactClicked: {
                    Qt.openUrlExternally("addressbook:///addphone?id=" + encodeURIComponent(contact.contactId) +
                                                                "&phone=" + encodeURIComponent(contactWatcher.phoneNumber))
                    PopupUtils.close(sheet)
                }
            }
            onDoneClicked: PopupUtils.close(sheet)
        }
    }

    Component {
        id: addContactToConversationSheet
        DefaultSheet {
            // FIXME: workaround to set the contact list
            // background to black
            Rectangle {
                anchors.fill: parent
                anchors.margins: -units.gu(1)
                color: "#221e1c"
            }
            id: sheet
            title: "Add Contact"
            doneButton: false
            modal: true
            contentsHeight: parent.height
            contentsWidth: parent.width
            ContactListView {
                anchors.fill: parent
                detailToPick: ContactDetail.PhoneNumber
                onContactClicked: {
                    // FIXME: search for favorite number
                    multiRecipient.addRecipient(contact.phoneNumber.number)
                    multiRecipient.forceActiveFocus()
                    PopupUtils.close(sheet)
                }
                onDetailClicked: {
                    multiRecipient.addRecipient(detail.number)
                    PopupUtils.close(sheet)
                    multiRecipient.forceActiveFocus()
                }
            }
            onDoneClicked: PopupUtils.close(sheet)
        }
    }

    ToolbarItems {
        id: messagesToolbar
        ToolbarButton {
            objectName: "selectMessagesButton"
            visible: messageList.count !== 0
            action: Action {
                iconSource: "image://theme/select"
                text: i18n.tr("Select")
                onTriggered: messageList.startSelection()
            }
        }
        ToolbarButton {
            visible: contactWatcher.isUnknown && participants.length == 1
            objectName: "addContactButton"
            action: Action {
                iconSource: "image://theme/new-contact"
                text: i18n.tr("Add")
                onTriggered: {
                    PopupUtils.open(newContactDialog)
                    messagesToolbar.opened = false
                }
            }
        }
        ToolbarButton {
            visible: !contactWatcher.isUnknown && participants.length == 1
            objectName: "contactProfileButton"
            action: Action {
                iconSource: "image://theme/contact"
                text: i18n.tr("Contact")
                onTriggered: {
                    Qt.openUrlExternally("addressbook:///contact?id=" + encodeURIComponent(contactWatcher.contactId))
                    messagesToolbar.opened = false
                }
            }
        }
        ToolbarButton {
            visible: participants.length == 1
            objectName: "contactCallButton"
            action: Action {
                iconSource: "image://theme/call-start"
                text: i18n.tr("Call")
                onTriggered: {
                    Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.phoneNumber))
                    messagesToolbar.opened = false
                }
            }
        }
        locked: selectionMode
    }

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: HistoryIntersectionFilter {
            HistoryFilter {
                filterProperty: "threadId"
                filterValue: threadId
            }
            HistoryFilter {
                filterProperty: "accountId"
                filterValue: accountId
            }
        }
        sort: HistorySort {
           sortField: "timestamp"
           sortOrder: HistorySort.DescendingOrder
        }
    }

    SortProxyModel {
        id: sortProxy
        sourceModel: eventModel
        sortRole: HistoryEventModel.TimestampRole
        ascending: false
    }

    Icon {
        id: addIcon
        visible: multiRecipient.visible
        height: units.gu(3)
        width: units.gu(3)
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            top: parent.top
            topMargin: units.gu(1)
        }

        name: "new-contact"
        color: "white"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                var item = keyboard.recursiveFindFocusedItem(messages)
                if (item) {
                    item.focus = false
                }

                PopupUtils.open(addContactToConversationSheet)
            }
        }
    }

    MultiRecipientInput {
        id: multiRecipient
        objectName: "multiRecipient"
        visible: participants.length == 0
        enabled: visible
        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            right: addIcon.left
        }
    }

    MultipleSelectionListView {
        id: messageList
        clip: true
        acceptAction.text: i18n.tr("Delete")
        anchors {
            top: multiRecipient.bottom
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        // TODO: workaround to add some extra space at the bottom and top
        header: Item {
            height: units.gu(2)
        }
        footer: Item {
            height: units.gu(2)
        }
        listModel: threadId !== "" ? sortProxy : null
        verticalLayoutDirection: ListView.BottomToTop
        spacing: units.gu(2)
        highlightFollowsCurrentItem: false
        listDelegate: MessageDelegate {
            id: messageDelegate
            incoming: senderId != "self"
            selected: messageList.isSelected(messageDelegate)
            removable: !messages.selectionMode
            selectionMode: messages.selectionMode
            confirmRemoval: true
            onClicked: {
                if (messageList.isInSelectionMode) {
                    if (!messageList.selectItem(messageDelegate)) {
                        messageList.deselectItem(messageDelegate)
                    }
                }
            }
            onPressAndHold: {
                messageList.startSelection()
                messageList.selectItem(messageDelegate)
            }

            Component.onCompleted: {
                if (newEvent) {
                    messages.markMessageAsRead(accountId, threadId, eventId, type);
                }
            }
            onResend: {
                // resend this message and remove the old one
                eventModel.removeEvent(accountId, threadId, eventId, type)
                chatManager.sendMessage(messages.participants, textMessage)
            }
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                eventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
            }
        }
        onCountChanged: {
            if (messages.pendingMessage) {
                messageList.contentY = 0
                messages.pendingMessage = false
            } 
        }
    }

    Item {
        id: bottomPanel
        anchors.bottom: keyboard.top
        anchors.bottomMargin: selectionMode ? 0 : units.gu(2)
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + attachButton.height + units.gu(4)
        visible: !selectionMode
        clip: true

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        ListItem.ThinDivider {
            anchors.top: parent.top
        }
        TextArea {
            id: textEntry
            anchors.bottomMargin: units.gu(2)
            anchors.bottom: attachButton.top
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            height: units.gu(5)
            autoSize: true
            placeholderText: i18n.tr("Write a message...")
            focus: false
            font.family: "Ubuntu"

            InverseMouseArea {
                anchors.fill: parent
                visible: textEntry.activeFocus
                onClicked: {
                    textEntry.focus = false;
                }
            }
        }

        Button {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Attach"
            width: units.gu(17)
            color: "gray"
            visible: false
        }

        Button {
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Send"
            width: units.gu(17)
            enabled: textEntry.text != "" && telepathyHelper.connected && (participants.length > 0 || multiRecipient.recipientCount > 0 )
            onClicked: {
                if (participants.length == 0 && multiRecipient.recipientCount > 0) {
                    participants = multiRecipient.recipients
                }

                if (messages.accountId == "") {
                    // FIXME: handle dual sim
                    console.log(messages.accountId)
                    messages.accountId = telepathyHelper.accountIds[0]
                    console.log(messages.accountId)
                }

                if (messages.threadId == "") {
                    // create the new thread and get the threadId
                    messages.threadId = eventModel.threadIdForParticipants(messages.accountId,
                                                                            HistoryThreadModel.EventTypeText,
                                                                            participants,
                                                                            HistoryThreadModel.MatchPhoneNumber,
                                                                            true)
                }
                messages.pendingMessage = true
                chatManager.sendMessage(participants, textEntry.text)
                textEntry.text = ""
            }
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    Scrollbar {
        flickableItem: messageList
        align: Qt.AlignTrailing
    }
}
