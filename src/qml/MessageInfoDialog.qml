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
import Ubuntu.Components.Popups 0.1


Item {
    id: root

    property QtObject activeDialog: null
    property var activeMessage: null

    function showMessageInfo(message)
    {
        if (!activeDialog) {
            activeMessage = message
            activeDialog = PopupUtils.open(messageInfoDialog, QuickUtils.rootItem(this))
        }
    }

    Component {
        id: messageInfoDialog

        Dialog {
            id: dialogue

            title: i18n.tr("Message info")

            anchors.centerIn: parent
            height: childrenRect.height
            width: childrenRect.width

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("Type")).arg(root.activeMessage.type)
            }

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("From")).arg(root.activeMessage.senderId !== "self" ? root.activeMessage.senderId : i18n.tr("Self"))
            }

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("Sent")).arg(Qt.formatDateTime(root.activeMessage.timestamp, Qt.DefaultLocaleShortDate))
                visible: (root.activeMessage.senderId === "self")
            }

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("Received")).arg(Qt.formatDateTime(root.activeMessage.textReadTimestamp, Qt.DefaultLocaleShortDate))
                visible: (root.activeMessage.senderId !== "self")
            }

            Button {
                text: i18n.tr("Close")
                onClicked: {
                    PopupUtils.close(root.activeDialog)
                }
            }

            Component.onDestruction: {
                root.activeDialog = null
                root.activeMessage = null
            }
        }
    }
}
