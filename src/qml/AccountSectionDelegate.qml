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

import "dateUtils.js" as DateUtils

ListItemWithActions {
    property var messageData: null
    property int index: -1
    property Item delegateItem
    property string accountLabel: telepathyHelper.accountForId(messageData.accountId).displayName

    // update the accountLabel when the list of accounts become available
    Item {
        Connections {
            target: telepathyHelper
            onAccountsChanged: accountLabel = telepathyHelper.accountForId(messageData.accountId).displayName
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
        text: i18n.tr("You switched to %1 @ %2")
              .arg(accountLabel)
              .arg(DateUtils.formatLogDate(messageData.timestamp))
        fontSize: "x-small"
        horizontalAlignment: Text.AlignHCenter
    }
}

