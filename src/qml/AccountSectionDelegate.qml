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
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1

import "dateUtils.js" as DateUtils

ListItemWithActions {
    id: informationEvent
    property var messageData: null
    property int index: -1
    property Item delegateItem
    property var account: telepathyHelper.accountForId(messageData.accountId)
    property string accountLabel: account ? account.displayName : ""

    // update the accountLabel when the list of accounts become available
    Item {
        id: internalItem
        property var displayName: { 
            if (internalWatcher.alias == "") {
                return internalWatcher.identifier
            }
            return internalWatcher.alias
        }
        Connections {
            target: telepathyHelper
            onAccountsChanged: accountLabel = telepathyHelper.accountForId(messageData.accountId).displayName
        }
        ContactWatcher {
            id: internalWatcher
            identifier: {
                switch(messageData.textInformationType) {
                case HistoryThreadModel.InformationTypeNone:
                case HistoryThreadModel.InformationTypeText:
                case HistoryThreadModel.InformationTypeSimChange:
                case HistoryThreadModel.InformationTypeSelfJoined:
                case HistoryThreadModel.InformationTypeSelfLeaving:
                case HistoryThreadModel.InformationTypeSelfAdminGranted:
                case HistoryThreadModel.InformationTypeSelfAdminRemoved:
                case HistoryThreadModel.InformationTypeSelfKicked:
                case HistoryThreadModel.InformationTypeTitleChanged:
                    break;
                case HistoryThreadModel.InformationTypeJoined:
                case HistoryThreadModel.InformationTypeInvitationSent:
                case HistoryThreadModel.InformationTypeLeaving:
                case HistoryThreadModel.InformationTypeAdminGranted:
                case HistoryThreadModel.InformationTypeAdminRemoved:
                    return messageData.textSubject
                }
                return ""
            }
            addressableFields: account ? account.addressableVCardFields : ["tel"] // just to have a fallback there
        }
    }

    height: sectionLabel.height + units.gu(2)
    anchors.left: parent.left
    anchors.right: parent.right
    ListItem.ThinDivider {
        id: leftDivider
        anchors.verticalCenter: sectionLabel.verticalCenter
        anchors.left: parent.left
        anchors.right: sectionLabel.left
        anchors.rightMargin: 0
        anchors.leftMargin: 0
    }

    ListItem.ThinDivider {
        id: rightDivider
        anchors.verticalCenter: sectionLabel.verticalCenter
        anchors.left: sectionLabel.right
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.leftMargin: 0
    }

    onItemClicked: {
        if (root.isInSelectionMode) {
            if (!root.selectItem(delegateItem)) {
                root.deselectItem(delegateItem)
            }
        }
    }

    Label {
        id: sectionLabel
        anchors.horizontalCenter: parent.horizontalCenter
        height: paintedHeight
        clip: true
        // TRANSLATORS: %1 is the SIM card name and %2 is the timestamp
        text: {
            switch(messageData.textInformationType) {
            case HistoryThreadModel.InformationTypeNone:
            case HistoryThreadModel.InformationTypeText:
                return messageData.textMessage
            case HistoryThreadModel.InformationTypeInvitationSent:
                if (messageData.senderId === "") {
                    return i18n.tr("%1 was invited to this group").arg(internalItem.displayName)
                } else if (messageData.senderId === "self") {
                    return i18n.tr("You invited %1 to this group").arg(internalItem.displayName)
                } else {
                    return i18n.tr("%1 invited %2 to this group").arg(messageData.sender.alias).arg(internalItem.displayName)
                }
            case HistoryThreadModel.InformationTypeSimChange:
                return i18n.tr("You switched to %1 @ %2")
                           .arg(accountLabel)
                           .arg(DateUtils.formatLogDate(messageData.timestamp))
            case HistoryThreadModel.InformationTypeSelfLeaving:
                return i18n.tr("You left this group")
            case HistoryThreadModel.InformationTypeTitleChanged:
                if (messageData.senderId === "") {
                    return i18n.tr("Renamed group to: %1").arg(messageData.textSubject)
                } else if (messageData.senderId === "self") {
                    return i18n.tr("You renamed group to: %1").arg(messageData.textSubject)
                } else {
                    return i18n.tr("%1 renamed group to: %2").arg(messageData.sender.alias).arg(messageData.textSubject)
                }
            case HistoryThreadModel.InformationTypeLeaving:
                if (messageData.senderId !== "" && messageData.senderId !== "self") {
                    return i18n.tr("%1 removed %2 from this group").arg(messageData.sender.alias).arg(internalItem.displayName)
                } else {
                    return i18n.tr("%1 left this group").arg(internalItem.displayName)
                }
            case HistoryThreadModel.InformationTypeSelfJoined:
                return i18n.tr("You joined this group")
            case HistoryThreadModel.InformationTypeJoined:
                if (messageData.senderId !== "" && messageData.senderId !== "self") {
                    return i18n.tr("%1 added %2 to this group").arg(messageData.sender.alias).arg(internalItem.displayName)
                } else {
                    return i18n.tr("%1 joined this group").arg(internalItem.displayName)
                }
            case HistoryThreadModel.InformationTypeAdminGranted:
                if (messageData.senderId !== "" && messageData.senderId !== "self") {
                    return i18n.tr("%1 set %2 as Admin").arg(messageData.sender.alias).arg(internalItem.displayName)
                } else {
                    return i18n.tr("%1 is Admin").arg(internalItem.displayName)
                }
            case HistoryThreadModel.InformationTypeSelfAdminGranted:
                return i18n.tr("You are Admin")
            case HistoryThreadModel.InformationTypeAdminRemoved:
                if (messageData.senderId !== "" && messageData.senderId !== "self") {
                    return i18n.tr("%1 set %2 as not Admin").arg(messageData.sender.alias).arg(internalItem.displayName)
                } else {
                    return i18n.tr("%1 is not Admin").arg(internalItem.displayName)
                }
            case HistoryThreadModel.InformationTypeSelfAdminRemoved:
                return i18n.tr("You are not Admin")
            case HistoryThreadModel.InformationTypeSelfKicked:
                return i18n.tr("You were removed from this group")
            }
            return ""
        }
        fontSize: "x-small"
        horizontalAlignment: Text.AlignHCenter
    }
}

