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
import Ubuntu.Contacts 0.1

Page {
    id: participantInfoPage
    property var delegate
    property var participant: delegate.participant
    property var chatEntry
    property bool chatRoom: false
    property bool knownContact: participant.contactId !== ""

    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Info")
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

            Item {
                id: groupInfo
                height: visible ? contactAvatar.height + contactAvatar.anchors.topMargin + units.gu(1) : 0

                anchors {
                    left: parent.left
                    right: parent.right
                }

                ContactAvatar {
                    id: contactAvatar

                    fallbackAvatarUrl: {
                        console.log(participant.avatar)
                        if (participant.avatar !== "") {
                            return participant.avatar
                        } else if (participant.alias === "") {
                            return "image://theme/contact"
                        }
                        return ""
                    }
                    fallbackDisplayName: contactName.text
                    showAvatarPicture: fallbackAvatarUrl !== ""
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        top: parent.top
                        topMargin: units.gu(2)
                    }
                    height: units.gu(6)
                    width: units.gu(6)
                }

                Label {
                    id: contactName
                    verticalAlignment: Text.AlignVCenter
                    text: {
                        if (participant.alias !== "") {
                            return participant.alias
                        } else {
                            return participant.identifier
                        }
                    }
                    anchors {
                        left: contactAvatar.right
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(1)
                        top: contactAvatar.top
                        topMargin: units.gu(1)
                    }
                }
            }

            Item {
               id: padding
               height: units.gu(1)
               anchors.left: parent.left
               anchors.right: parent.right
            }

            ListItems.ThinDivider {
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Item {
               id: padding3
               height: units.gu(2)
               anchors.left: parent.left
               anchors.right: parent.right
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                spacing: units.gu(2)
                Button {
                    id: showInContactsButton
                    text: knownContact ? i18n.tr("See in contacts") : i18n.tr("Add to contacts")
                    onClicked: { 
                        if (knownContact) {
                            mainView.showContactDetails(participantInfoPage, participant.contactId, null, null)
                        } else {
                            mainView.addPhoneToContact(participantInfoPage, "", participant.identifier, null, null)
                        }
                    }
                }

                Button {
                    id: setAsAdminButton
                    text: i18n.tr("Set as admin")
                    visible: false
                    // disabled until backends support this feature
                    //visible: chatRoom && chatEntry.active && chatEntry.selfContactRoles == 3
                }

                Button {
                    id: leaveButton
                    visible: delegate.canRemove()
                    text: i18n.tr("Remove from group")
                    color: Theme.palette.normal.negative
                    onClicked: {
                        delegate.removeFromGroup()
                        pageStack.removePages(participantInfoPage)
                    }
                }
            }
        }
    }
}

