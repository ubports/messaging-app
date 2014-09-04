/*
 * Copyright 2012-2013 Canonical Ltd.
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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

ListItemWithActions {
    id: delegate

    property bool groupChat: participants.length > 1
    property string searchTerm
    property string phoneNumber: delegateHelper.phoneNumber
    property bool unknownContact: delegateHelper.isUnknown
    property string threadId: model.threadId
    property QtObject contactWatcher: delegateHelper.contactWatcher
    property string groupChatLabel: {
        var firstRecipient
        if (unknownContact) {
            firstRecipient = delegateHelper.phoneNumber
        } else {
            firstRecipient = delegateHelper.alias
        }

        if (participants.length > 1)
            return firstRecipient + " +" + String(participants.length-1)
        return firstRecipient
    }

    property string textMessage: {
        // check if this is an mms, if so, search for the actual text
        var imageCount = 0
        var videoCount = 0
        var contactCount = 0
        var attachmentCount = 0
        for (var i = 0; i < eventTextAttachments.length; i++) {
            if (startsWith(eventTextAttachments[i].contentType, "text/plain")) {
                return application.readTextFile(eventTextAttachments[i].filePath)
            } else if (startsWith(eventTextAttachments[i].contentType, "image/")) {
                imageCount++
            } else if (startsWith(eventTextAttachments[i].contentType, "video/")) {
                videoCount++
            } else if (startsWith(eventTextAttachments[i].contentType, "text/vcard") ||
                      startsWith(eventTextAttachments[i].contentType, "text/x-vcard")) {
                contactCount++
            }
        }
        attachmentCount = imageCount + videoCount + contactCount

        if (imageCount > 0 && attachmentCount == imageCount) {
            return i18n.tr("Attachment: %1 image", "Attachments: %1 images").arg(imageCount)
        }
        if (videoCount > 0 && attachmentCount == videoCount) {
            return i18n.tr("Attachment: %1 video", "Attachments: %1 videos").arg(videoCount)
        }
        if (contactCount > 0 && attachmentCount == contactCount) {
            return i18n.tr("Attachment: %1 contact", "Attachments: %1 contacts").arg(contactCount)
        }
        if (attachmentCount > 0) {
            return i18n.tr("Attachment: %1 file", "Attachments: %1 files").arg(attachmentCount)
        }
        return eventTextMessage
    }
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)
    // WORKAROUND: history-service can't filter by contact names
    onSearchTermChanged: {
        var found = false
        var searchTermLowerCase = searchTerm.toLowerCase()
        if (searchTerm !== "") {
            if ((delegateHelper.phoneNumber.toLowerCase().search(searchTermLowerCase) !== -1)
            || (!unknownContact && delegateHelper.alias.toLowerCase().search(searchTermLowerCase) !== -1)) {
                found = true
            }
        } else {
            found = true
        }

        height = found ? units.gu(8) : 0
    }

    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: {
            for (var i in threads) {
                threadModel.removeThread(threads[i].accountId, threads[i].threadId, threads[i].type)
            }
        }
    }

    ContactAvatar {
        id: avatar

        fallbackAvatarUrl: {
            if (groupChat) {
                return "image://theme/contact-group"
            } else if (delegateHelper.avatar !== "") {
                return delegateHelper.avatar
            } else {
                return "image://theme/contact"
            }
        }
        fallbackDisplayName: delegateHelper.alias
        showAvatarPicture: groupChat || (delegateHelper.avatar !== "") || (initials.length === 0)
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        height: units.gu(6)
        width: units.gu(6)
    }

    Label {
        id: contactName
        anchors {
            top: avatar.top
            topMargin: units.gu(0.5)
            left: avatar.right
            leftMargin: units.gu(1)
        }
        color: UbuntuColors.lightAubergine
        text: groupChat ? groupChatLabel : unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    }

    Row {
        id: time

        anchors {
            verticalCenter: contactName.verticalCenter
            right: parent.right
        }
        Label {
            fontSize: "x-small"
            font.weight: Font.DemiBold
            opacity: 0.70
            text: Qt.formatDateTime(eventTimestamp,"h:mm")
        }
        Label {
            fontSize: "x-small"
            opacity: 0.70
            text: Qt.formatDateTime(eventTimestamp," ap")
        }
    }


    UbuntuShape {
        id: unreadCountIndicator
        height: units.gu(2)
        width: height
        anchors {
            top: time.bottom
            topMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(2)
        }
        visible: unreadCount > 0
        color: "#38b44a"
        Label {
            anchors.centerIn: parent
            text: unreadCount
            color: "white"
            fontSize: "x-small"
            font.weight: Font.Light
        }
    }

    // This is currently not being used in the new designs, but let's keep it here for now
    /*
    Label {
        id: phoneType
        anchors {
            top: contactName.bottom
            left: contactName.left
        }
        text: delegateHelper.phoneNumberSubTypeLabel
        color: "gray"
        fontSize: "x-small"
    }*/

    Label {
        id: latestMessage

        anchors {
            top: contactName.bottom
            topMargin: units.gu(0.5)
            left: contactName.left
            right: time.left
            rightMargin: units.gu(3)
            bottom: avatar.bottom
        }
        elide: Text.ElideRight
        fontSize: "x-small"
        text: textMessage
    }

    Item {
        id: delegateHelper
        property alias phoneNumber: watcherInternal.phoneNumber
        property alias alias: watcherInternal.alias
        property alias avatar: watcherInternal.avatar
        property alias contactId: watcherInternal.contactId
        property alias subTypes: phoneDetail.subTypes
        property alias contexts: phoneDetail.contexts
        property alias isUnknown: watcherInternal.isUnknown
        property QtObject contactWatcher: watcherInternal
        property string phoneNumberSubTypeLabel: ""

        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = isUnknown ? "" : phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }

        onSubTypesChanged: updateSubTypeLabel();
        onContextsChanged: updateSubTypeLabel();
        onIsUnknownChanged: updateSubTypeLabel();

        ContactWatcher {
            id: watcherInternal
            phoneNumber: participants[0]
        }

        PhoneNumber {
            id: phoneDetail
            contexts: watcherInternal.phoneNumberContexts
            subTypes: watcherInternal.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
        }
    }
}
