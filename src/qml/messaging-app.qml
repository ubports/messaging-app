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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1

MainView {
    id: mainView

    automaticOrientation: true
    width: units.gu(40)
    height: units.gu(71)
    property bool selectionMode: false
    property int selectionCount: 0
    onSelectionCountChanged: {
        if (selectionCount == 0) {
            selectionMode = false
        }
    }
    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient"
        mainStack.push(Qt.resolvedUrl("MainPage.qml"))
    }


    signal applicationReady

    Connections {
        target: telepathyHelper
        onAccountReady: {
            mainView.applicationReady()
        }
    }

    function startNewMessage() {
        var properties = {}
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    function startChat(phoneNumber) {
        var properties = {}
        properties["number"] = phoneNumber
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    Component {
        id: newcontactPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard { text: i18n.tr("Add to existing contact") }
                ListItem.Standard { text: i18n.tr("Create new contact") }
            }
        }
    }

    ToolbarItems {
        id: regularToolbar
        ToolbarButton {
            action: Action {
                iconSource: Qt.resolvedUrl("assets/compose.png")
                text: i18n.tr("Compose")
                onTriggered: mainView.startNewMessage()
            }
        }
    }

    ToolbarItems {
        id: selectionToolbar
        visible: selectionMode
        back: Button {
            text: i18n.tr("Cancel")
            anchors.verticalCenter: parent.verticalCenter
            onClicked: selectionMode = false
        }

        Button {
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Delete")
        }
        locked: true
        opened: true
    }

    PageStack {
        id: mainStack
        anchors.fill: parent
    }
}
