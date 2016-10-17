/*
 * Copyright 2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.History 0.1
import Ubuntu.Contacts 0.1
import Ubuntu.Keyboard 0.1

Page {
    id: groupChatInfoPage

    property variant threads: []
    property variant participants: threads.length > 0 ? threads[0].participants : []

    property var threadId: threads.length > 0 ? threads[0].threadId : ""
    property int chatType: threads.length > 0 ? threads[0].chatType : HistoryThreadModel.ChatTypeNone
    property bool chatRoom: chatType == HistoryThreadModel.ChatTypeRoom

    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Group Info")
        // FIXME: uncomment once the header supports subtitle
        //subtitle: i18n.tr("%1 member", "%1 members", participants.length)
        flickable: contentsFlickable
    }

    Flickable {
        id: contentsFlickable
        anchors.fill: parent
        contentHeight: contentsColumn.height
        clip: true

        Column {
            id: contentsColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            height: childrenRect.height
            spacing: units.gu(1)

            Item {
                id: groupInfo
                height: visible ? groupAvatar.height + groupAvatar.anchors.topMargin : 0
                visible: chatRoom

                anchors {
                    left: parent.left
                    right: parent.right
                }

                ContactAvatar {
                    id: groupAvatar

                    // FIXME: set to the group picture once implemented
                    //fallbackAvatarUrl:
                    fallbackDisplayName: groupName.text
                    showAvatarPicture: groupName.text.length === 0
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        top: parent.top
                        topMargin: units.gu(1)
                    }
                    height: units.gu(6)
                    width: units.gu(6)
                }

                TextField {
                    id: groupName
                    verticalAlignment: Text.AlignVCenter
                    style: TransparentTextFieldStype {}
                    text: chatEntry.title
                    anchors {
                        left: groupAvatar.right
                        leftMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1)
                        verticalCenter: groupAvatar.verticalCenter
                    }

                    InputMethod.extensions: { "enterKeyText": i18n.dtr("messaging-app", "Rename") }

                    // FIXME: check if there is a way to replace the enter button
                    // by a custom one saying "Rename" in OSK
                    onAccepted: {
                        chatEntry.title = groupName.text
                    }

                    Keys.onEscapePressed: {
                        groupName.text = chatEntry.title
                    }
                }
            }

            ListItems.ThinDivider {
                visible: groupInfo.visible
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Item {
                id: participantsHeader
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: Math.max(participantsLabel.height, addParticipantButton.height) + units.gu(2)

                Label {
                    id: participantsLabel
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    text: i18n.tr("Participants")
                    fontSize: "small"
                    color: Theme.palette.normal.backgroundTertiaryText
                }

                Button {
                    id: addParticipantButton
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }

                    visible: chatRoom
                    text: i18n.tr("Add member")
                }
            }

            ListItems.ThinDivider {
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Repeater {
                model: participants

                ParticipantDelegate {
                    participant: modelData
                }
            }

        }
    }
}

