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
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

ListItemWithActions {
    id: messageFactory

    property bool incoming: false
    property string accountLabel

    // To be used by actions
    property int _index: index
    property var _lastItem

    signal deleteMessage()
    signal resendMessage()
    signal copyMessage()
    signal showMessageDetails()

    triggerActionOnMouseRelease: true
    width: messageList.width
    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: deleteMessage()
    }

    height: loader.height + units.gu(1)
    internalAnchors {
        topMargin: units.gu(0.5)
        bottomMargin: units.gu(0.5)
    }

    onItemClicked: {
        if (!selectionMode && (loader.status === Loader.Ready)) {
            loader.item.clicked(mouse)
        }
    }

    Loader {
        id: loader

        anchors {
            left: parent.left
            right: parent.right
        }
        source: textMessageAttachments.length > 0 ? Qt.resolvedUrl("MMSDelegate.qml") : Qt.resolvedUrl("SMSDelegate.qml")
        height: status == Loader.Ready ? item.height : 0
        onStatusChanged:  {
            if (status === Loader.Ready) {
                //signals
                messageFactory.resendMessage.connect(item.resendMessage)
                messageFactory.deleteMessage.connect(item.deleteMessage)
                messageFactory.copyMessage.connect(item.copyMessage)
                messageFactory.showMessageDetails(item.showMessageDetails)
            }
        }
        Binding {
            target: loader.item
            property: "messageData"
            value: messageData
            when: (loader.status === Loader.Ready)
        }
        Binding {
            target: loader.item
            property: "accountLabel"
            value: accountLabel
            when: (loader.status === Loader.Ready)
        }
        Binding {
            target: messageFactory
            property: "_lastItem"
            value: loader.item._lastItem
            when: (loader.status === Loader.Ready)
        }
    }

    Item {
        id: statusIcon

        height: units.gu(4)
        width: units.gu(4)
        parent: messageFactory._lastItem
        anchors {
            verticalCenter: parent ? parent.verticalCenter : undefined
            right: parent ? parent.left : undefined
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
                onClicked: messageFactory.resendMessage()
            }
        }
    }
}
