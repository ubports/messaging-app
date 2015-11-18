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
import Ubuntu.Contacts 0.1
import "../"

Previewer {
    id: root

    title: contactView.title
    flickable: contactView.flickable

    MessagingContactViewPage {
        id: contactView

        function handleAction(action, detail)
        {
            if ((action === "message") || (action === "default")) {
                mainView.startChat(detail.value(0), "", false)
            } else {
                Qt.openUrlExternally(("%1:%2").arg(action).arg(detail.value(0)))
            }
        }

        header: Item { height: 0 }
        contact: thumbnail.vcard.contacts.length > 0 ? thumbnail.vcard.contacts[0] : null
        editable: false
        anchors.fill: parent
    }
}
