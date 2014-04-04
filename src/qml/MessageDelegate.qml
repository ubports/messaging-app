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
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1

import "dateUtils.js" as DateUtils
import "ba-linkify.js" as BaLinkify

ListItem.Empty {
    id: messageDelegate
    property bool incoming: false
    property string textColor: incoming ? "#333333" : "#ffffff"
    property bool selectionMode: false
    property bool unread: false

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right: undefined
    height: bubble.height
    showDivider: false
    highlightWhenPressed: false

    signal resend()

    onPressAndHold: PopupUtils.open(popoverMenuComponent, messageDelegate)

    Item {
        Component {
            id: popoverMenuComponent
            Popover {
                id: popover
                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    ListItem.Standard {
                        text: i18n.tr("Copy")
                        onClicked: {
                            Clipboard.push(textMessage);
                            PopupUtils.close(popover)
                        }
                    }
                }
            }
        }
    }

    Item {
        Component {
            id: popoverComponent
            Popover {
                id: popover
                Column {
                    id: containerLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    ListItem.Standard {
                        text: i18n.tr("Try again")
                        enabled: telepathyHelper.connected
                        onClicked: {
                            resend()
                            PopupUtils.close(popover)
                        }
                    }
                    ListItem.Standard {
                        text: i18n.tr("Cancel")
                        onClicked: {
                            eventModel.removeEvent(accountId, threadId, eventId, type)
                            PopupUtils.close(popover)
                        }
                    }
                }
            }
        }
    }

    Icon {
        id: selectionIndicator
        visible: selectionMode
        name: "select"
        height: units.gu(3)
        width: units.gu(3)
        anchors.right: incoming ? undefined : bubble.left
        anchors.left: incoming ? bubble.right : undefined
        anchors.verticalCenter: bubble.verticalCenter
        anchors.leftMargin: incoming ? units.gu(2) : 0
        anchors.rightMargin: incoming ? 0 : units.gu(2)
        color: selected ? "white" : "grey"
    }

    ActivityIndicator {
        id: indicator
        height: units.gu(3)
        width: units.gu(3)
        anchors.right: bubble.left
        anchors.left: undefined
        anchors.verticalCenter: bubble.verticalCenter
        anchors.leftMargin: 0
        anchors.rightMargin: units.gu(1)

        visible: running && !selectionMode
        // if temporarily failed or unknown status, then show the spinner
        running: (textMessageStatus == HistoryThreadModel.MessageStatusUnknown ||
                  textMessageStatus == HistoryThreadModel.MessageStatusTemporarilyFailed) && !incoming
    }

    // FIXME: this is just a temporary workaround while we dont have the final design
    UbuntuShape {
        id: warningButton
        color: "yellow"
        height: units.gu(3)
        width: units.gu(3)
        anchors.right: bubble.left
        anchors.left: undefined
        anchors.verticalCenter: bubble.verticalCenter
        anchors.leftMargin: 0
        anchors.rightMargin: units.gu(1)
        visible: (textMessageStatus == HistoryThreadModel.MessageStatusPermanentlyFailed) && !incoming && !selectionMode
        MouseArea {
            anchors.fill: parent
            onClicked: PopupUtils.open(popoverComponent, warningButton)
        }
        Label {
            text: "!"
            color: "black"
            anchors.centerIn: parent
        }
    }

    onItemRemoved: {
        eventModel.removeEvent(accountId, threadId, eventId, type)
    }

    BorderImage {
        id: bubble

        anchors.left: incoming ? parent.left : undefined
        anchors.leftMargin: units.gu(1)
        anchors.right: incoming ? undefined : parent.right
        anchors.rightMargin: units.gu(1)
        anchors.top: parent.top

        function selectBubble() {
            var fileName = "assets/conversation_";
            if (incoming) {
                fileName += "incoming.sci";
            } else {
                fileName += "outgoing.sci";
            }
            return fileName;
        }

        source: selectBubble()

        height: messageContents.height + units.gu(4)

        Item {
            id: messageContents
            anchors {
                top: parent.top
                topMargin: units.gu(2)
                left: parent.left
                leftMargin: incoming ? units.gu(3) : units.gu(2)
                right: parent.right
                rightMargin: units.gu(3)
            }
            height: childrenRect.height

            // TODO: to be used only on multiparty chat
            Label {
                id: senderName
                anchors.top: parent.top
                height: text == "" ? 0 : paintedHeight
                fontSize: "large"
                color: textColor
                text: ""
            }

            Label {
                id: date
                objectName: 'messageDate'
                anchors.top: senderName.bottom
                height: paintedHeight
                fontSize: "x-small"
                color: textColor
                text: {
                    if (indicator.visible)
                        i18n.tr("Sending...")
                    else if (warningButton.visible)
                        i18n.tr("Failed")
                    else
                        DateUtils.friendlyDay(timestamp) + " " + Qt.formatDateTime(timestamp, "hh:mm AP")
                }
            }

            Label {
                id: messageText
                objectName: 'messageText'
                anchors.top: date.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                fontSize: "medium"
                color: textColor
                opacity: incoming ? 1 : 0.9
                text: parseText(textMessage)
                onLinkActivated:  Qt.openUrlExternally(link)
                function parseText(text) {
                    var phoneExp = /(\+?([0-9]+[ ]?)?\(?([0-9]+)\)?[-. ]?([0-9]+)[-. ]?([0-9]+)[-. ]?([0-9]+))/img;
                    // remove html tags
                    text = text.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
                    // replace line breaks
                    text = text.replace(/(\n)+/g, '<br />');
                    // check for links
                    text = BaLinkify.linkify(text);
                    // linkify phone numbers
                    return text.replace(phoneExp, '<a href="tel:///$1">$1</a>');

                }

            }
        }
    }
}
