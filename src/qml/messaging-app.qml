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
import Ubuntu.Components.Popups 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1

MainView {
    id: mainView

    automaticOrientation: true
    width: units.gu(40)
    height: units.gu(71)
    property bool selectionMode: false
    property int selectionCount: 0
    onSelectionCountChanged: {
        if (selectionCount == 0) {
            selectionMode = false
        }
    }

    signal applicationReady

    function startNewMessage() {
        var properties = {}
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    Component {
        id: newcontactPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard { text: i18n.tr("Add to existing contact") }
                ListItem.Standard { text: i18n.tr("Create new contact") }
            }
        }
    }

    Component {
        id: threadDelegate
        Item {
            property bool selected: false
            property bool unknownContact: contactWatcher.contactId == ""
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(10)


            ContactWatcher {
                id: contactWatcher
                phoneNumber: participants[0]
            }

            Connections {
                target: mainView
                onSelectionModeChanged: {
                    if (!selectionMode) {
                        selected = false
                    }
                }
            }

            // FIXME: temporary solution to display selected threads
            Rectangle {
                anchors.fill: parent
                height: units.gu(2)
                width: units.gu(2)
                color: "gray"
                opacity: 0.3
                visible: selected
            }

            UbuntuShape {
                id: avatar
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: units.gu(1)
                image: Image {
                    source: {
                        if(!unknownContact) {
                            if (contactWatcher.avatar != "") {
                                return contactWatcher.avatar
                            }
                        }
                        return Qt.resolvedUrl("assets/avatar-default.png")
                    }
                }
                MouseArea {
                    anchors.fill: avatar
                    onClicked: PopupUtils.open(newcontactPopover, avatar)
                    enabled: unknownContact
                }
            }

            Label {
                id: contactName
                anchors.top: avatar.top
                anchors.left: avatar.right
                anchors.leftMargin: units.gu(1)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1)
                fontSize: "large"
                text: unknownContact ? contactWatcher.phoneNumber : contactWatcher.alias
            }

            Label {
                id: message
                anchors.top: contactName.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: avatar.right
                anchors.leftMargin: units.gu(1)
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1)
                elide: Text.ElideRight
                fontSize: "medium"
                text: eventTextMessage == undefined ? "" : eventTextMessage
            }

            Image {
                anchors.bottom: parent.bottom
                source: Qt.resolvedUrl("assets/horizontal_divider.png")
            }

            MouseArea {
                anchors {
                    left: avatar.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }

                onClicked: {
                    if (mainView.selectionMode) {
                        selected = !selected
                        if (selected) {
                            selectionCount = selectionCount + 1
                        } else {
                            selectionCount = selectionCount - 1
                        }
                    } else {
                        var properties = {}
                        properties["threadId"] = threadId
                        properties["number"] = participants[0]
                        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
                    }
                }
                onPressAndHold: {
                    mainView.selectionMode = true
                    selected = true
                    selectionCount = 1
                }
            }
        }
    }

    ToolbarItems {
        id: regularToolbar
        ToolbarButton {
            action: Action {
                iconSource: Qt.resolvedUrl("assets/compose.png")
                text: i18n.tr("Compose")
                onTriggered: mainView.startNewMessage()
            }
        }
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

    PageStack {
        id: mainStack
        anchors.fill: parent
        Component.onCompleted: push(page0)
        Page {
            id: page0
            tools: selectionMode ? selectionToolbar : regularToolbar

            title: i18n.tr("Messages")
            ListView {
                id: threadList
                anchors.fill: parent
                // We can't destroy delegates while selectionMode == true
                // looks like 320 is the default value
                cacheBuffer: selectionMode ? units.gu(10) * count : 320
                model: HistoryThreadModel {
                    type: HistoryThreadModel.EventTypeText
                    filter: HistoryFilter {
                        filterProperty: "accountId"
                        filterValue: telepathyHelper.accountId
                    }
                }
                delegate: threadDelegate
            }

            Scrollbar {
                flickableItem: threadList
                align: Qt.AlignTrailing
            }
        }
    }
}
