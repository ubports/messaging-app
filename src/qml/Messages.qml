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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1

Page {
    id: messages
    property string threadId: getCurrentThreadId()
    property alias number: contactWatcher.phoneNumber
    property alias selectionMode: messageList.isInSelectionMode
    flickable: null
    title:  number !== "" ? (contactWatcher.isUnknown ? messages.number : contactWatcher.alias) : i18n.tr("New Message")
    tools: selectionMode ? selectionToolbar : regularToolbar

    function getCurrentThreadId() {
        if (number === "")
            return ""
        return eventModel.threadIdForParticipants(telepathyHelper.accountId, HistoryThreadModel.EventTypeText, messages.number)
    }

    ContactWatcher {
        id: contactWatcher
    }

    onNumberChanged: {
        threadId = getCurrentThreadId()
    }

    // just and empty toolbar with back button
    ToolbarItems {
        id: regularToolbar
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
                filterValue: telepathyHelper.accountId
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

    Item {
        id: newMessage
        property alias newNumber: newPhoneNumberField.text
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        clip: true
        height: (number === "" && threadId == "") ? childrenRect.height + units.gu(1) : 0
        TextField {
            id: newPhoneNumberField
            objectName: "newPhoneNumberField"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: units.gu(1)
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
        }
    }

    MultipleSelectionListView {
        id: messageList
        clip: true
        acceptAction.text: i18n.tr("Delete")
        anchors {
            top: newMessage.bottom
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
        listDelegate: MessageDelegate {
            id: messageDelegate
            incoming: senderId != "self"
            selected: messageList.isSelected(messageDelegate)
            removable: !selectionMode
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
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                eventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
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
        ListItem.ThinDivider {
            anchors.top: parent.top
        }
        TextArea {
            id: textEntry
            clip: true
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
        }

        Button {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Attach"
            width: units.gu(17)
            color: "gray"
        }

        Button {
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.bottom: parent.bottom
            text: "Send"
            width: units.gu(17)
            enabled: textEntry.text != "" && telepathyHelper.connected && (messages.number !== "" || newMessage.newNumber !== "" )
            onClicked: {
                if (messages.number === "" && newMessage.newNumber !== "") {
                    messages.number = newMessage.newNumber
                }

                if (messages.threadId == "") {
                    messages.threadId = messages.number
                }

                chatManager.sendMessage(messages.number, textEntry.text)
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
