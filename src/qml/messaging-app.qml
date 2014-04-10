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
    property string newPhoneNumber

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient"
        mainStack.push(Qt.resolvedUrl("MainPage.qml"))
    }

    signal applicationReady

    function emptyStack() {
        while (mainStack.depth !== 1 && mainStack.depth !== 0) {
            mainStack.pop()
        }
    }

    function startNewMessage() {
        var properties = {}
        emptyStack()
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    function startChat(phoneNumber) {
        var properties = {}
        var participants = [phoneNumber]
        properties["participants"] = participants
        emptyStack()
        if (phoneNumber === "") {
            return;
        }
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
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
                ListItem.Standard {
                    text: i18n.tr("Create new contact")
                    onClicked: {
                        Qt.openUrlExternally("addressbook:///create?phone=" + encodeURIComponent(newPhoneNumber))
                        popover.hide()
                    }
                }
            }
        }
    }

    PageStack {
        id: mainStack
        objectName: "mainStack"
        anchors.fill: parent
    }
}
