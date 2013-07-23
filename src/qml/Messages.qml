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
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1

Page {
    id: messages
    property string threadId: ""
    property string number
    property bool selectionMode: false
    property int selectionCount: 0
    flickable: null
    title:  threadId != "" ? messages.number : i18n.tr("New Message")
    tools: selectionMode ? selectionToolbar : regularToolbar

    onSelectionCountChanged: {
        if (selectionCount == 0) {
            selectionMode = false
        }
    }

    // just and empty toolbar with back button
    ToolbarItems {
        id: regularToolbar
    }

    ToolbarItems {
        id: selectionToolbar
        visible: selectionMode
        back: Button {
            text: i18n.tr("Cancel")
            anchors.verticalCenter: parent.verticalCenter
            onClicked: selectionMode = false
        }

        Button {
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Delete")
        }
        locked: true
        opened: true
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
    }

    SortProxyModel {
        id: sortProxy
        model: eventModel
        sortRole: HistoryEventModel.TimestampRole
        ascending: false
    }

    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        id: newMessage
        clip: true
        height: threadId == "" ? childrenRect.height + units.gu(1) : 0
        TextField {
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

    ListView {
        id: messageList
        clip: true
        anchors {
            top: newMessage.bottom
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        model: threadId != "" ? sortProxy : null
        verticalLayoutDirection: ListView.BottomToTop
        cacheBuffer: selectionMode ? units.gu(10) * count : 320
        delegate: MessageDelegate {
            message: textMessage
            incoming: senderId != "self"
            timestamp: timestamp

            Connections {
                target: messages
                onSelectionModeChanged: {
                    if (!selectionMode) {
                        selected = false
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (selectionMode) {
                        selected = !selected
                        if (selected) {
                            selectionCount = selectionCount + 1
                        } else {
                            selectionCount = selectionCount - 1
                        }
                    }
                }
                onPressAndHold: {
                    selectionMode = true
                    selected = true
                    selectionCount = 1
                }
            }
        }
    }

    Item {
        id: bottomPanel
        anchors.bottom: keyboard.top
        anchors.bottomMargin: units.gu(1)
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + attachButton.height + units.gu(1)
        visible: !selectionMode
        clip: true

        TextArea {
            id: textEntry
            clip: true
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: attachButton.top
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1)
            height: units.gu(5)
            autoSize: true
            placeholderText: i18n.tr("Write a message...")
            focus: false
        }

        Button {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.bottom: parent.bottom
            text: "Attach"
            width: units.gu(15)
        }

        Button {
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1)
            anchors.bottom: parent.bottom
            text: "Send"
            width: units.gu(15)
            enabled: textEntry.text != "" && telepathyHelper.connected
            onClicked: {
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
