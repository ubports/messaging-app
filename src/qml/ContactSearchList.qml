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
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Contacts 0.1

ListView {
    id: root

    // FIXME: change the Ubuntu.Contacts model to search for more fields
    property alias filterTerm: contactModel.filterTerm
    onFilterTermChanged: console.debug("FILTER :" + filterTerm)

    signal contactPicked(string identifier, string label, string avatar)

    model: ContactListModel {
        id: contactModel

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
    }

    ContactDetailPhoneNumberTypeModel {
        id: phoneTypeModel
    }

    delegate: Item {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: phoneRepeater.count * units.gu(6)
        Column {
            anchors.fill: parent

            Repeater {
                id: phoneRepeater

                model: contact.phoneNumbers.length

                delegate: MouseArea {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(6)

                    onClicked: root.contactPicked(contact.phoneNumbers[index].number, contact.displayLabel.label, contact.avatar.url)

                    Column {
                        anchors.right: parent.right
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: childrenRect.height
                        spacing: units.gu(.5)

                        Label {
                            anchors {
                                left: parent.left
                                leftMargin: units.gu(2)
                                right: parent.right
                            }
                            height: units.gu(2)
                            text: {
                                // this is necessary to keep the string in the original format
                                var originalText = contact.displayLabel.label
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
                            fontSize: "medium"
                            color: Theme.palette.normal.backgroundText
                        }
                        Label {
                            anchors {
                                left: parent.left
                                leftMargin: units.gu(2)
                                right: parent.right
                            }
                            height: units.gu(2)
                            text: {
                                var phoneDetail = contact.phoneNumbers[index]
                                return ("%1 %2").arg(phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label)
                                                .arg(phoneDetail.number)
                            }
                            color: Theme.palette.normal.backgroundSecondaryText
                        }

                        ListItem.ThinDivider {}
                    }
                }
            }
        }
    }
}
