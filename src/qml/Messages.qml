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
    property string threadId: ""
    property bool newMessage: threadId === ""
    // FIXME: we should get the account ID properly when dealing with multiple accounts
    property string accountId: telepathyHelper.accountIds[0]
    property variant participants: []
    property bool groupChat: participants.length > 1
    property bool keyboardFocus: true
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property bool pendingMessage: false
    flickable: null
    // we need to use isReady here to know if this is a bottom edge page or not.
    __customHeaderContents: newMessage && isReady ? newMessageHeader : null
    property bool isReady: false
    signal ready
    onReady: {
        isReady = true
        if (participants.length === 0 && keyboardFocus)
            multiRecipient.forceFocus()
    }

    title: {
        if (selectionMode) {
            return i18n.tr("Edit")
        }

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
                return i18n.tr("Group")
            }
        }
        return i18n.tr("New Message")
    }
    tools: {
        if (selectionMode) {
            return messagesToolbarSelectionMode
        }

        if (participants.length == 0) {
            return null
        } else if (participants.length == 1) {
            if (contactWatcher.isUnknown) {
                return messagesToolbarUnknownContact
            } else {
                return messagesToolbarKnownContact
            }
        } else if (groupChat){
            return messagesToolbarGroupChat
        }
    }

    Component.onCompleted: {
        threadId = getCurrentThreadId()
    }

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
                     PopupUtils.close(dialogue)
                     Qt.inputMethod.hide()
                     mainStack.push(Qt.resolvedUrl("AddPhoneNumberToContactPage.qml"), {"phoneNumber": contactWatcher.phoneNumber})
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

    Item {
        id: newMessageHeader
        anchors {
            left: parent.left
            rightMargin: units.gu(1)
            right: parent.right
            bottom: parent.bottom
            top: parent.top
        }
        visible: participants.length == 0 && isReady && messages.active
        MultiRecipientInput {
            id: multiRecipient
            objectName: "multiRecipient"
            enabled: visible
            width: childrenRect.width
            anchors {
                left: parent.left
                right: addIcon.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
        }
        Icon {
            id: addIcon
            visible: multiRecipient.visible
            height: units.gu(3)
            width: units.gu(3)
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            name: "new-contact"
            color: "gray"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.inputMethod.hide()
                    mainStack.push(Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": multiRecipient})
                }
            }
        }
    }

    ContactListView {
        id: contactSearch
        /*Item {
            id: root
            property string manager: "galera"
        }*/
        property bool searchEnabled: multiRecipient.searchString !== "" && multiRecipient.focus
        visible: searchEnabled
        detailToPick: ContactDetail.PhoneNumber
        property string searchTerm: {
            if(multiRecipient.searchString !== "" && multiRecipient.focus) {
                return multiRecipient.searchString
            }
            return "some value that won't match"
        }
        listModel: ContactModel {
            manager: contactSearch.manager
            sortOrders: contactSearch.sortOrders
            fetchHint: contactSearch.fetchHint
            filter: UnionFilter {
                DetailFilter {
                    detail: ContactDetail.DisplayLabel
                    field: DisplayLabel.Label
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchContains
                }
                DetailFilter {
                    detail: ContactDetail.PhoneNumber
                    field: PhoneNumber.Number
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchPhoneNumber
                }

                DetailFilter {
                    detail: ContactDetail.PhoneNumber
                    field: PhoneNumber.Number
                    value: contactSearch.searchTerm
                    matchFlags: DetailFilter.MatchContains
                }
            }
        }
        clip: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        states: [
            State {
                name: "empty"
                when: contactSearch.count === 0
                PropertyChanges {
                    target: contactSearch
                    height: 0
                }
            }
        ]

        Behavior on height {
            UbuntuNumberAnimation { }
        }
        onDetailClicked: {
            if (action === "message" || action === "") {
                multiRecipient.addRecipient(detail.number)
                multiRecipient.clearSearch()
                multiRecipient.forceActiveFocus()
            } else if (action === "call") {
                Qt.inputMethod.hide()
                Qt.openUrlExternally("tel:///" + encodeURIComponent(detail.number))
            }
        }
        z: 1
    }

    ContactWatcher {
        id: contactWatcher
        phoneNumber: participants.length > 0 ? participants[0] : ""
    }

    onParticipantsChanged: {
        threadId = getCurrentThreadId()
    }

    ToolbarItems {
        id: messagesToolbarSelectionMode
        visible: false
        back: ToolbarButton {
            id: selectionModeCancelButton
            objectName: "selectionModeCancelButton"
            action: Action {
                iconSource: "image://theme/close"
                onTriggered: messageList.cancelSelection()
            }
        }
        ToolbarButton {
            id: selectionModeSelectAllButton
            objectName: "selectionModeSelectAllButton"
            action: Action {
                iconSource: "image://theme/filter"
                onTriggered: messageList.selectAll()
            }
        }
        ToolbarButton {
            id: selectionModeDeleteButton
            objectName: "selectionModeDeleteButton"
            action: Action {
                enabled: messageList.selectedItems.count > 0
                iconSource: "image://theme/delete"
                onTriggered: messageList.endSelection()
            }
        }
    }

    ToolbarItems {
        id: messagesToolbarGroupChat
        visible: false
        ToolbarButton {
            id: groupChatButton
            objectName: "groupChatButton"
            action: Action {
                iconSource: "image://theme/navigation-menu"
                onTriggered: {
                    PopupUtils.open(participantsPopover, messages.header)
                }
            }
        }
    }

    ToolbarItems {
        id: messagesToolbarUnknownContact
        visible: false
        ToolbarButton {
            objectName: "contactCallButton"
            action: Action {
                visible: participants.length == 1
                iconSource: "image://theme/call-start"
                text: i18n.tr("Call")
                onTriggered: {
                    Qt.inputMethod.hide()
                    Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.phoneNumber))
                }
            }
        }
        ToolbarButton {
            objectName: "addContactButton"
            action: Action {
                visible: contactWatcher.isUnknown && participants.length == 1
                iconSource: "image://theme/new-contact"
                text: i18n.tr("Add")
                onTriggered: {
                    Qt.inputMethod.hide()
                    PopupUtils.open(newContactDialog)
                }
            }
        }
    }

    ToolbarItems {
        id: messagesToolbarKnownContact
        visible: false
        ToolbarButton {
            objectName: "contactCallButton"
            action: Action {
                visible: participants.length == 1
                iconSource: "image://theme/call-start"
                text: i18n.tr("Call")
                onTriggered: {
                    Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.phoneNumber))
                }
            }
        }
        ToolbarButton {
            objectName: "contactProfileButton"
            action: Action {
                visible: !contactWatcher.isUnknown && participants.length == 1
                iconSource: "image://theme/contact"
                text: i18n.tr("Contact")
                onTriggered: {
                    Qt.openUrlExternally("addressbook:///contact?id=" + encodeURIComponent(contactWatcher.contactId))
                }
            }
        }
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

    MultipleSelectionListView {
        id: messageList
        objectName: "messageList"
        clip: true
        anchors {
            top: parent.top
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
        listModel: !newMessage ? sortProxy : null
        verticalLayoutDirection: ListView.BottomToTop
        spacing: units.gu(2)
        highlightFollowsCurrentItem: false
        listDelegate: MessageDelegate {
            id: messageDelegate
            objectName: "message%1".arg(index)
            incoming: senderId != "self"
            selected: messageList.isSelected(messageDelegate)
            unread: newEvent
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
            onTriggerSelectionMode: {
                messageList.startSelection()
                clicked()
            }

            Component.onCompleted: {
                if (newEvent) {
                    messages.markMessageAsRead(accountId, threadId, eventId, type);
                }
            }
            onResend: {
                // resend this message and remove the old one
                eventModel.removeEvent(accountId, threadId, eventId, type)
                chatManager.sendMessage(messages.participants, textMessage, accountId)
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
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + units.gu(2)
        visible: !selectionMode
        clip: true

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        ListItem.ThinDivider {
            anchors.top: parent.top
        }

        Icon {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.verticalCenter: sendButton.verticalCenter
            height: units.gu(3)
            width: units.gu(3)
            color: "gray"
            name: "camera"
        }

        TextArea {
            id: textEntry
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: parent.bottom
            anchors.left: attachButton.right
            anchors.leftMargin: units.gu(1)
            anchors.right: sendButton.left
            anchors.rightMargin: units.gu(1)
            height: units.gu(4)
            autoSize: true
            maximumLineCount: 0
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
            Component.onCompleted: {
                // if page is active, it means this is not a bottom edge page
                if (messages.active && messages.keyboardFocus && participants.length != 0) {
                    textEntry.forceActiveFocus()
                }
            }
        }

        Button {
            id: sendButton
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            text: "Send"
            color: "green"
            width: units.gu(7)
            enabled: (textEntry.text != "" || textEntry.inputMethodComposing) && telepathyHelper.connected && (participants.length > 0 || multiRecipient.recipientCount > 0 )
            onClicked: {
                // make sure we flush everything we have prepared in the OSK preedit
                Qt.inputMethod.commit();
                if (textEntry.text == "") {
                    return
                }
                if (participants.length == 0 && multiRecipient.recipientCount > 0) {
                    participants = multiRecipient.recipients
                }
                if (messages.accountId == "") {
                    // FIXME: handle dual sim
                    messages.accountId = telepathyHelper.accountIds[0]
                }
                if (messages.newMessage) {
                    // create the new thread and get the threadId
                    messages.threadId = eventModel.threadIdForParticipants(messages.accountId,
                                                                            HistoryThreadModel.EventTypeText,
                                                                            participants,
                                                                            HistoryThreadModel.MatchPhoneNumber,
                                                                            true)
                }
                messages.pendingMessage = true
                chatManager.sendMessage(participants, textEntry.text, messages.accountId)
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
