/*
 * Copyright 2012-2016 Canonical Ltd.
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
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: newRecipientPage
    objectName: "newRecipientPage"

    property var itemCallback: null
    property var accountToAdd: null
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

    function addRecipient(identifier, contact)
    {
        if (itemCallback) {
            itemCallback.addRecipient(identifier, contact)
            if (itemCallback.forceActiveFocus) {
                itemCallback.forceActiveFocus()
            }
        }
        mainStack.removePages(newRecipientPage)
    }

    function createEmptyContact(account, parent)
    {
        var details = [ {detail: "EmailAddress", field: "emailAddress", value: ""},
                        {detail: "Name", field: "firstName", value: ""}
                      ]

        var newContact =  Qt.createQmlObject("import QtContacts 5.0; Contact{ }", parent)
        var detailSourceTemplate = "import QtContacts 5.0; %1{ %2: \"%3\" }"
        for (var i=0; i < details.length; i++) {
            var detailMetaData = details[i]
            var newDetail = Qt.createQmlObject(detailSourceTemplate.arg(detailMetaData.detail)
                                            .arg(detailMetaData.field)
                                            .arg(detailMetaData.value), parent)
            newContact.addDetail(newDetail)
        }

        if (account.protocol === "OnlineAccount.Unknown") {
            var phoneSourceTemplate = "import QtContacts 5.0; PhoneNumber{ number: \"" + account.uri + "\" }"
            var newDetail = Qt.createQmlObject(phoneSourceTemplate, parent)
        } else {
            var accountSourceTemplate = "import QtContacts 5.0; OnlineAccount{ accountUri: \"%1\"; protocol: %2 }"
            var newDetail = Qt.createQmlObject(accountSourceTemplate
                                               .arg(account.uri)
                                               .arg(account.protocol), parent)
        }
        newContact.addDetail(newDetail)
        return newContact
    }

    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        title: i18n.tr("Add recipient")
        leadingActionBar {
            id: leadingBar
        }

        trailingActionBar {
            id: trailingBar
            actions: [
                Action {
                    text: i18n.tr("Back")
                    iconName: "back"
                    onTriggered: {
                        mainStack.removePages(newRecipientPage)
                        newRecipientPage.destroy()
                    }
                }
            ]
        }


    }

    Sections {
        id: headerSections
        model: [i18n.tr("All"), i18n.tr("Favorites")]
    }
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
        State {
            id: defaultState
            name: "default"
            property list<QtObject> trailingActions: [
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
                target: pageHeader
                trailingActions: defaultState.trailingActions
                extension: headerSections
            }
            PropertyChanges {
                target: searchField
                text: ""
                visible: false
            }
        },
        State {
            id: searchingState
            name: "searching"
            property list<QtObject> leadingActions: [
                Action {
                    iconName: "back"
                    text: i18n.tr("Cancel")
                    enabled: newRecipientPage.state == "searching"
                    shortcut: "Esc"
                    onTriggered: {
                        newRecipientPage.forceActiveFocus()
                        newRecipientPage.state = "default"
                        headerSections.selectedIndex = 0
                    }
                }
            ]

            PropertyChanges {
                target: pageHeader
                leadingActions: searchingState.leadingActions
                trailingActions: []
                contents: searchField
            }

            PropertyChanges {
                target: headerSections
                visible: false
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
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: keyboard.top
        }

        focus: true
        currentIndex: -1
        highlightSelected: false
        activeFocusOnTab: true
        showAddNewButton: true
        showImportOptions: (contactList.count === 0) && (filterTerm == "")
        // this will be used to callback the app, after create account
        onlineAccountApplicationId: "messaging-app"

        filterTerm: searchField.text
        onContactClicked: {
            if (newRecipientPage.accountToAdd) {
                mainView.addAccountToContact(newRecipientPage,
                                             contact,
                                             accountToAdd.protocol,
                                             accountToAdd.uri,
                                             newRecipientPage,
                                             contactList.listModel)
            } else {
                mainView.showContactDetails(newRecipientPage,
                                            contact,
                                            newRecipientPage,
                                            contactList.listModel)
            }
        }

        onAddNewContactClicked: {
            var newContact = newRecipientPage.createEmptyContact(newRecipientPage.accountToAdd, newRecipientPage)
            var focusField = "name"
            if (newRecipientPage.accountToAdd) {
                switch (newRecipientPage.accountToAdd.protocol) {
                case "OnlineAccount.Unknown":
                    focusField = "phones"
                    break
                default:
                    focusField = "ims"
                    break
                }
            }

            mainStack.addPageToCurrentColumn(newRecipientPage,
                                             Qt.resolvedUrl("MessagingContactEditorPage.qml"),
                                             { model: contactList.listModel,
                                               contact: newContact,
                                               initialFocusSection: focusField,
                                               contactListPage: newRecipientPage })
        }
    }

    Component.onCompleted: {
        if (QTCONTACTS_PRELOAD_VCARD !== "") {
            contactList.listModel.importContacts("file://" + QTCONTACTS_PRELOAD_VCARD)
        }
    }
    onActiveChanged: {
        if (active && (state === "searching")) {
            searchField.forceActiveFocus()
        } else {
            if (contactList.currentIndex === -1)
                contactList.currentIndex = 0
            contactList.forceActiveFocus()
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    Connections {
        target: headerSections
        onSelectedIndexChanged: {
            switch (headerSections.selectedIndex) {
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

    // WORKAROUND: Wee need this button to register the "Esc" shortcut,
    // adding it into the trailingActionBar cause the app to crash due a bug on SDK
    Button {
        visible: false
        action: Action {
            text: i18n.tr("Back")
            enabled: newRecipientPage.active
            shortcut: "Esc"
            onTriggered: {
                mainStack.removePages(newRecipientPage)
                newRecipientPage.destroy()
            }
        }
    }
}
