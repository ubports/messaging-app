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
import "3rd_party/ba-linkify.js" as BaLinkify

Item {
    id: messageDelegate
    property bool incoming: false
    property string textColor: incoming ? "#333333" : "#ffffff"
    property bool selectionMode: false
    property bool unread: false
    property alias confirmRemoval: internalDelegate.confirmRemoval
    property alias removable: internalDelegate.removable
    property alias selected: internalDelegate.selected

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right: undefined
    height: attachments.height + internalDelegate.height

    signal resend()
    signal clicked()

    Column {
        id: attachments
        anchors.top: parent.top
        height: childrenRect.height
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: units.gu(1)
        anchors.rightMargin: units.gu(1)
        // TODO: we currently support only images as attachments
        Repeater {
            model: textMessageAttachments
            Loader {
                anchors.left: parent.left
                anchors.right: parent.right
                height: item ? item.height : undefined
                source: {
                    switch (modelData.contentType) {
                    case "image/jpeg":
                    case "image/gif":
                    case "image/*":
                    case "image/tiff":
                    case "image/png":
                    case "image/vnd.wap.wbmp":
                        "MMSImage.qml"
                        break
                    default:
                        console.log("No MMS render for " + modelData.contentType)
                        return ""
                    }
                }
                onStatusChanged: {
                    if (status == Loader.Ready) {
                        item.attachment = modelData
                        item.incoming = incoming
                    }
                }
                Connections {
                    target: item
                    onItemRemoved: {
                        console.log("attachment removed: " + modelData.attachmentId)
                    }
                }
            }
        }
    }

    ListItem.Empty {
        id: internalDelegate
        anchors.top: attachments.bottom
        anchors.left: parent ? parent.left : undefined
        anchors.right: parent ? parent.right: undefined
        clip: true
        height: (textMessage === "" && textMessageAttachments.length > 0) ? 0 : bubble.height
        showDivider: false
        highlightWhenPressed: false
        onPressAndHold: PopupUtils.open(popoverMenuComponent, messageDelegate)

        onClicked: messageDelegate.clicked()

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
                                messageDelegate.resend()
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
                        text = text.replace(/</g,'&lt;').replace(/>/g,'<tt>&gt;</tt>');
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
}
