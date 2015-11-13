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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Content 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.AddressBook.Base 0.1

Previewer {
    id: root

    function saveAttachment()
    {
        if (contactList.isInSelectionMode) {
            console.debug("Export selected contact")
            contactExporter.exportSelectedContacts(ContentHandler.Destination)
        } else {
            // all contacts.
            console.debug("Export all contacts")
            root.handleAttachment(attachment.filePath, ContentHandler.Destination)
            root.actionTriggered()
        }
    }

    function shareAttchment()
    {
        if (contactList.isInSelectionMode) {
            console.debug("Share selected contact")
            contactExporter.exportSelectedContacts(ContentHandler.Share)
        } else {
            // all contacts.
            console.debug("Share selected contact")
            root.handleAttachment(attachment.filePath, ContentHandler.Share)
            root.actionTriggered()
        }
    }

    function backAction()
    {
        if (contactList.isInSelectionMode) {
            contactList.cancelSelection()
        } else {
            mainStack.pop()
        }
    }

    MultipleSelectionListView {
        id: contactList

        anchors.fill: parent
        listModel: vcardParser.contacts
        listDelegate: ContactDelegate {
            id: contactDelegate
            objectName: "contactDelegate"

            property var contact: vcardParser.contacts[index]

            selectionMode: contactList.isInSelectionMode
            selected: contactList.isSelected(contactDelegate)

            onClicked: {
                if (contactList.isInSelectionMode) {
                    if (!contactList.selectItem(contactDelegate)) {
                        contactList.deselectItem(contactDelegate)
                    }
                } else {
                    mainStack.push(Qt.resolvedUrl("../MessagingContactViewPage.qml"),
                                   {'contact': contact, 'readOnly': true})
                }
            }

            onPressAndHold: {
                if (contactList.multipleSelection) {
                    contactList.currentIndex = -1
                    contactList.startSelection()
                    contactList.selectItem(contactDelegate)
                }
            }

        }
    }

    VCardParser {
        id: vcardParser

        vCardUrl: attachment ? Qt.resolvedUrl(attachment.filePath) : ""
    }
    ContactExporter {
        id: contactExporter

        property int actionHandler: -1

        function exportSelectedContacts(handler)
        {
            contactList.enabled = false
            contactExporter.actionHandler = handler
            var contacts = []
            var items = contactList.selectedItems
            for (var i=0, iMax=items.count; i < iMax; i++) {
                contacts.push(items.get(i).model.modelData)
            }
            contactExporter.start(contacts)
        }

        contactModel: vcardParser._model
        exportToDisk: true
        onDone: {
            contactList.enabled = true
            root.handleAttachment(outputFile, contactExporter.actionHandler)
            root.actionTriggered()
        }
    }
}
