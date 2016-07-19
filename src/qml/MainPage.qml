/*
 * Copyright 2012-2015 Canonical Ltd.
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
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import "dateUtils.js" as DateUtils

Page {
    id: mainPage
    property alias selectionMode: threadList.isInSelectionMode
    property bool searching: false
    property bool isEmpty: threadCount == 0 && !threadModel.canFetchMore
    property alias threadCount: threadList.count
    property alias displayedThreadIndex: threadList.currentIndex

    property var _messagesPage: null

    function startSelection() {
        threadList.startSelection()
    }

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
                        emptyStack()
                        pageStack.addPageToNextColumn(mainPage, Qt.resolvedUrl("SettingsPage.qml"))
                    }
                },
                Action {
                    objectName: "newMessageAction"
                    text: i18n.tr("New message")
                    iconName: "add"
                    onTriggered: mainView.bottomEdge.commit()
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
                    onTriggered: threadList.cancelSelection()
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
                title: " "
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
        Item {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            height: units.gu(3)
            Label {
                anchors.fill: parent
                elide: Text.ElideRight
                text: DateUtils.friendlyDay(Qt.formatDate(section, "yyyy/MM/dd"));
                verticalAlignment: Text.AlignVCenter
                fontSize: "small"
                color: Theme.palette.normal.backgroundTertiaryText
            }
            ListItem.ThinDivider {
                anchors.bottom: parent.bottom
            }
        }
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
        clip: true
        cacheBuffer: threadList.height * 2
        section.property: "eventDate"
        currentIndex: -1
        //spacing: searchField.text === "" ? units.gu(-2) : 0
        section.delegate: searching && searchField.text !== ""  ? null : sectionDelegate
        header: ListItem.Standard {
            id: newItem
            height: mainView.bottomEdge.status === BottomEdge.Committed &&
                    !mainView.bottomEdge.showingConversation &&
                    mainView.dualPanel ? units.gu(10) : 0
            text: i18n.tr("New message")
            iconName: "message-new"
            iconFrame: false
            selected: true
        }

        listDelegate: ThreadDelegate {
            id: threadDelegate
            // FIXME: find a better unique name
            objectName: "thread%1".arg(participants[0].identifier)

            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(8)
            selectionMode: threadList.isInSelectionMode
            selected: {
                if (selectionMode) {
                    return threadList.isSelected(threadDelegate)
                } else if (mainView.bottomEdge.status === BottomEdge.Committed ||
                           !mainView.inputInfo.hasKeyboard) {
                    return false
                } else {
                    // FIXME: there might be a better way of doing this
                    return index === threadList.currentIndex
                }
            }

            searchTerm: mainPage.searching ? searchField.text : ""
            onItemClicked: {
                if (threadList.isInSelectionMode) {
                    if (!threadList.selectItem(threadDelegate)) {
                        threadList.deselectItem(threadDelegate)
                    }
                } else {
                    var properties = model.properties
                    properties["keyboardFocus"] = false
                    properties["threads"] = model.threads
                    var participantIds = [];
                    for (var i in model.participants) {
                        participantIds.push(model.participants[i].identifier)
                    }
                    properties["participantIds"] = participantIds
                    properties["participants"] = model.participants
                    properties["presenceRequest"] = threadDelegate.presenceItem
                    if (displayedEvent != null) {
                        properties["scrollToEventId"] = displayedEvent.eventId
                    }
                    emptyStack()
                    mainStack.addPageToNextColumn(mainPage, messagesWithBottomEdge, properties)

                    // mark this item as current
                    threadList.currentIndex = index
                }
            }
            onItemPressAndHold: {
                threadList.startSelection()
                threadList.selectItem(threadDelegate)
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

    Scrollbar {
        flickableItem: threadList
        align: Qt.AlignTrailing
    }

    Loader {
        id: bottomEdgeLoader
        active: !selectionMode && !searching && !mainView.dualPanel
        sourceComponent: MessagingBottomEdge {
            parent: mainPage
        }
    }
}
