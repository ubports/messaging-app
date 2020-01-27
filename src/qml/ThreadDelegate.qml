/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import Ubuntu.History 0.1
import "dateUtils.js" as DateUtils

ListItemWithActions {
    id: delegate

    property QtObject chatEntry: null
    property bool compactView: false
    property var participant: participants ? participants[0] : {}
    property bool groupChat: chatType == HistoryThreadModel.ChatTypeRoom || participants.length > 1
    property string searchTerm
    property string phoneNumber: delegateHelper.phoneNumber
    property bool unknownContact: delegateHelper.isUnknown
    property string threadId: model.threadId
    property var displayedEvent: null
    property var displayedEventTextAttachments: displayedEvent ? displayedEvent.textMessageAttachments : eventTextAttachments
    property var displayedEventTimestamp: displayedEvent ? displayedEvent.timestamp : timestamp
    property var displayedEventTextMessage: displayedEvent ? displayedEvent.textMessage : eventTextMessage
    property QtObject presenceItem: delegateHelper.presenceItem
    property string groupTitle: {
        if (chatType == HistoryThreadModel.ChatTypeRoom) {
            if (chatRoomInfo.Title != "") {
                return chatRoomInfo.Title
            } else if (chatRoomInfo.RoomName != "") {
                return chatRoomInfo.RoomName
            }
        }
        return ""
    }

    property string groupChatLabel: {
        if (groupTitle != "") {
            return groupTitle
        }

        var finalParticipants = participants.length
        if (chatType == HistoryThreadModel.ChatTypeRoom && chatRoomInfo.Joined) {
            finalParticipants++
        }
        var firstRecipient
        if (unknownContact) {
            firstRecipient = delegateHelper.phoneNumber
        } else {
            firstRecipient = delegateHelper.alias
        }

        if (participants.length > 1) {
            // TRANSLATORS: %1 is the first recipient the message is sent to, %2 is the count of remaining recipients
            return i18n.tr("%1 + %2").arg(firstRecipient).arg(String(finalParticipants-1))
        }
        return firstRecipient
    }

    property bool isBroadcast: chatType != HistoryThreadModel.ChatTypeRoom && participants.length > 1

    function formatDisplayedText(text) {
        return text.replace("\n", " ")
    }

    property string textMessage: {
        // check if this is an mms, if so, search for the actual text
        var imageCount = 0
        var videoCount = 0
        var contactCount = 0
        var audioCount = 0
        var attachmentCount = 0
        for (var i = 0; i < displayedEventTextAttachments.length; i++) {
            if (startsWith(displayedEventTextAttachments[i].contentType, "text/plain")) {
                return application.readTextFile(displayedEventTextAttachments[i].filePath)
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "image/")) {
                imageCount++
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "video/")) {
                videoCount++
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "text/vcard") ||
                      startsWith(displayedEventTextAttachments[i].contentType, "text/x-vcard")) {
                contactCount++
            } else if (startsWith(displayedEventTextAttachments[i].contentType, "audio/")) {
                audioCount++
            }
        }
        attachmentCount = imageCount + videoCount + contactCount + audioCount

        if (imageCount > 0 && attachmentCount == imageCount) {
            return i18n.tr("Attachment: %1 image", "Attachments: %1 images").arg(imageCount)
        }
        if (videoCount > 0 && attachmentCount == videoCount) {
            return i18n.tr("Attachment: %1 video", "Attachments: %1 videos").arg(videoCount)
        }
        if (contactCount > 0 && attachmentCount == contactCount) {
            return i18n.tr("Attachment: %1 contact", "Attachments: %1 contacts").arg(contactCount)
        }
        if (audioCount > 0 && attachmentCount == audioCount) {
            return i18n.tr("Attachment: %1 audio clip", "Attachments: %1 audio clips").arg(audioCount)
        }
        if (attachmentCount > 0) {
            return i18n.tr("Attachment: %1 file", "Attachments: %1 files").arg(attachmentCount)
        }
        return formatDisplayedText(displayedEventTextMessage)
    }

    state: compactView ? "compactView" : ""
    states: [
        State {
            name: "compactView"
            PropertyChanges {
                target: avatar
                visible: false
                height:  0
                width: 0
            }
            PropertyChanges {
                target: delegate
                height: units.gu(4)
            }
            PropertyChanges {
                target: latestMessage
                visible: false
            }
            PropertyChanges {
                target: protocolIcon
                visible: false
            }
            AnchorChanges {
                target: unreadCountIndicator
                anchors.left: contactName.left
                anchors.verticalCenter: contactName.verticalCenter
                anchors.right: undefined
                anchors.top: undefined
                anchors.bottom: undefined
            }
            AnchorChanges {
                target: contactName
                anchors.right: time.left
            }
        }
    ]
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(8)

    leftSideAction:
            Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered: {
                    mainView.removeThreads(model.threads)
                }
            }

    Component.onCompleted: {
        if (searchTerm !== "") {
            delegateHelper.updateSearch()
        }
    }

    ContactAvatar {
        id: avatar

        fallbackAvatarUrl: {
            if (delegateHelper.avatar !== "") {
                return delegateHelper.avatar
            } else {
                return "image://theme/contact"
            }
        }
        fallbackDisplayName: (isBroadcast || groupTitle == "") ? delegateHelper.alias : contactName.text
        showAvatarPicture: (delegateHelper.avatar !== "") || (initials.length === 0)
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        height: units.gu(6)
        width: units.gu(6)
    }

    Image {
        id: chatTypeIcon
        anchors {
            verticalCenter: contactName.verticalCenter
            left: avatar.right
            leftMargin: units.gu(1)
        }
        visible: source != ""
        source: {
            if (isBroadcast) {
                return "image://theme/broadcast"
            } else if (groupChat) {
                return "image://theme/contact-group"
            }
            return "image://theme/contact"
        }
        asynchronous: true
        sourceSize.height: units.gu(2)
    }

    Label {
        id: contactName
        anchors {
            top: avatar.top
            topMargin: units.gu(0.5)
            left: chatTypeIcon.right
            leftMargin: units.gu(1)
            right: time.left
            rightMargin: unreadCountIndicator.width
        }
        elide: Text.ElideRight
        color: Theme.palette.normal.backgroundText
        font.bold: unreadCount > 0
        text: {
            if (groupChat) {
                return groupChatLabel
            } else {
                if (delegateHelper.phoneNumber == "x-ofono-unknown") {
                    // FIXME: replace the dtr() call by a regular tr() call after
                    // string freeze
                    return i18n.dtr("telephony-service", "Unknown Number")
                } else if (unknownContact) {
                    return delegateHelper.phoneNumber
                } else {
                    return delegateHelper.alias
                }
            }
        }
    }

    Label {
        id: time

        anchors {
            verticalCenter: contactName.verticalCenter
            right: parent.right
        }

        text: {
            if (!displayedEvent) {
                Qt.formatTime(displayedEventTimestamp, Qt.DefaultLocaleShortDate)
            } else {
                DateUtils.friendlyDay(Qt.formatDate(displayedEventTimestamp, "yyyy/MM/dd"), i18n)
            }
        }
        fontSize: "small"
        color: Theme.palette.normal.backgroundTertiaryText
    }

    Image {
        id: protocolIcon
        anchors {
            top: time.bottom
            topMargin: units.gu(1)
            right: parent.right
        }
        height: units.gu(2)
        width: units.gu(2)
        visible: source !== ""
        asynchronous: true
        source: {
            if (!telepathyHelper.ready) {
                return ""
            }

            // for any chat room, or generic account, show the icon
            if (chatType == HistoryThreadModel.ChatTypeRoom || telepathyHelper.accountForId(model.accountId).type == AccountEntry.GenericAccount) {
                return telepathyHelper.accountForId(model.accountId).protocolInfo.icon
            }
            if (delegateHelper.presenceType != PresenceRequest.PresenceTypeUnknown
                    && delegateHelper.presenceType != PresenceRequest.PresenceTypeUnset) {
                return telepathyHelper.accountForId(delegateHelper.presenceAccountId).protocolInfo.icon
            }
            return ""
        }
    }

    UbuntuShape {
        id: unreadCountIndicator
        height: units.gu(2)
        width: height
        anchors {
            top: avatar.top
            topMargin: units.gu(-0.5)
            left: avatar.left
            leftMargin: delegate.state == "compactView" ? contactName.paintedWidth + units.gu(0.5) : units.gu(-0.5)
        }
        z: 1
        visible: unreadCount > 0
        color: Theme.palette.normal.positive
        Label {
            anchors.centerIn: parent
            text: unreadCount
            color: Theme.palette.normal.positiveText
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
        color: Theme.palette.normal.backgroundSecondaryText
        fontSize: "x-small"
    }*/

    Label {
        id: latestMessage

        anchors {
            top: contactName.bottom
            topMargin: units.gu(0.5)
            left: chatTypeIcon.left
            right: time.left
            rightMargin: units.gu(3)
            bottom: avatar.bottom
        }
        elide: Text.ElideRight
        fontSize: "x-small"
        text: textMessage
        // avoid any kind of formatting in the text message preview
        textFormat: Text.PlainText
        maximumLineCount: 2
        wrapMode: Text.Wrap
        color: Theme.palette.normal.backgroundSecondaryText
    }

    Item {
        id: delegateHelper
        property string phoneNumber: participant ? participant.identifier : ""
        property string alias: participant && participant.alias ? participant.alias : ""
        property string avatar: participant && participant.avatar ? participant.avatar : ""
        property string contactId: participant && participant.contactId ? participant.contactId : ""
        property alias subTypes: phoneDetail.subTypes
        property alias contexts: phoneDetail.contexts
        property bool isUnknown: contactId === ""
        property string phoneNumberSubTypeLabel: ""
        property alias presenceAccountId: presenceRequest.accountId
        property alias presenceType: presenceRequest.type
        property alias presenceItem: presenceRequest
        property string latestFilter: ""
        property var searchHistoryFilter
        property var searchHistoryFilterString: 'import Ubuntu.History 0.1;
            HistoryUnionFilter {
                %1
            }'
        property var searchIntersectionFilter: 'HistoryIntersectionFilter {
            HistoryFilter { filterProperty: "accountId"; filterValue: \'%1\' }
            HistoryFilter { filterProperty: "threadId"; filterValue: \'%2\' }
            HistoryFilter { filterProperty: "message"; filterValue: searchTerm; matchFlags: HistoryFilter.MatchContains }
        }
        '

        function updateSearch() {
            var found = false
            var searchTermLowerCase = searchTerm.toLowerCase()
            if (searchTerm !== "") {
                if ((delegateHelper.phoneNumber.toLowerCase().search(searchTermLowerCase) !== -1)
                || (!unknownContact && delegateHelper.alias.toLowerCase().search(searchTermLowerCase) !== -1)) {
                    found = true
                } else {
                    var componentFilters = ""
                    for(var i in model.threads) {
                        componentFilters += searchIntersectionFilter.arg(model.threads[i].accountId).arg(model.threads[i].threadId)
                    }
                    var finalString = searchHistoryFilterString.arg(componentFilters)
                    if (finalString !== latestFilter) {
                        delegateHelper.searchHistoryFilter = Qt.createQmlObject(finalString, searchEventModelLoader)
                        latestFilter = finalString
                    }

                    searchEventModelLoader.active = true
                }
            } else {
                delegate.displayedEvent = null
                searchEventModelLoader.active = false
                found = true
            }

            delegate.height = found ? units.gu(8) : 0
            delegate.visible = found ? true : false
        }

        // WORKAROUND: history-service can't filter by contact names
        Connections {
            target: delegate
            onSearchTermChanged: {
                delegateHelper.updateSearch()
            }
        }

        Loader {
            id: searchEventModelLoader
            active: false
            asynchronous: true
            sourceComponent: searchEventModelComponent
        }

        Component {
            id: searchEventModelComponent
            HistoryEventModel {
                id: eventModel
                type: HistoryThreadModel.EventTypeText
                filter: delegateHelper.searchHistoryFilter
                onCountChanged: {
                    if (count > 0) {
                        delegate.height = units.gu(8)
                        delegate.visible = true
                        delegate.displayedEvent = eventModel.get(0)
                    } else if (searchTerm == "") {
                        delegate.height = units.gu(8)
                        delegate.visible = true
                        delegate.displayedEvent = null
                    } else {
                        delegate.displayedEvent = null
                        delegate.height = 0
                    }
                }
            }
        }

        // FIXME: there is another instance of PresenceRequest in Messages.qml,
        // we have to reuse the same instance when possible
        PresenceRequest {
            id: presenceRequest
            accountId: {
                // if this is a regular sms chat, try requesting the presence on
                // a multimedia account
                if (!telepathyHelper.ready) {
                    return ""
                }
                var account = telepathyHelper.accountForId(model.accountId)
                if (!account) {
                    return ""
                }
                if (account.type == AccountEntry.PhoneAccount) {
                    var accounts = telepathyHelper.accountOverload(account)
                    for (var i in accounts) {
                        var tmpAccount = accounts[i]
                        if (tmpAccount.active) {
                            return tmpAccount.accountId
                        }
                    }
                    return ""
                }
                return account.accountId
            }
            // we just request presence on 1-1 chats
            identifier: !groupChat ? participant.identifier : ""
        }

        function updateSubTypeLabel() {
            var subLabel = "";
            if (participant && participant.phoneNumber) {
                var typeInfo = phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail))
                if (typeInfo) {
                    subLabel = typeInfo.label
                }
            }
            phoneNumberSubTypeLabel = subLabel
        }

        onSubTypesChanged: updateSubTypeLabel();
        onContextsChanged: updateSubTypeLabel();
        onIsUnknownChanged: updateSubTypeLabel();

        PhoneNumber {
            id: phoneDetail
            contexts: participant && participant.phoneContexts ? participant.phoneContexts : []
            subTypes: participant && participant.phoneSubTypes ? participant.phoneSubTypes : []
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
        }
    }
}
