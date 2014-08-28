/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: newRecipientPage
    property Item multiRecipient: null
    property Item parentPage: null

    title: i18n.tr("Add recipient")

    head {
        contents: TextField {
            id: searchField

            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                topMargin: units.gu(1.5)
                bottomMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
            onTextChanged: contactList.currentIndex = -1
            inputMethodHints: Qt.ImhNoPredictiveText
            placeholderText: i18n.tr("Search...")
        }
        sections.model: ["All", "Favorites"]
    }

    Connections {
        target: newRecipientPage.head.sections
        onSelectedIndexChanged: {
            switch (newRecipientPage.head.sections.selectedIndex) {
            case 0:
                contactList.showAllContacts()
                break;
            case 1:
                contactList.showFavoritesContacts()
                break;
            default:
                break;
            }
        }
    }

    ContactListView {
        id: contactList
        objectName: "newRecipientList"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }
        filterTerm: searchField.text
        detailToPick: ContactDetail.PhoneNumber
        onDetailClicked: {
            if (action === "message" || action === "") {
                multiRecipient.addRecipient(detail.number)
                multiRecipient.forceActiveFocus()
            } else if (action === "call") {
                Qt.openUrlExternally("tel:///" + encodeURIComponent(detail.number))
            }
            mainStack.pop()
        }
        onInfoRequested: {
            Qt.openUrlExternally("addressbook:///contact?callback=messaging-app.desktop&id=" + encodeURIComponent(contact.contactId))
            mainStack.pop()
        }
        onAddDetailClicked: {
            // FIXME: the extra space at the end is needed so contacts-app opens the right view
            Qt.openUrlExternally("addressbook:///addphone?callback=messaging-app.desktop&id=" + encodeURIComponent(contact.contactId) + "&phone= ")
            mainStack.pop()
        }
    }

    // WORKAROUND: This is necessary to make the header visible from a bottom edge page
    Component.onCompleted: parentPage.active = false
    Component.onDestruction: parentPage.active = true

    KeyboardRectangle {
        id: keyboard
    }
}
