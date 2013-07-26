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
        delegate: threadDelegate
    }

    Scrollbar {
        flickableItem: threadList
        align: Qt.AlignTrailing
    }
}
