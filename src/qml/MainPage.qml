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
import Ubuntu.Contacts 0.1

Page {
    id: mainPage
    tools: threadList.isInSelectionMode ? selectionToolbar : regularToolbar
    title: i18n.tr("Messages")

    function startSelection() {
        threadList.startSelection()
    }

    HistoryThreadModel {
        id: threadModel
        type: HistoryThreadModel.EventTypeText
        filter: HistoryFilter {
            filterProperty: "accountId"
            filterValue: telepathyHelper.accountId
        }
        sort: HistorySort {
            sortField: "lastEventTimestamp"
            sortOrder: HistorySort.DescendingOrder
        }
    }

    SortProxyModel {
        id: sortProxy
        sortRole: HistoryThreadModel.LastEventTimestampRole
        sourceModel: threadModel
        ascending: false
    }

    MultipleSelectionListView {
        id: threadList
        anchors.fill: parent
        listModel: sortProxy
        acceptAction.text: i18n.tr("Delete")
        listDelegate: ThreadDelegate {
            id: threadDelegate
            selectionMode: threadList.isInSelectionMode
            selected: threadList.isSelected(threadDelegate)
            removable: !selectionMode
            onClicked: {
                if (threadList.isInSelectionMode) {
                    if (!threadList.selectItem(threadDelegate)) {
                        threadList.deselectItem(threadDelegate)
                    }
                } else {
                    var properties = {}
                    properties["threadId"] = threadId
                    properties["number"] = participants[0]
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
