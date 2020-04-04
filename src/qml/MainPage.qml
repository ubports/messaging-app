/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import "dateUtils.js" as DateUtils

Page {
    id: mainPage
    property alias selectionMode: threadList.isInSelectionMode
    property bool searching: false
    property bool isEmpty: threadCount == 0 && !threadModel.canFetchMore
    property alias threadCount: threadList.count
    property alias displayedThreadIndex: threadList.currentIndex
    property bool _keepFocus: true

    function startSelection() {
        threadList.startSelection()
    }

    function selectMessage(index) {
        if (index !== -1)
            _keepFocus = false
        threadList.currentIndex = index
    }

    signal newThreadCreated(var newThread)

    TextField {
        id: searchField
        objectName: "searchField"
        visible: mainPage.searching
        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            right: parent.right
            rightMargin: units.gu(2)
        }
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Search...")
        onActiveFocusChanged: {
            if (!activeFocus) {
                searchField.text = ""
                mainPage.searching = false
            }
        }
    }

    flickable: pageHeader.flickable
    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        title: i18n.tr("Messages")
        flickable: dualPanel ? null : threadList
        leadingActionBar {
            id: leadingBar
        }

        trailingActionBar {
            id: trailingBar
        }
    }

    states: [
        State {
            id: defaultState
            name: "default"
            when: !searching && !selectionMode

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "searchAction"
                    iconName: "search"
                    text: i18n.tr("Search")
                    shortcut: "Ctrl+F"
                    enabled: mainPage.state == "default"
                    onTriggered: {
                        mainPage.searching = true
                        searchField.forceActiveFocus()
                    }
                },
                Action {
                    objectName: "settingsAction"
                    text: i18n.tr("Settings")
                    iconName: "settings"
                    onTriggered: {
                        threadList.currentIndex = -1
                        pageStack.addPageToNextColumn(mainPage, Qt.resolvedUrl("SettingsPage.qml"))
                    }
                },
                Action {
                    objectName: "newMessageAction"
                    text: i18n.tr("New message")
                    iconName: "add"
                    shortcut: "Ctrl+N"
                    enabled: mainPage.state == "default"
                    onTriggered: {
                        threadList.currentIndex = -1
                        mainView.startNewMessage()
                    }
                }
            ]

            PropertyChanges {
                target: pageHeader
                trailingActions: defaultState.trailingActions
                leadingActions: []
            }
        },
        State {
            id: searchState
            name: "search"
            when: searching

            property list<QtObject> leadingActions: [
                Action {
                    objectName: "cancelSearch"
                    visible: mainPage.searching
                    iconName: "back"
                    text: i18n.tr("Cancel")
                    shortcut: "Esc"
                    enabled: mainPage.state == "search"
                    onTriggered: {
                        searchField.text = ""
                        mainPage.searching = false
                    }
                }
            ]

            PropertyChanges {
                target: pageHeader
                contents: searchField
                leadingActions: searchState.leadingActions
                trailingActions: []
            }
        },
        State {
            id: selectionState
            name: "selection"
            when: selectionMode

            property list<QtObject> leadingActions: [
                Action {
                    objectName: "selectionModeCancelAction"
                    iconName: "back"
                    shortcut: "Esc"
                    onTriggered: threadList.cancelSelection()
                    enabled: mainPage.state == "selection"
                }
            ]

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "selectionModeSelectAllAction"
                    iconName: "select"
                    onTriggered: {
                        if (threadList.selectedItems.count === threadList.count) {
                            threadList.clearSelection()
                        } else {
                            threadList.selectAll()
                        }
                    }
                },
                Action {
                    objectName: "selectionModeDeleteAction"
                    enabled: threadList.selectedItems.count > 0
                    iconName: "delete"
                    onTriggered: threadList.endSelection()
                }
            ]
            PropertyChanges {
                target: pageHeader
                title: i18n.tr("Select")
                leadingActions: selectionState.leadingActions
                trailingActions: selectionState.trailingActions
            }
        }
    ]

    EmptyState {
        id: emptyStateScreen
        visible: mainPage.isEmpty && !mainView.dualPanel
    }

    Component {
        id: sectionDelegate
        ThreadsSectionDelegate {
            function formatSectionTitle(title) {
                if (mainView.sortThreadsBy === "timestamp")
                    return DateUtils.friendlyDay(Qt.formatDate(section, "yyyy/MM/dd"), i18n);
                else if (telepathyHelper.ready) {
                    var account = telepathyHelper.accountForId(title)
                    if (account.connectionStatus == AccountEntry.ConnectionStatusConnecting) {
                        return i18n.tr("%1 - Connecting...").arg(account.displayName)
                    } else {
                        return account.displayName
                    }
                }
                else
                    return title
            }
        }
    }

     NumberAnimation {
            id:threadMoveAnim
            running: threadList.currentIndex == 0
            target: threadList.currentItem;
            properties: "opacity";
            duration: 500
            easing.type: Easing.InOutQuad;
            from: 0; to:1
        }

    MultipleSelectionListView {
        id: threadList
        objectName: "threadList"

        anchors {
            top: parent.top
            topMargin: mainView.dualPanel ? pageHeader.height : 0
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }
        listModel: threadModel
        // (rmescandon): Prevent having selected items in the list while BottomEdge is been revealed
        // but not completely revealed.
        enabled: bottomEdgeLoader.item.status !== BottomEdge.Revealed
        clip: true
        currentIndex: -1
        //spacing: searchField.text === "" ? units.gu(-2) : 0
        section.property: mainView.sortThreadsBy === "title" ? "accountId" : "eventDate"
        section.delegate: searching && searchField.text !== ""  ? null : sectionDelegate
        header: ListItem.Standard {
            // FIXME: update
            id: newItem
            height: mainView.dualPanel && mainView.composingNewMessage ? units.gu(8) : 0
            text: i18n.tr("New message")
            iconName: "message-new"
            iconFrame: false
            selected: true
        }

        onCurrentItemChanged: {
            if (pageStack.columns > 1) {
                currentItem.show()
                if (mainPage._keepFocus)
                    // Keep focus on current page
                    threadList.forceActiveFocus()
                else if (pageStack.activePage)
                    pageStack.activePage.forceActiveFocus()
                mainPage._keepFocus = true
            }
        }


        listDelegate: ThreadDelegate {
            id: threadDelegate

            function show()
            {
                var properties = {}
                properties["accountId"] = model.properties.accountId
                properties["keyboardFocus"] = false
                properties["threads"] = model.threads
                properties["presenceRequest"] = threadDelegate.presenceItem
                if (displayedEvent != null) {
                    properties["scrollToEventId"] = displayedEvent.eventId
                }
                properties["chatEntry"] = chatEntry
                mainView.showMessagesView(properties)
            }

            // FIXME: find a better unique name
            objectName: "thread%1".arg(participants.length > 0 ? participants[0].identifier : "")
            Component.onCompleted: mainPage.newThreadCreated(model)

            anchors {
                left: parent.left
                right: parent.right
            }
            compactView: mainView.compactView
            selectionMode: threadList.isInSelectionMode
            selected: {
                if (selectionMode) {
                    return threadList.isSelected(threadDelegate)
                }
                return false
            }

            searchTerm: mainPage.searching ? searchField.text : ""

            onItemClicked: {
                if (threadList.isInSelectionMode) {
                    if (!threadList.selectItem(threadDelegate)) {
                        threadList.deselectItem(threadDelegate)
                    }
                }else {
                    if (pageStack.columns <= 1) {
                        show()
                    }
                }

                threadList.currentIndex = index


            }
            onItemPressAndHold: {
                if (!threadList.isInSelectionMode) {
                    threadList.startSelection()
                    threadList.selectItem(threadDelegate)
                }else{
                    threadList.cancelSelection()
                }


            }

            chatEntry : ChatEntry {
                chatType: model.properties.chatType
                participantIds: model.properties.participantIds ? model.properties.participantIds : []
                chatId: model.properties.threadId
                accountId: model.properties.accountId
                autoRequest: false
            }


            opacity: !groupChat || chatEntry.active ? 1.0 : 0.5

            ListView.onRemove: SequentialAnimation {
                PropertyAction { target: threadDelegate; property: "ListView.delayRemove"; value: true }
                NumberAnimation { target: threadDelegate; property: "height"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: threadDelegate; property: "ListView.delayRemove"; value: false }
            }
        }
        onSelectionDone: {
            var threadsToRemove = []
            for (var i=0; i < items.count; i++) {
                var threads = items.get(i).model.threads
                for (var j in threads) {
                    threadsToRemove.push(threads[j])
                }
            }
            if (threadsToRemove.length > 0) {
                mainView.removeThreads(threadsToRemove);
            }
        }

        Binding {
            target: threadList
            property: 'contentY'
            value: -threadList.headerItem.height
            when: mainView.composingNewMessage && mainView.dualPanel
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    function createQmlObjectAsynchronously(url, parent, properties, callback) {
        var component = Qt.createComponent(url, Component.Asynchronous);
        var incubator;

        function componentCreated() {
            if (component.status == Component.Ready) {
                incubator = component.incubateObject(parent, properties, Qt.Asynchronous);

                function objectCreated(status) {
                    if (status == Component.Ready && callback != undefined && callback != null) {
                        callback(incubator.object);
                    }
                }
                incubator.onStatusChanged = objectCreated;

            } else if (component.status == Component.Error) {
                console.log("Error loading component:", component.errorString());
            }
        }

        component.statusChanged.connect(componentCreated);
    }

    Timer {
        interval: 1
        repeat: false
        running: true
        onTriggered: {
            createQmlObjectAsynchronously(Qt.resolvedUrl("Scrollbar.qml"),
                                          mainPage,
                                          {"flickableItem": threadList})
            threadList.forceActiveFocus()
        }
    }

    Loader {
        id: bottomEdgeLoader
        asynchronous: true
        active: !mainView.dualPanel
        source: Qt.resolvedUrl('MessagingBottomEdge.qml')
        onLoaded: bottomEdgeLoader.item.parent = mainPage
    }

    onActiveFocusChanged: {
        if (activeFocus && threadList.currentItem !== null && threadList.currentItem >= 0 ) {
            threadList.currentItem.forceActiveFocus()
        }
    }

    Binding {
        target: pageStack
        property: "activePage"
        value: mainPage
        when: pageStack.columns === 1
    }

    KeyNavigation.right: pageStack.activePage
}
