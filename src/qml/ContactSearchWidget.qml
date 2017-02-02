/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

FocusScope {
    id: searchItem
    property alias text: contactSearch.text
    property alias hasFocus: contactSearch.focus
    property Item parentPage: null
    property int searchResultsHeight: 0

    signal contactPicked(string identifier, string alias, string avatar)

    anchors {
        left: parent.left
        right: parent.right
    }
    height: units.gu(6)
    Label {
        id: membersLabel
        anchors.left: parent.left
        anchors.leftMargin: units.gu(2)
        height: units.gu(2)
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: contactSearch.verticalCenter
        text: i18n.tr("Members:")
    }

    onContactPicked: contactSearch.forceActiveFocus()

    TextField {
        id: contactSearch

        function commit()
        {
            if (text == "")
                return
            searchItem.contactPicked(text, "","")
            text = ""
        }

        anchors.top: parent.top
        anchors.left: membersLabel.right
        anchors.leftMargin: units.gu(1)
        anchors.right: parent.right
        height: units.gu(6)
        style: TransparentTextFieldStype { }
        hasClearButton: false
        placeholderText: i18n.tr("Number or contact name")
        inputMethodHints: Qt.ImhNoPredictiveText
        focus: true
        Keys.onReturnPressed: commit()
        Keys.onEnterPressed: commit()
        Keys.onDownPressed: searchListLoader.item.forceActiveFocus()

        Icon {
            name: "add"
            height: units.gu(2)
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.inputMethod.hide()
                    mainStack.addPageToCurrentColumn(searchItem.parentPage, Qt.resolvedUrl("NewRecipientPage.qml"), {"itemCallback": searchItem.parentPage})
                }
            }
            z: 2
        }
    }
    Loader {
        id: searchListLoader
        parent: searchItem.parentPage

        property int resultCount: (status === Loader.Ready) ? item.count : 0

        source: (searchItem.text !== "") && searchItem.hasFocus ?
                Qt.resolvedUrl("ContactSearchList.qml") : ""
        visible: source != ""
        anchors.left: parent.left
        anchors.bottom: keyboard.top
        width: parent.width
        height: searchItem.searchResultsHeight
        clip: true
        z: 2
        Rectangle {
            anchors.fill: parent
            color: Theme.palette.normal.background
        }

        Binding {
            target: searchListLoader.item
            property: "filterTerm"
            value: searchItem.text
            when: (searchListLoader.status === Loader.Ready)
        }

        onStatusChanged: {
            if (status === Loader.Ready) {
                item.contactPicked.connect(searchItem.contactPicked)
            }
        }

        Connections {
            target: searchListLoader.item
            onFocusUp: {
                contactSearch.forceActiveFocus()
            }
        }
    }
}
