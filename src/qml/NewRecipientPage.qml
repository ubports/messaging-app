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
    objectName: "newRecipientPage"

    property Item multiRecipient: null
    property Item parentPage: null
    property string phoneToAdd: ""
    property QtObject contactIndex: null

    function moveListToContact(contact)
    {
        if (active) {
            newRecipientPage.contactIndex = null
            contactList.positionViewAtContact(contact)
        } else {
            newRecipientPage.contactIndex = contact
        }
    }

    function addRecipient(phoneNumber)
    {
        multiRecipient.addRecipient(phoneNumber)
        multiRecipient.forceActiveFocus()
        mainStack.pop()
    }

    title: i18n.tr("Add recipient")

    TextField {
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
        onTextChanged: newRecipientPage.currentIndex = -1
        inputMethodHints: Qt.ImhNoPredictiveText
        placeholderText: i18n.tr("Search...")
        visible: false
    }

    state: "default"
    states: [
        PageHeadState {
            id: defaultState

            name: "default"
            actions: [
                Action {
                    text: i18n.tr("Search")
                    iconName: "search"
                    onTriggered: {
                        newRecipientPage.state = "searching"
                        contactList.showAllContacts()
                        searchField.forceActiveFocus()
                    }
                }
            ]
            PropertyChanges {
                target: newRecipientPage.head
                actions: defaultState.actions
                sections.model: [i18n.tr("All"), i18n.tr("Favorites")]
            }
            PropertyChanges {
                target: searchField
                text: ""
                visible: false
            }
        },
        PageHeadState {
            id: searchingState

            name: "searching"
            backAction: Action {
                iconName: "back"
                text: i18n.tr("Cancel")
                onTriggered: {
                    newRecipientPage.forceActiveFocus()
                    newRecipientPage.state = "default"
                    newRecipientPage.head.sections.selectedIndex = 0
                }
            }

            PropertyChanges {
                target: newRecipientPage.head
                backAction: searchingState.backAction
                contents: searchField
            }

            PropertyChanges {
                target: searchField
                text: ""
                visible: true
            }
        }
    ]

    ContactListView {
        id: contactList
        objectName: "newRecipientList"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }

        showAddNewButton: true
        showImportOptions: (contactList.count === 0) && (filterTerm == "")

        filterTerm: searchField.text
        onContactClicked: {
            if (newRecipientPage.phoneToAdd != "") {
                mainView.addPhoneToContact(contact,
                                           newRecipientPage.phoneToAdd,
                                           newRecipientPage,
                                           contactList.listModel)
            } else {
                mainView.showContactDetails(contact,
                                            newRecipientPage,
                                            contactList.listModel)
            }
        }

        onAddNewContactClicked: {
            var newContact = ContactsJS.createEmptyContact(newRecipientPage.phoneToAdd, newRecipientPage)
            pageStack.push(Qt.resolvedUrl("MessagingContactEditorPage.qml"),
                           { model: contactList.listModel,
                             contact: newContact,
                             initialFocusSection: (newRecipientPage.phoneToAdd != "" ? "phones" : "name"),
                             contactListPage: newRecipientPage
                           })
        }
    }

    // WORKAROUND: This is necessary to make the header visible from a bottom edge page
    Component.onCompleted: {
        parentPage.active = false
        if (QTCONTACTS_PRELOAD_VCARD !== "") {
            contactList.listModel.importContacts("file://" + QTCONTACTS_PRELOAD_VCARD)
        }
    }
    Component.onDestruction: parentPage.active = true

    KeyboardRectangle {
        id: keyboard
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

    Connections {
        target: contactList.listModel
        onContactsChanged: {
            if (newRecipientPage.contactIndex) {
                contactList.positionViewAtContact(newRecipientPage.contactIndex)
                newRecipientPage.contactIndex = null
            }
        }
    }
}
