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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.History 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneUtils


Item {
    id: root

    property QtObject activeDialog: null
    property var activeMessage: null

    function showMessageInfo(message)
    {
        if (!activeDialog) {
            Qt.inputMethod.hide()
            activeMessage = message
            activeDialog = PopupUtils.open(messageInfoDialog, QuickUtils.rootItem(this))
        }
    }

    Component {
        id: messageInfoDialog

        Dialog {
            id: dialogue

            parent: QuickUtils.rootItem(this)

            function statusToString(status)
            {
                switch(status)
                {
                case HistoryThreadModel.MessageStatusDelivered:
                    return i18n.tr("Delivered")
                case HistoryThreadModel.MessageStatusTemporarilyFailed:
                    return i18n.tr("Temporarily Failed")
                case HistoryThreadModel.MessageStatusPermanentlyFailed:
                    return i18n.tr("Failed")
                case HistoryThreadModel.MessageStatusAccepted:
                    return i18n.tr("Accepted")
                case HistoryThreadModel.MessageStatusRead:
                    return i18n.tr("Read")
                case HistoryThreadModel.MessageStatusDeleted:
                    return i18n.tr("Deleted")
                case HistoryThreadModel.MessageStatusPending:
                    return i18n.tr("Pending")
                case HistoryThreadModel.MessageStatusUnknown:
                    //FIXME: Received messages has Unknown status is that correct??
                    if (root.activeMessage.senderId !== "self") {
                        return i18n.tr("Received")
                    } else {
                        return i18n.tr("Unknown")
                    }
                default:
                    return i18n.tr("Unknown")
                }
            }

            function getTargetName(message)
            {
                if (!message)
                    return ""

                if (message.senderId !== "self") {
                    return root.activeMessage.accountLabel
                } else if (message.participants && (message.participants.length > 1)) {
                    return i18n.tr("Group")
                } else if (message.participants.length > 0) {
                    return message.participants[0].identifier
                } else {
                    return i18n.tr("Unknown")
                }
            }

            title: i18n.tr("Message info")

            Label {
                text: root.activeMessage ? "<b>%1:</b> %2".arg(i18n.tr("Type")).arg(root.activeMessage.type) : ""
            }

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("From"))
                .arg(root.activeMessage && root.activeMessage.senderId !== "self" ?
                     root.activeMessage && root.activeMessage.senderId : root.activeMessage.accountLabel)
            }

            Label {
                text: "<b>%1:</b> %2".arg(i18n.tr("To"))
                                     .arg(getTargetName(root.activeMessage))
            }

            /*
            // Disable list of contacts for now, this is not reliable on a IRC channel for example
            // the current participants can not the same at the moment when the message was sent
            ListView {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                height: units.gu(10) //Math.min(count * units.gu(3), units.gu(3))
                model: root.activeMessage && root.activeMessage.senderId === "self" && root.activeMessage.participants.length > 1 ? root.activeMessage.participants : []
                delegate: ListItem {
                    height: itemLayout.height + (divider.visible ? divider.height : 0)

                    ListItemLayout {
                        id: itemLayout

                        title.text: {
                            var formatted = PhoneUtils.PhoneUtils.format(modelData.identifier)
                            if (formatted.length > 0)
                                return formatted
                            else
                                return modelData.identifier
                        }
                    }
                }
            }
            */

            Label {
                text: root.activeMessage ?
                          "<b>%1:</b> %2".arg(i18n.tr("Sent")).arg(Qt.formatDateTime(root.activeMessage.timestamp, Qt.DefaultLocaleShortDate)) :
                          ""
                visible: root.activeMessage && (root.activeMessage.senderId === "self")
            }

            Label {
                text: root.activeMessage ?
                          "<b>%1:</b> %2".arg(i18n.tr("Received")).arg(Qt.formatDateTime(root.activeMessage.timestamp, Qt.DefaultLocaleShortDate)) :
                          ""
                visible: (root.activeMessage && root.activeMessage.senderId !== "self")
            }

            Label {
                text: root.activeMessage ?
                          "<b>%1:</b> %2".arg(i18n.tr("Read")).arg(Qt.formatDateTime(root.activeMessage.textReadTimestamp, Qt.DefaultLocaleShortDate)) :
                          ""
                visible: root.activeMessage && (root.activeMessage.senderId !== "self") && (root.activeMessage.textReadTimestamp > 0)
            }

            Label {
                text: root.activeMessage ? "<b>%1:</b> %2".arg(i18n.tr("Status")).arg(statusToString(root.activeMessage.status)) : ""
            }

            Button {
                action: Action {
                    text: i18n.tr("Close")
                    shortcut: "esc"
                    onTriggered: PopupUtils.close(root.activeDialog)
                }
            }

            Component.onDestruction: {
                root.activeDialog = null
                root.activeMessage = null
            }
        }
    }
}
