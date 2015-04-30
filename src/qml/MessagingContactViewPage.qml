/*
 * Copyright 2015 Canonical Ltd.
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


import QtQuick 2.2
import QtContacts 5.0

import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0 as Popups
import Ubuntu.Contacts 0.1

import Ubuntu.AddressBook.Base 0.1
import Ubuntu.AddressBook.ContactView 0.1
import Ubuntu.AddressBook.ContactShare 0.1

ContactViewPage {
    id: root
    objectName: "contactViewPage"

    readonly property string contactEditorPageURL: Qt.resolvedUrl("MessagingContactEditorPage.qml")
    property string addPhoneToContact: ""
    property var contactListPage: null

    head.actions: [
        Action {
            objectName: "share"
            text: i18n.tr("Share")
            iconName: "share"
            onTriggered: {
                pageStack.push(root.contactShareComponent,
                               { contactModel: root.model,
                                 contacts: [root.contact] })
            }
        },
        Action {
            objectName: "edit"
            text: i18n.tr("Edit")
            iconName: "edit"
            onTriggered: {
                pageStack.push(contactEditorPageURL,
                               { model: root.model,
                                 contact: root.contact,
                                 contactListPage: root.contactListPage })
            }
        }
    ]

    model: ContactModel {
        id: sourceModel

        manager: (typeof(QTCONTACTS_MANAGER_OVERRIDE) !== "undefined") &&
                  (QTCONTACTS_MANAGER_OVERRIDE != "") ? QTCONTACTS_MANAGER_OVERRIDE : "galera"
        autoUpdate: false
    }

    extensions: ContactDetailSyncTargetView {
        contact: root.contact
        anchors {
            left: parent.left
            right: parent.right
        }
        height: implicitHeight
    }

    onContactRemoved: pageStack.pop()

    Component {
        id: contactShareComponent
        ContactSharePage {}
    }

    onContactFetched: {
        if (root.addPhoneToContact != "") {
            var detailSourceTemplate = "import QtContacts 5.0; PhoneNumber{ number: \"" + root.addPhoneToContact.trim() + "\" }"
            var newDetail = Qt.createQmlObject(detailSourceTemplate, contact)
            if (newDetail) {
                contact.addDetail(newDetail)
                pageStack.push(root.contactEditorPageURL,
                               { model: root.model,
                                 contact: contact,
                                 initialFocusSection: "phones",
                                 newDetails: [newDetail],
                                 contactListPage: root.contactListPage })
                root.addPhoneToContact = ""
            }
        }
    }

    onActionTrigerred: {
        if (action === "message") {
            if (root.contactListPage) {
                var list = root.contactListPage
                list.addRecipient(detail.value(0))
            } else {
                console.warn("Action message without contactList")
                pageStack.pop()
                mainView.startChat(detail.value(0), "")
                return
            }
        } else {
            Qt.openUrlExternally(("%1:///%2").arg(action).arg(detail.value(0)))
        }
        pageStack.pop()
    }
}
