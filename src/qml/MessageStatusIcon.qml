/*
 * Copyright 2012 - 2016 Canonical Ltd.
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
import Ubuntu.History 0.1

Item {
    id: statusIcon

    property bool incoming
    property bool selectMode
    property int textMessageStatus
    property var messageDelegate

    height: units.gu(4)
    width: units.gu(4)
    onParentChanged: {
        // The spinner gets stuck once parent changes, this is a workaround
        indicator.running = false
        // if temporarily failed or unknown status, then show the spinner
        indicator.running = Qt.binding(function(){ return !incoming && 
                                                   (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                                                    textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed)});
    }
    anchors {
        verticalCenter: parent ? parent.verticalCenter : undefined
        right: parent ? parent.left : undefined
        rightMargin: units.gu(2)
    }

    ActivityIndicator {
        id: indicator

        anchors.centerIn: parent
        height: units.gu(2)
        width: units.gu(2)
        visible: running && !selectMode
    }

    Item {
        id: retrybutton

        anchors.fill: parent
        Icon {
            id: icon
            
            name: "reload"
            color: Theme.palette.normal.negative
            height: units.gu(2)
            width: units.gu(2)
            anchors {
                centerIn: parent
                verticalCenterOffset: units.gu(-1)
            }
            asynchronous: true
        }

        Label {
            text: i18n.tr("Failed!")
            fontSize: "small"
            color: "red"
            anchors {
                horizontalCenter: retrybutton.horizontalCenter
                top: icon.bottom
            }
        }
        visible: (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)
        MouseArea {
            id: retrybuttonMouseArea
            
            anchors.fill: parent
            onClicked: messageDelegate.resendMessage()
        }
    }
}
