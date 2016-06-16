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

Page {
    id: groupChatInfoPage

    property variant threads: []
    property variant participants: threads.length > 0 ? threads[0].participants : []
    property QtObject chatEntry: null

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


    function addRecipient(identifier) {
        chatEntry.inviteParticipants([identifier], "")
    }

    Flickable {
        id: contentsFlickable
        anchors.fill: parent

        Column {
            id: contentsColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            spacing: units.gu(1)

            Item {
                id: groupInfo
                height: visible ? groupAvatar.height : 0
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
                        verticalCenter: parent.verticalCenter
                    }
                    height: units.gu(6)
                    width: units.gu(6)
                }

                TextField {
                    id: groupName
                    verticalAlignment: Text.AlignVCenter
                    style: TransparentTextFieldStype {}
                    anchors {
                        left: groupAvatar.right
                        leftMargin: units.gu(1)
                        right: parent.right
                        rightMargin: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                }
            }

            Button {
                id: destroyButton
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                }
                visible: chatRoom && chatEntry
                text: i18n.tr("Delete group")
                onClicked: {
                    var result = chatEntry.destroyRoom()
                    // FIXME: show a dialog in case of failure
                }
            }

            ListItems.ThinDivider {
                visible: groupInfo.visible
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Label {
                id: participantsLabel
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                }
                text: i18n.tr("Participants")
                fontSize: "small"
                color: Theme.palette.normal.backgroundTertiaryText
            }

            Button {
                id: addParticipantButton
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                }

                visible: chatRoom
                text: i18n.tr("Add member")
                onClicked: mainStack.addFileToCurrentColumnSync(groupChatInfoPage,  Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": groupChatInfoPage})
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
                    onParticipantRemoved: chatEntry.removeParticipants([modelData.identifier], "")
                }
            }

        }
    }
}

