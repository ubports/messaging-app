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

Page {
    id: mainPage
    tools: selectionMode ? selectionToolbar : regularToolbar
    title: i18n.tr("Messages")

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

    ListView {
        id: threadList
        anchors.fill: parent
        // We can't destroy delegates while selectionMode == true
        // looks like 320 is the default value
        cacheBuffer: selectionMode ? units.gu(10) * count : 320
        model: sortProxy
        delegate: ThreadDelegate {
            id: threadDelegate
            selectionMode: mainView.selectionMode
        }
    }

    Scrollbar {
        flickableItem: threadList
        align: Qt.AlignTrailing
    }
}
