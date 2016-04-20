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

Page {
    id: settingsPage
    title: i18n.tr("Settings")
    property var setMethods: {
        "mmsGroupChatEnabled": function(value) { telepathyHelper.mmsGroupChat = value }
    }
    property var settingsModel: [
        { "name": "mmsGroupChatEnabled",
          "description": i18n.tr("Enable MMS group chat"),
          "property": telepathyHelper.mmsGroupChat
        }
    ]

    // These fake items are used to track if there are instances loaded
    // on the second column because we have no access to the page stack
    Loader {
        sourceComponent: fakeItemComponent
        active: true
    }
    Component {
        id: fakeItemComponent
        Item { objectName:"fakeItem"}
    }

    header: PageHeader {
        id: pageHeader
        title: settingsPage.title
        leadingActionBar {
            actions: [
                Action {
                    id: singlePanelBackAction
                    objectName: "back"
                    name: "cancel"
                    text: i18n.tr("Cancel")
                    iconName: "back"
                    shortcut: "Esc"
                    visible: !mainView.dualPanel
                    onTriggered: {
                        // emptyStack will make sure the page gets removed.
                        mainView.emptyStack()
                    }
                }
            ]
        }
    }

    Component {
        id: settingDelegate
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(6)
            Label {
                id: descriptionLabel
                text: modelData.description
                anchors.left: parent.left
                anchors.right: checkbox.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: units.gu(2)
            }
            Switch {
                id: checkbox
                objectName: modelData.name
                anchors.right: parent.right
                anchors.rightMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                checked: modelData.property
                onCheckedChanged: {
                    if (checked != modelData.property) {
                        settingsPage.setMethods[modelData.name](checked)
                    }
                }
            }
        }
    }

    ListView {
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        model: settingsModel
        delegate: settingDelegate
    }

    Loader {
        id: messagesBottomEdgeLoader
        active: mainView.dualPanel
        sourceComponent: MessagingBottomEdge {
            id: messagesBottomEdge
            parent: settingsPage
            hint.text: ""
            hint.height: 0
        }
    }
}

