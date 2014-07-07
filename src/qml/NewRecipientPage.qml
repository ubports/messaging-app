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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: newRecipientPage
    property Item multiRecipient: null
    title: i18n.tr("Add recipient")
    ContactListView {
        id: contactListLoader
        objectName: "newRecipientList"
        anchors.fill: parent
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
            Qt.openUrlExternally("addressbook:///contact?id=" + encodeURIComponent(contact.contactId))
            mainStack.pop()
        }
    }
}
