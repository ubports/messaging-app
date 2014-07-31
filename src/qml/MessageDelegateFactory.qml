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
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

ListItemWithActions {
    id: root

    property bool incoming: false
    property string accountLabel: ""
    property var _lastItem: loader.status === Loader.Ready ? loader.item._lastItem : null

    signal deleteMessage()
    signal resendMessage()
    signal copyMessage()
    signal showMessageDetails()

    triggerActionOnMouseRelease: true

    anchors {
        left: parent ? parent.left : undefined
        right: parent ? parent.right: undefined
    }

    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: deleteMessage()
    }

    rightSideActions: [
// TODO: implement message info view
//        Action {
//            iconName: "info"
//            text: i18n.tr("Info")
//            onTriggered: showMessageDetails()
//        },
        Action {
            iconName: "edit-copy"
            text: i18n.tr("Copy")
            onTriggered: copyMessage()
        }
    ]

    height: loader.height + units.gu(2) //margin

    onItemClicked: {
        if (loader.status === Loader.Ready) {
            loader.item.clicked(mouse)
        }
    }

    Loader {
        id: loader

        onStatusChanged:  {
            if (status === Loader.Ready) {
                //signals
                root.resendMessage.connect(item.resendMessage)
                root.deleteMessage.connect(item.deleteMessage)
                root.copyMessage.connect(item.copyMessage)
                root.showMessageDetails(item.showMessageDetails)
            }
        }
        anchors {
            left: parent.left
            right: parent.right
        }
        height: status == Loader.Ready ? item.height : 0
        Component.onCompleted: {
            var initialProperties = {
                "incoming": root.incoming,
                "accountLabel": root.accountLabel,
                "attachments": textMessageAttachments,
                "accountId": accountId,
                "threadId": threadId,
                "eventId": eventId,
                "type": type,
                "text": textMessage,
                "messageStatus": textMessageStatus,
                "timestamp": timestamp
            }
            if (textMessageAttachments.length > 0) {
                setSource(Qt.resolvedUrl("MMSDelegate.qml"), initialProperties)
            } else {
                setSource(Qt.resolvedUrl("SMSDelegate.qml"), initialProperties)
            }
        }
    }

    Item {
        id: statusIcon

        height: units.gu(4)
        width: units.gu(4)
        parent: _lastItem
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.left
            rightMargin: units.gu(2)
        }

        visible: !incoming && !selectionMode
        ActivityIndicator {
            id: indicator

            anchors.centerIn: parent
            height: units.gu(2)
            width: units.gu(2)
            visible: running && !selectionMode
            // if temporarily failed or unknown status, then show the spinner
            running: (textMessageStatus === HistoryThreadModel.MessageStatusUnknown ||
                      textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed)
        }

        Item {
            id: retrybutton

            anchors.fill: parent
            Icon {
                id: icon

                name: "reload"
                color: "red"
                height: units.gu(2)
                width: units.gu(2)
                anchors {
                    centerIn: parent
                    verticalCenterOffset: units.gu(-1)
                }
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
                onClicked: root.resendMessage()
            }
        }
    }
}
