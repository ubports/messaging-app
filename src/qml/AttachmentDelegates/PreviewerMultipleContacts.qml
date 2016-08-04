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
import Ubuntu.Content 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.AddressBook.Base 0.1
import Ubuntu.AddressBook.ContactView 0.1

Previewer {
    id: root

    function saveAttachment()
    {
        // all contacts.
        root.handleAttachment(attachment.filePath, ContentHandler.Destination)
    }

    function shareAttchment()
    {
        // all contacts.
        root.handleAttachment(attachment.filePath, ContentHandler.Share)
    }

    title: thumbnail.title
    flickable: contactList

    MultipleSelectionListView {
        id: contactList

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        listModel: thumbnail.vcard.contacts
        listDelegate: ContactDelegate {
            id: contactDelegate
            objectName: "contactDelegate"

            property var contact: thumbnail.vcard.contacts[index]

            onClicked: {
                mainStack.addPageToCurrentColumn(root, sigleContatPreviewer, {'contact': contact})
            }
        }
    }

    Component {
        id: sigleContatPreviewer

        ContactViewPage {
            id: contactViewPage

            editable: false
            onActionTrigerred: {
                if ((action === "message") || (action == "default")) {
                    var properties = {'participantIds': [detail.value(0)]}
                    mainView.startChat(properties)
                    return
                } else {
                    Qt.openUrlExternally(("%1:%2").arg(action).arg(detail.value(0)))
                }
            }

            state: "default"
            states: [
                PageHeadState {
                    name: "default"
                    head: contactViewPage.head
                    actions: [
                        Action {
                            objectName: "saveButton"
                            text: i18n.tr("Save")
                            iconSource: "image://theme/save"
                            onTriggered: contactExporter.exportContact(contactViewPage.contact,
                                                                       ContentHandler.Destination)
                        },
                        Action {
                            objectName: "shareButton"
                            iconSource: "image://theme/share"
                            text: i18n.tr("Share")
                            onTriggered: contactExporter.exportContact(contactViewPage.contact,
                                                                       ContentHandler.Share)
                        }
                    ]
                }
            ]

            ContactExporter {
                id: contactExporter

                property int actionHandler: -1

                function exportContact(contact, handler)
                {
                    contactExporter.actionHandler = handler
                    contactExporter.start([contact])
                }

                contactModel: thumbnail.vcard._model
                exportToDisk: true
                onDone: {
                    console.debug("Export file:" + outputFile)
                    root.handleAttachment(outputFile, contactExporter.actionHandler)
                }
            }
        }
    }
}
