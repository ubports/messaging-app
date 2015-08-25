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

LocalPageWithBottomEdge {
    id: mainPage
    property alias selectionMode: threadList.isInSelectionMode
    property bool searching: false
    property alias threadCount: threadList.count

    function startSelection() {
        threadList.startSelection()
    }

    state: selectionMode ? "select" : searching ? "search" : "default"
    title: selectionMode ? " " : i18n.tr("Messages")
    flickable: null

    bottomEdgeEnabled: !selectionMode && !searching
    bottomEdgeTitle: i18n.tr("+")
    bottomEdgePageComponent: Messages { active: false }

    TextField {
        id: searchField
        objectName: "searchField"
        visible: mainPage.searching
        anchors {
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

    states: [
        PageHeadState {
            name: "default"
            head: mainPage.head
            actions: [
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
                    onTriggered: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            ]
        },
        PageHeadState {
            name: "search"
            head: mainPage.head
            backAction: Action {
                objectName: "cancelSearch"
                visible: mainPage.searching
                iconName: "back"
                text: i18n.tr("Cancel")
                onTriggered: {
                    searchField.text = ""
                    mainPage.searching = false
                }
            }
            contents: searchField
        },
        PageHeadState {
            name: "select"
            head: mainPage.head
            backAction: Action {
                objectName: "selectionModeCancelAction"
                iconName: "back"
                onTriggered: threadList.cancelSelection()
            }
            actions: [
                Action {
                    objectName: "selectionModeSelectAllAction"
                    iconName: "select"
                    onTriggered: threadList.selectAll()
                },
                Action {
                    objectName: "selectionModeDeleteAction"
                    enabled: threadList.selectedItems.count > 0
                    iconName: "delete"
                    onTriggered: threadList.endSelection()
                }
            ]
        }
    ]

    Item {
        id: emptyStateScreen
        anchors.left: parent.left
        anchors.leftMargin: units.gu(6)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(6)
        height: childrenRect.height
        anchors.verticalCenter: parent.verticalCenter
        visible: threadCount == 0 && !threadModel.canFetchMore
        Icon {
            id: emptyStateIcon
            anchors.top: emptyStateScreen.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(5)
            width: height
            opacity: 0.3
            name: "message"
        }
        Label {
            id: emptyStateLabel
            anchors.top: emptyStateIcon.bottom
            anchors.topMargin: units.gu(2)
            anchors.left: parent.left
            anchors.right: parent.right
            text: i18n.tr("Compose a new message by swiping up from the bottom of the screen.")
            color: "#5d5d5d"
            fontSize: "x-large"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
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
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }
        listModel: threadModel
        clip: true
        cacheBuffer: threadList.height * 2
        section.property: "eventDate"
        //spacing: searchField.text === "" ? units.gu(-2) : 0
        section.delegate: searching && searchField.text !== ""  ? null : sectionDelegate
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
            selected: threadList.isSelected(threadDelegate)
            searchTerm: mainPage.searching ? searchField.text : ""
            onItemClicked: {
                if (threadList.isInSelectionMode) {
                    if (!threadList.selectItem(threadDelegate)) {
                        threadList.deselectItem(threadDelegate)
                    }
                } else {
                    var properties = model.properties
                    properties["keyboardFocus"] = false
                    if (displayedEvent != null) {
                        properties["scrollToEventId"] = displayedEvent.eventId
                    }
                    if (model.participants[0].alias) {
                        properties["firstRecipientAlias"] = model.participants[0].alias;
                    }
                    mainStack.addPageToNextColumn(mainPage, Qt.resolvedUrl("Messages.qml"), properties)
                }
            }
            onItemPressAndHold: {
                threadList.startSelection()
                threadList.selectItem(threadDelegate)
            }
        }
        onSelectionDone: {
            var threadsToRemove = [];
            for (var i=0; i < items.count; i++) {
                var threads = items.get(i).model.threads
                for (var j in threads) {
                    threadsToRemove.push(threads[j]);
                }
            }

            if (threadsToRemove.length > 0) {
                threadModel.removeThreads(threadsToRemove);
            }
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    Scrollbar {
        flickableItem: threadList
        align: Qt.AlignTrailing
    }
}
