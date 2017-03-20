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
import QtContacts 5.0

import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1

UbuntuListView {
    id: root

    // FIXME: change the Ubuntu.Contacts model to search for more fields
    property alias filterTerm: contactModel.filterTerm

    signal contactPicked(string identifier, string label, string avatar)
    signal focusUp()

    ContactDetailPhoneNumberTypeModel {
        id: phoneTypeModel
    }

    ContactListModel {
        id: contactModel

        property var proxyModel: []

        manager: "galera"
        view: root
        autoUpdate: false
        sortOrders: [
            SortOrder {
                detail: ContactDetail.Tag
                field: Tag.Tag
                direction: Qt.AscendingOrder
                blankPolicy: SortOrder.BlanksLast
                caseSensitivity: Qt.CaseInsensitive
            },
            // empty tags will be sorted by display Label
            SortOrder {
                detail: ContactDetail.DisplayLabel
                field: DisplayLabel.Label
                direction: Qt.AscendingOrder
                blankPolicy: SortOrder.BlanksLast
                caseSensitivity: Qt.CaseInsensitive
            }
        ]

        fetchHint: FetchHint {
            // FIXME: check what other fields to load here
            detailTypesHint: [ ContactDetail.DisplayLabel,
                               ContactDetail.PhoneNumber ]
        }

        onContactsChanged: {
            var proxy = []
            for (var i=0; i < contacts.length; i++) {
                for (var p=0; p < contacts[i].phoneNumbers.length; p++) {
                    proxy.push({"contact": contacts[i], "phoneIndex": p})
                }
            }
            contactModel.proxyModel = proxy
        }
    }

    model: contactModel.proxyModel
    delegate: ListItem {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: itemLayout.height

        onClicked: root.contactPicked(modelData.contact.phoneNumbers[modelData.phoneIndex].number,
                                      modelData.contact.displayLabel.label, modelData.contact.avatar.url)

        ListItemLayout {
            id: itemLayout

            title.text: {
                // this is necessary to keep the string in the original format
                var originalText = modelData.contact.displayLabel.label
                var lowerSearchText =  filterTerm.toLowerCase()
                var lowerText = originalText.toLowerCase()
                var searchIndex = lowerText.indexOf(lowerSearchText)
                if (searchIndex !== -1) {
                   var piece = originalText.substr(searchIndex, lowerSearchText.length)
                   return originalText.replace(piece, "<b>" + piece + "</b>")
                } else {
                   return originalText
                }
            }
            title.fontSize: "medium"
            title.color: Theme.palette.normal.backgroundText

            subtitle.text: {
                var phoneDetail = modelData.contact.phoneNumbers[modelData.phoneIndex]
                return ("%1 %2").arg(phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label)
                                .arg(phoneDetail.number)
            }
            subtitle.color: Theme.palette.normal.backgroundSecondaryText
        }
    }

    Keys.onUpPressed: {
        if (currentIndex == 0)
            focusUp()

        event.accepted  = false
    }
}
