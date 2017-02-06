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
import Ubuntu.OnlineAccounts.Client 0.1

Page {
    id: settingsPage
    title: i18n.tr("Settings")

    property var setMethods: {
        "mmsEnabled": function(value) { telepathyHelper.mmsEnabled = value }/*,
        "characterCountEnabled": function(value) { msgSettings.showCharacterCount = value }*/
    }
    property var settingsModel: [
        { "name": "mmsEnabled",
          "description": i18n.tr("Enable MMS messages"),
          "property": telepathyHelper.mmsEnabled,
          "activatedFuncion": null
        },
        { "name": "addAccount",
          "description": i18n.tr("Add an online account"),
          "onActivated": "createAccount",
          "property": null
        }
        /*,
        { "name": "characterCountEnabled",
          "description": i18n.tr("Show character count"),
          "property": msgSettings.showCharacterCount
        }*/
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
        leadingActionBar.actions: [
            Action {
               iconName: "back"
               text: i18n.tr("Back")
               shortcut: "Esc"
               onTriggered: mainView.emptyStack(true)
            }
        ]
        flickable: settingsList
    }

    onActiveChanged: {
        if (active) {
            settingsList.forceActiveFocus()
        }
    }


    Component {
        id: settingDelegate
        ListItem {
            onClicked: {
                if (checkbox.visible) {
                    checkbox.checked = !checkbox.checked
                } else {
                    settingsPage[modelData.onActivated]()
                }
            }
            ListItemLayout {
                title.text: modelData.description

                CheckBox {
                    id: checkbox
                    objectName: modelData.name

                    visible: modelData.property !== null
                    SlotsLayout.position: SlotsLayout.trailing
                    checked: modelData.property
                    onCheckedChanged: {
                        if (checked != modelData.property) {
                            settingsPage.setMethods[modelData.name](checked)
                        }
                    }
                }

                ProgressionSlot {
                    visible: modelData.property === null
                }
            }
        }
    }

    UbuntuListView {
        id: settingsList

        anchors {
            //topMargin: mainPage.header.flickable ? 0 : mainPage.header.height
            fill: parent
        }
        model: settingsModel
        delegate: settingDelegate
    }

    Loader {
        id: messagesBottomEdgeLoader
        active: mainView.dualPanel
        //asynchronous: true
        /* FIXME: would be even more efficient to use setSource() to
           delay the compilation step but a bug in Qt prevents us.
           Ref.: https://bugreports.qt.io/browse/QTBUG-54657
        */
        sourceComponent: MessagingBottomEdge {
            id: messagesBottomEdge
            parent: settingsPage
            hint.text: ""
            hint.height: 0
        }
    }

    function createAccount()
    {
        if (onlineAccountHelper.item)
            onlineAccountHelper.item.run()
    }

    Loader {
        id: onlineAccountHelper

        anchors.fill: parent
        asynchronous: true
        source: Qt.resolvedUrl("OnlineAccountsHelper.qml")
    }


}
