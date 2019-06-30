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
import Qt.labs.settings 1.0

Page {
    id: settingsPage
    title: i18n.tr("Settings")

    function createAccount()
    {
        if (onlineAccountHelper.item)
            onlineAccountHelper.item.run()
    }

    readonly property var setMethods: {
        "mmsEnabled": function(value) { telepathyHelper.mmsEnabled = value },
        "threadSort": function(value) { mainView.sortThreadsBy = value },
        "compactView": function(value) { mainView.compactView = value },
        "userTheme": function(value) { mainView.userTheme = value }
        //"characterCountEnabled": function(value) { msgSettings.showCharacterCount = value }
    }

    property var sortByModel: {
        "timestamp": i18n.tr("Sort by timestamp"),
        "title": i18n.tr("Sort by title")
    }

    property var themeModel: {
        "default": i18n.tr("System Theme"),
        "Ubuntu.Components.Themes.Ambiance": i18n.tr("Light"),
        "Ubuntu.Components.Themes.SuruDark": i18n.tr("Dark"),
    }

    readonly property var settingsModel: [
        { "type": "boolean",
          "data": {"name": "mmsEnabled",
                   "description": i18n.tr("Enable MMS messages"),
                   "property": telepathyHelper.mmsEnabled,
                   "activatedFuncion": null,
                   "setMethod": "mmsEnabled"}
        },
        { "type": "boolean",
          "data": {"name": "compactView",
                   "description": i18n.tr("Simplified conversation view"),
                   "property": mainView.compactView,
                   "activatedFuncion": null,
                   "setMethod": "compactView"}
        },
        { "type": "options",
          "data": { "name": "threadSort",
                    "description": i18n.tr("Sort threads"),
                    "currentValue": mainView.sortThreadsBy,
                    "subtitle": settingsPage.sortByModel[mainView.sortThreadsBy],
                    "options": sortByModel,
                    "setMethod": "threadSort"}
        },
        { "type": "options",
          "data": {"name": "userTheme",
                   "description": i18n.tr("Theme"),
                   "currentValue": mainView.userTheme,
                   "property": mainView.userTheme,
                   "subtitle": themeModel[mainView.userTheme],
                   "options": themeModel,
                   "setMethod": "userTheme"}
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
                layoutDelegate.item.activate()
                settingsList.currentIndex = index

            }
            ListItemLayout {
                title.text: modelData.data.description
                subtitle.text: modelData.data.subtitle ? modelData.data.subtitle : ""

                Loader {
                    id: layoutDelegate

                    sourceComponent: {
                        switch(modelData.type) {
                        case "action":
                            return actionDelegate
                        case "boolean":
                            return booleanDelegate
                        case "options":
                            return optionsDelegate
                        }
                    }

                    Binding {
                        target: layoutDelegate.item
                        property: "modelData"
                        value: modelData.data
                        when: layoutDelegate.status === Loader.Ready
                    }
                    Binding {
                        target: layoutDelegate.item
                        property: "index"
                        value: index
                        when: layoutDelegate.status === Loader.Ready
                    }
                }
            }
        }
    }

    Component {
        id: booleanDelegate

        CheckBox {
            id: checkbox
            objectName: modelData.name

            property var modelData: null
            property int index: -1

            function activate()
            {
                checkbox.checked = !checkbox.checked
            }

            SlotsLayout.position: SlotsLayout.Trailing
            checked: modelData.property
            onCheckedChanged: {
                if (checked != modelData.property) {
                    settingsPage.setMethods[modelData.setMethod](checked)
                }
            }
        }
    }

    Component {
        id: actionDelegate

        ProgressionSlot {
            id: progression
            objectName: modelData.name

            property var modelData: null
            property int index: -1
            function activate()
            {
                settingsPage[modelData.onActivated]()
            }
        }
    }

    Component {
        id: optionsDelegate

        ProgressionSlot {
            id: progression
            objectName: modelData.name

            property var modelData: null
            property int index: -1
            function activate()
            {
                pageStack.addPageToNextColumn(settingsPage, optionsDelegatePage,
                                              {"title": modelData.description,
                                               "model": modelData.options,
                                               "index": index,
                                               "currentIndex": modelData.currentValue,
                                               "setMethod": modelData.setMethod})
            }
        }
    }

    Component {
        id: optionsDelegatePage

        Page {
            id: optionsPage

            property alias title: pageHeader.title
            property var model
            property string currentIndex
            property string setMethod
            property int index: -1

            signal selected(string key)

            function indexOf(key) {
                return Object.keys(optionsPage.model).indexOf(key)
            }

            onSelected: {
                if (key !== "") {
                    settingsPage.setMethods[optionsPage.setMethod](key)
                }
                //WORKAROUND: re-set index of settings page because the list is
                // rebuild after a value change and that cause the index to reset to 0
                settingsList.currentIndex = index
                pageStack.removePages(optionsPage)
            }

            header: PageHeader {
                id: pageHeader

                leadingActionBar.actions: [
                    Action {
                       iconName: "back"
                       text: i18n.tr("Back")
                       shortcut: "Esc"
                       onTriggered: optionsPage.selected("")
                    }
                ]
                flickable: pageView
            }

            UbuntuListView {
                id: pageView

                model: Object.keys(optionsPage.model)
                anchors.fill: parent
                currentIndex: optionsPage.indexOf(optionsPage.currentIndex)
                delegate: ListItem {
                    ListItemLayout {
                        title.text: optionsPage.model[modelData]
                    }
                    onClicked: optionsPage.selected(modelData)
                }
            }

            onActiveChanged: this.forceActiveFocus()
        }
    }

    ListView {
        id: settingsList

        currentIndex: -1
        anchors {
            fill: parent
        }
        model: settingsModel
        delegate: settingDelegate
    }

    Loader {
        id: messagesBottomEdgeLoader
        active: mainView.dualPanel
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

    Loader {
        id: onlineAccountHelper

        anchors.fill: parent
        asynchronous: true
        source: Qt.resolvedUrl("OnlineAccountsHelper.qml")
    }
}
