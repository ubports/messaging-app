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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.History 0.1
import Ubuntu.Contacts 0.1
import "dateUtils.js" as DateUtils

Page {
    id: mainPage
    tools: threadList.isInSelectionMode ? selectionToolbar : regularToolbar
    title: i18n.tr("Messages")

    property alias threadCount: threadList.count

    function startSelection() {
        threadList.startSelection()
    }

    ToolbarItems {
        id: regularToolbar
        ToolbarButton {
            visible: mainStack.currentPage.threadCount !== 0
            objectName: "selectButton"
            text: i18n.tr("Select")
            iconSource: "image://theme/select"
            onTriggered: mainStack.currentPage.startSelection()
        }

        ToolbarButton {
            objectName: "newMessageButton"
            action: Action {
                iconSource: "image://theme/compose"
                text: i18n.tr("Compose")
                onTriggered: mainView.startNewMessage()
            }
        }
    }

    ToolbarItems {
        id: selectionToolbar
        locked: true
        opened: false
    }

    SortProxyModel {
        id: sortProxy
        sortRole: HistoryThreadModel.LastEventTimestampRole
        sourceModel: threadModel
        ascending: false
    }

    HistoryThreadModel {
        id: threadModel
        type: HistoryThreadModel.EventTypeText
        sort: HistorySort {
            sortField: "lastEventTimestamp"
            sortOrder: HistorySort.DescendingOrder
        }
    }

    MultipleSelectionListView {
        id: threadList
        objectName: "threadList"
        anchors.fill: parent
        listModel: sortProxy
        acceptAction.text: i18n.tr("Delete")
        section.property: "eventDate"
        section.delegate: Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(5)
            Label {
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                fontSize: "medium"
                elide: Text.ElideRight
                color: "gray"
                opacity: 0.6
                text: DateUtils.friendlyDay(Qt.formatDate(section, "yyyy/MM/dd"));
                verticalAlignment: Text.AlignVCenter
            }
            ListItem.ThinDivider {
                anchors.bottom: parent.bottom
            }
        }

        listDelegate: ThreadDelegate {
            id: threadDelegate
            objectName: "thread%1".arg(participants)
            selectionMode: threadList.isInSelectionMode
            selected: threadList.isSelected(threadDelegate)
            removable: !selectionMode
            confirmRemoval: true
            onClicked: {
                if (threadList.isInSelectionMode) {
                    if (!threadList.selectItem(threadDelegate)) {
                        threadList.deselectItem(threadDelegate)
                    }
                } else {
                    var properties = {}
                    properties["threadId"] = threadId
                    properties["accountId"] = accountId
                    properties["participants"] = participants
                    mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
                }
            }
            onPressAndHold: {
                threadList.startSelection()
                threadList.selectItem(threadDelegate)
            }
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var thread = items.get(i).model
                threadModel.removeThread(thread.accountId, thread.threadId, thread.type)
            }
        }

    }

    Scrollbar {
        flickableItem: threadList
        align: Qt.AlignTrailing
    }
}
