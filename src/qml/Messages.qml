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

import QtQuick 2.2
import QtQuick.Window 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import messagingapp.private 0.1

import "dateUtils.js" as DateUtils

Page {
    id: messages
    objectName: "messagesPage"

    // this property can be overriden by the user using the account switcher,
    // in the suru divider
    property string accountId: ""
    property var threadId: threads.length > 0 ? threads[0].threadId : ""
    property int chatType: threads.length > 0 ? threads[0].chatType : HistoryThreadModel.ChatTypeNone
    property QtObject account: getCurrentAccount()
    property variant participants: {
        if (chatEntry.active) {
            return chatEntry.participants
        } else if (threads.length > 0) {
            return threads[0].participants
        }
        return []
    }
    property variant localPendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.localPendingParticipants
        } else if (threads.length > 0) {
            return threads[0].localPendingParticipants
        }
        return []
    }
    property variant remotePendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.remotePendingParticipants
        } else if (threads.length > 0) {
            return threads[0].remotePendingParticipants
        }
        return []
    }
    property variant participantIds: {
        var ids = []
        for (var i in participants) {
            ids.push(participants[i].identifier)
        }
        return ids
    }
    property bool groupChat: chatType == HistoryThreadModel.ChatTypeRoom || participants.length > 1
    property bool keyboardFocus: true
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property var sharedAttachmentsTransfer: []
    property alias contactWatcher: contactWatcherInternal
    property string text: ""
    property string scrollToEventId: ""
    property bool isSearching: scrollToEventId !== ""
    property string latestEventId: ""
    property var pendingEventsToMarkAsRead: []
    property bool reloadFilters: false
    // to be used by tests as variant does not work with autopilot
    property bool userTyping: false
    property string userTypingId: ""
    property string firstParticipantId: participantIds.length > 0 ? participantIds[0] : ""
    property variant firstParticipant: participants.length > 0 ? participants[0] : null
    property var threads: []
    property QtObject presenceRequest: presenceItem
    property var accountsModel: getAccountsModel()
    property alias oskEnabled: keyboard.oskEnabled
    property bool isReady: false
    property QtObject chatEntry: chatEntryObject
    property string firstRecipientAlias: ((contactWatcher.isUnknown &&
                                           contactWatcher.isInteractive) ||
                                          contactWatcher.alias === "") ? contactWatcher.identifier : contactWatcher.alias
    property bool newMessage: false
    property var lastTypingTimestamp: 0

    signal ready
    signal cancel

    function restoreBindings() {
        messages.account = Qt.binding(getCurrentAccount)
        headerSections.selectedIndex = Qt.binding(getSelectedIndex)
    }

    function getAccountsModel() {
        // on chat rooms we don't give the option to switch to another account
        var tmpAccount = telepathyHelper.accountForId(messages.accountId)
        if (!newMessage && tmpAccount && tmpAccount.type != AccountEntry.PhoneAccount && messages.chatType == HistoryThreadModel.ChatTypeRoom) {
            return [tmpAccount]
        }

        // show only the text accounts meant to be displayed
        return telepathyHelper.textAccounts.displayed
    }

    function getSectionsModel() {
        var accountNames = []
        // suru divider must be empty if there is only one account
        for (var i in messages.accountsModel) {
            accountNames.push(messages.accountsModel[i].displayName)
        }
        return accountNames.length > 1 ? accountNames : []
    }

    function getSelectedIndex() {
        if (newMessage) {
            // if this is a new message, just pre select the the 
            // default phone account for messages if available
            if (multiplePhoneAccounts && telepathyHelper.defaultMessagingAccount) {
                for (var i in messages.accountsModel) {
                    if (telepathyHelper.defaultMessagingAccount == messages.accountsModel[i]) {
                        return i
                    }
                }
            }
        }

        // if we get here, just pre-select the account that is set in messages.account
        return accountIndex(messages.account)
    }

    function accountIndex(account) {
        var index = -1;
        for (var i in messages.accountsModel) {
            if (messages.accountsModel[i] == account) {
                index = i;
                break;
            }
        }
        return index;
    }

    function getCurrentAccount() {
        if (messages.accountId !== "") {
            var tmpAccount = telepathyHelper.accountForId(messages.accountId)
            // if the selected account is a phone account, check if there is a default
            // phone account for messages
            if (tmpAccount && tmpAccount.type == AccountEntry.PhoneAccount) {
                if (multiplePhoneAccounts) {
                    return telepathyHelper.defaultMessagingAccount
                } else {
                    for (var i in messages.accountsModel) {
                        if (messages.accountsModel[i].type == AccountEntry.PhoneAccount) {
                            return messages.accountsModel[i]
                        }
                    }
                }
                return null
            }
            for (var i in messages.accountsModel) {
                if (tmpAccount.accountId == messages.accountId) {
                    return tmpAccount
                }
            }
            return null
        } else {
            return mainView.account
        }
    }

    function addNewThreadToFilter(newAccountId, properties) {
        var newAccount = telepathyHelper.accountForId(newAccountId)
        var matchType = HistoryThreadModel.MatchCaseSensitive
        // if the addressable fields contains "tel", assume we should do phone match
        if (newAccount.addressableVCardFields.find("tel")) {
            console.log("addNewThreadToFilter: matching phone number for account " + newAccount.accountId)
            matchType = HistoryThreadModel.MatchPhoneNumber
        }

        var thread = eventModel.threadForProperties(newAccountId,
                                           HistoryThreadModel.EventTypeText,
                                           properties,
                                           matchType,
                                           true)
        if (thread.length == 0) {
            return thread
        } 
        var threadId = thread.threadId

        // dont change the participants list
        if (!messages.participants || messages.participants.length == 0) {
            messages.participants = thread.participants
            var ids = []
            for (var i in messages.participants) {
                ids.push(messages.participants[i].identifier)
            }
            messages.participantIds = ids;
        }

        var found = false;
        for (var i in messages.threads) {
            if (messages.threads[i].threadId == threadId && messages.threads[i].accountId == newAccountId) {
                found = true;
                break;
            }
        }

        if (!found) {
            messages.threads.push(thread)
            reloadFilters = !reloadFilters
        }

        return thread
    }

    function sendMessageNetworkCheck() {
        if (messages.account.simLocked) {
            Qt.inputMethod.hide()
            // workaround for bug #1461861
            messages.focus = false
            PopupUtils.open(Qt.createComponent("Dialogs/SimLockedDialog.qml").createObject(messages))
            return false
        }

        if (!messages.account.connected) {
            Qt.inputMethod.hide()
            // workaround for bug #1461861
            messages.focus = false
            PopupUtils.open(noNetworkDialogComponent)
            return false
        }

        return true
    }

    function checkSelectedAccount() {
        if (!messages.account) {
            Qt.inputMethod.hide()
            // workaround for bug #1461861
            messages.focus = false
            var properties = {}

            if (telepathyHelper.flightMode) {
                properties["title"] = i18n.tr("You have to disable flight mode")
                properties["text"] = i18n.tr("It is not possible to send messages in flight mode")
            } else if (multiplePhoneAccounts) {
                properties["title"] = i18n.tr("No SIM card selected")
                properties["text"] = i18n.tr("You need to select a SIM card")
            } else if (telepathyHelper.phoneAccounts.all.length > 0 && telepathyHelper.phoneAccounts.active.length == 0) {
                properties["title"] = i18n.tr("No SIM card")
                properties["text"] = i18n.tr("Please insert a SIM card and try again.")
            } else {
                properties["text"] = i18n.tr("Failed")
                properties["title"] = i18n.tr("It is not possible to send messages at the moment")
            }
            PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, properties)
            return false
        }
        if (messages.account.type == AccountEntry.PhoneAccount) {
            return sendMessageNetworkCheck()
        }
        if (!messages.account.connected) {
            var properties = {}
            properties["title"] = i18n.tr("Not available")
            properties["text"] = i18n.tr("The selected account is not available at the moment")
            PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, properties)
            return false
        }
        return true
    }

    // FIXME: support more stuff than just phone number
    function onContactPickedDuringSearch(identifier, displayName, avatar) {
        multiRecipient.addRecipient(identifier)
        multiRecipient.clearSearch()
        multiRecipient.forceActiveFocus()
    }

    function sendMessage(text, participantIds, attachments, properties) {
        if (typeof(properties) === 'undefined') {
            properties = {}
        }

        // check if at least one account is selected
        if (!messages.account) {
            Qt.inputMethod.hide()
            // workaround for bug #1461861
            messages.focus = false
            var properties = {}

            if (telepathyHelper.flightMode) {
                properties["title"] = i18n.tr("You have to disable flight mode")
                properties["text"] = i18n.tr("It is not possible to send messages in flight mode")
            } else if (multiplePhoneAccounts) {
                properties["title"] = i18n.tr("No SIM card selected")
                properties["text"] = i18n.tr("You need to select a SIM card")
            } else if (telepathyHelper.phoneAccounts.all.length > 0 && telepathyHelper.phoneAccounts.active.length == 0) {
                properties["title"] = i18n.tr("No SIM card")
                properties["text"] = i18n.tr("Please insert a SIM card and try again.")
            } else {
                properties["text"] = i18n.tr("It is not possible to send the message")
                properties["title"] = i18n.tr("Failed to send the message")
            }
            PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, properties)
            return false
        }

        if (messages.threads.length > 0) {
            properties["chatType"] = messages.chatType
            properties["threadId"] = messages.threadId
        } else if (properties["chatType"]) {
            messages.chatType = properties["chatType"]
        }

        var newParticipantsIds = []
        for (var i in participantIds) {
            newParticipantsIds.push(String(participantIds[i]))
        }

        // fallback chatType to Contact
        if (newParticipantsIds.length == 1 && messages.chatType == HistoryThreadModel.ChatTypeNone) {
            messages.chatType = HistoryThreadModel.ChatTypeContact
        }

        properties["chatType"] = messages.chatType
        properties["participantIds"] = newParticipantsIds
        if (messages.threadId !== "") {
            properties["threadId"] = messages.threadId
        }

        for (var i=0; i < eventModel.count; i++) {
            var event = eventModel.get(i)
            if (event.senderId == "self" && event.accountId != messages.account.accountId) {
                var tmpAccount = telepathyHelper.accountForId(event.accountId)
                if (!tmpAccount || (tmpAccount.type != AccountEntry.PhoneAccount && messages.account.type == AccountEntry.PhoneAccount)) {
                    // we don't add the information event if the last outgoing message
                    // was a fallback to a multimedia service
                    break;
                }
                // if the last outgoing message used a different accountId, add an
                // information event and quit the loop
                eventModel.writeTextInformationEvent(messages.account.accountId,
                                                     thread.threadId,
                                                     newParticipantsIds,
                                                     "")
                break;
            } else if (event.senderId == "self" && event.accountId == messages.account.accountId) {
                // in case last ougoing event used the same accountId, just skip
                break;
            }
        }

        if (!sendMessageNetworkCheck()) {
            // we can't simply send the message as the handler checks for
            // connection state. while this is not fixed, we generate the event here
            // and insert it into the history service
            var event = {}
            var timestamp = new Date()
            var tmpEventId = timestamp.toISOString()
            event["accountId"] = messages.account.accountId
            event["threadId"] = thread.threadId
            event["eventId"] =  tmpEventId
            event["type"] = HistoryEventModel.MessageTypeText
            event["participants"] = thread.participants
            event["senderId"] = "self"
            event["timestamp"] = timestamp
            event["newEvent"] = false
            event["message"] = text
            event["messageStatus"] = HistoryEventModel.MessageStatusPermanentlyFailed
            event["readTimestamp"] = timestamp;
            event["subject"] = ""; // we dont support subject yet
            if (attachments.length > 0) {
                event["messageType"] = HistoryEventModel.MessageTypeMultiPart
                var newAttachments = []
                for (var i = 0; i < attachments.length; i++) {
                    var attachment = {}
                    var item = attachments[i]
                    attachment["accountId"] = messages.account.accountId
                    attachment["threadId"] = thread.threadId
                    attachment["eventId"] = tmpEventId
                    attachment["attachmentId"] = item[0]
                    attachment["contentType"] = item[1]
                    attachment["filePath"] = item[2]
                    attachment["status"] = HistoryEventModel.AttachmentDownloaded
                    newAttachments.push(attachment)
                }
                event["attachments"] = newAttachments
            } else {
                event["messageType"] = HistoryEventModel.MessageTypeText
            }
            eventModel.writeEvents([event]);
        } else {
            // FIXME: we need to change the way of detecting MMS group chat
            var isMmsGroupChat = newParticipantsIds.length > 1 && telepathyHelper.mmsGroupChat && messages.account.type == AccountEntry.PhoneAccount
            // mms group chat only works if we know our own phone number
            var isSelfContactKnown = account.selfContactId != ""
            if (isMmsGroupChat && !isSelfContactKnown) {
                // TODO: inform the user to enter the phone number of the selected sim card manually
                // and use it in the telepathy-ofono account as selfContactId.
                return false
            }
            messages.chatEntry.sendMessage(messages.account.accountId, text, attachments, properties)
            messages.chatEntry.setChatState(ChatEntry.ChannelChatStateActive)
            selfTypingTimer.stop()
        }

        if (newMessage) {
            newMessage = false
            var currentIndex = headerSections.selectedIndex
            headerSections.model = getSectionsModel()
            restoreBindings()
            // dont restore index if this is a chatroom
            if (messages.chatType != HistoryThreadModel.ChatTypeRoom) {
                headerSections.selectedIndex = currentIndex
            }
        }

        // FIXME: soon it won't be just about SIM cards, so the dialogs need updating
        if (multiplePhoneAccounts && !telepathyHelper.defaultMessagingAccount && !settings.messagesDontAsk && account.type == AccountEntry.PhoneAccount) {
            Qt.inputMethod.hide()
            PopupUtils.open(Qt.createComponent("Dialogs/SetDefaultSIMCardDialog.qml").createObject(messages))
        } else {
            // FIXME: We only show the swipe tutorial after select the default sim card to avoid problems with the dialog
            // Since the dialog will be removed soon we do not expend time refactoring the code to make it visible after the dialog
            swipeItemDemo.enable()
        }

        return true
    }

    function updateFilters(accounts, chatType, participantIds, reload, threads) {
        console.log(accounts, chatType, participantIds.length, reload, threads.length)
        if (participantIds.length == 0 || accounts.length == 0) {
            if (chatType != HistoryThreadModel.ChatTypeRoom) {
                return null
            }
        }

        var componentUnion = "import Ubuntu.History 0.1; HistoryUnionFilter { %1 }"
        var componentFilters = ""
        if (threads.length > 0) {
            for (var i in threads) {
                var filterAccountId = 'HistoryFilter { property string value: "%1"; filterProperty: "accountId"; filterValue: value }'.arg(threads[i].accountId)
                var filterThreadId = 'HistoryFilter { property string value: "%1"; filterProperty: "threadId"; filterValue: value }'.arg(threads[i].threadId)
                componentFilters += 'HistoryIntersectionFilter { %1 %2 } '.arg(filterAccountId).arg(filterThreadId)
            }
            return Qt.createQmlObject(componentUnion.arg(componentFilters), eventModel)
        }

        // if we have all info but not threads, we force the filter generation
        if (messages.chatType == HistoryThreadModel.ChatTypeRoom && messages.threadId !== "" && messages.accountId !== "") {
            var filterAccountId = 'HistoryFilter { property string value: "%1"; filterProperty: "accountId"; filterValue: value }'.arg(messages.accountId)
            var filterThreadId = 'HistoryFilter { property string value: "%1"; filterProperty: "threadId"; filterValue: value }'.arg(messages.threadId)
            componentFilters += 'HistoryIntersectionFilter { %1 %2 } '.arg(filterAccountId).arg(filterThreadId)
            return Qt.createQmlObject(componentUnion.arg(componentFilters), eventModel)
        }

        var filterAccounts = []

        for (var i in accounts) {
            var account = accounts[i]
            filterAccounts.push(account)
        }

        for (var i in filterAccounts) {
            var account = filterAccounts[i];
            var filterValue = eventModel.threadIdForParticipants(account.accountId,
                                                                 HistoryThreadModel.EventTypeText,
                                                                 participantIds,
                                                                 account.addressableVCardFields.find("tel") ? HistoryThreadModel.MatchPhoneNumber
                                                                                                            : HistoryThreadModel.MatchCaseSensitive);
            if (filterValue === "") {
                continue
            }
            // WORKAROUND: we don't set value directly to filterValue otherwise strings matching color names
            // will be converted to QColor
            componentFilters += 'HistoryFilter { property string value: "%1"; filterProperty: "threadId"; filterValue: value } '.arg(filterValue)
        }
        if (componentFilters === "") {
            return null
        }
        console.log("BLABLA component filters: " + componentFilters)
        return Qt.createQmlObject(componentUnion.arg(componentFilters), eventModel)
    }

    function markMessageAsRead(accountId, threadId, eventId, type) {
        var pendingEvent = {"accountId": accountId, "threadId": threadId, "messageId": eventId, "type": type, "chatType": messages.chatType, 'participantIds': messages.participantIds}
        if (!mainView.applicationActive || !messages.active) {
           pendingEventsToMarkAsRead.push(pendingEvent)
           return false
        }
        chatManager.acknowledgeMessage(pendingEvent)
        return eventModel.markEventAsRead(accountId, threadId, eventId, type);
    }

    function processPendingEvents() {
        if (mainView.applicationActive && messages.active) {
            for (var i in pendingEventsToMarkAsRead) {
                var event = pendingEventsToMarkAsRead[i]
                markMessageAsRead(event.accountId, event.threadId, event.messageId, event.type)
            }
            pendingEventsToMarkAsRead = []
        }
    }

    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        title: {
            if (landscape) {
                return ""
            }

            if (participants.length == 1) {
                return firstRecipientAlias
            }

            return " "
        }
        flickable: null

        Sections {
            id: headerSections
            objectName: "headerSections"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            visible: headerSections.model.length > 1
            enabled: visible
            model: getSectionsModel()
            selectedIndex: getSelectedIndex()
            onSelectedIndexChanged: {
                if (selectedIndex >= 0) {
                    messages.account = messages.accountsModel[selectedIndex]
                }
            }
            // force break the binding, so the index doesn't get reset
            Component.onCompleted: model = getSectionsModel()
        }

        extension: headerSections.model.length > 1 ? headerSections : null

        leadingActionBar {
            id: leadingBar
        }

        trailingActionBar {
            id: trailingBar
        }

        Item {
            id: trailingActionArea
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
        }
    }

    states: [
        State {
            id: selectionState
            name: "selection"
            when: selectionMode

            property list<QtObject> leadingActions: [
                Action {
                    objectName: "selectionModeCancelAction"
                    iconName: "back"
                    onTriggered: messageList.cancelSelection()
                }
            ]

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "selectionModeSelectAllAction"
                    iconName: "select"
                    onTriggered: {
                        if (messageList.selectedItems.count === messageList.count) {
                            messageList.clearSelection()
                        } else {
                            messageList.selectAll()
                        }
                    }
                },
                Action {
                    objectName: "selectionModeDeleteAction"
                    enabled: messageList.selectedItems.count > 0
                    iconName: "delete"
                    onTriggered: messageList.endSelection()
                },
                Action {
                    objectName: "selectionModeForwardAction"
                    enabled: messageList.selectedItems.count > 0
                    iconName: "mail-forward"
                    onTriggered: messageList.shareSelectedMessages()
                }
            ]

            PropertyChanges {
                target: pageHeader
                title: " "
                leadingActions: selectionState.leadingActions
                trailingActions: selectionState.trailingActions
            }
        },
        State {
            id: groupChatState
            name: "groupChat"
            when: groupChat

            property list<QtObject> trailingActions: [
                Action {
                    id: groupChatAction
                    objectName: "groupChatAction"
                    iconName: "contact-group"
                    onTriggered: mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("GroupChatInfoPage.qml"), { threads: threadInformation.threads, chatEntry: messages.chatEntry, eventModel: eventModel})
                }
            ]

            PropertyChanges {
                target: pageHeader
                // TRANSLATORS: %1 refers to the number of participants in a group chat
                title: {
                    if (messages.chatType == HistoryThreadModel.ChatTypeRoom) {
                        if (chatEntry.title !== "") {
                            return chatEntry.title
                        }
                        var roomInfo = threadInformation.chatRoomInfo
                        if (roomInfo.Title != "") {
                            return roomInfo.Title
                        } else if (roomInfo.RoomName != "") {
                            return roomInfo.RoomName
                        } else {
                            return i18n.tr("Group")
                        }
                    } else {
                        return i18n.tr("Group (%1)").arg(participants.length)
                    }
                }
                contents: headerContents
                trailingActions: groupChatState.trailingActions
            }
        },
        State {
            id: unknownContactState
            name: "unknownContact"
            when: participants.length == 1 && contactWatcher.isUnknown

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "contactCallAction"
                    visible: participants.length == 1 && contactWatcher.interactive
                    iconName: "call-start"
                    text: i18n.tr("Call")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        // FIXME: support other things than just phone numbers
                        Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.identifier))
                    }
                },
                Action {
                    objectName: "addContactAction"
                    visible: contactWatcher.isUnknown && participants.length == 1 && contactWatcher.interactive
                    iconName: "contact-new"
                    text: i18n.tr("Add")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        // FIXME: support other things than just phone numbers
                        mainView.addPhoneToContact(messages, "", contactWatcher.identifier, null, null)
                    }
                }
            ]
            PropertyChanges {
                target: pageHeader
                contents: headerContents
                trailingActions: unknownContactState.trailingActions
            }
        },
        State {
            id: newMessageState
            // NOTE: in case the state name is changed here, the bottom edge component needs
            // to be updated too
            name: "newMessage"
            when: messages.newMessage

            property list<QtObject> trailingActions: [
                Action {
                    id: groupSelectionAction
                    objectName: "groupSelection"
                    iconName: "contact-group"
                    onTriggered: {
                        Qt.inputMethod.hide()
                        if (!checkSelectedAccount()) {
                            return
                        }

                        // check if we support more than one kind of group
                        var multipleGroupTypes = false
                        for (var i in telepathyHelper.textAccounts.active) {
                            var account = telepathyHelper.textAccounts.active[i]
                            if (account.type != AccountEntry.PhoneAccount) {
                                multipleGroupTypes = true
                                break
                            }
                        }

                        if (!multipleGroupTypes) {
                            // FIXME: remove that: now that creating an MMS group is an explicit action we don't need to have a settings for that
                            if (!telepathyHelper.mmsGroupChat) {
                                application.showNotificationMessage(i18n.tr("You need to enable MMS group chat in the app settings"), "contact-group")
                                return
                            }
                            mainStack.addPageToCurrentColumn(messages,  Qt.resolvedUrl("NewGroupPage.qml"), {"participants": multiRecipient.participants, "account": messages.account})
                            return
                        }
                        contextMenu.caller = header;
                        contextMenu.updateGroupTypes();
                        contextMenu.show();
                    }
                }
            ]

            property Item contents: MultiRecipientInput {
                id: multiRecipient
                objectName: "multiRecipient"
                enabled: visible
                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                    rightMargin: units.gu(2)
                    top: parent ? parent.top: undefined
                    topMargin: units.gu(1)
                }

                Icon {
                    name: "add"
                    height: units.gu(2)
                    anchors {
                        right: parent.right
                        rightMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Qt.inputMethod.hide()
                            mainStack.addPageToCurrentColumn(messages,  Qt.resolvedUrl("NewRecipientPage.qml"), {"itemCallback": multiRecipient})
                        }
                        z: 2
                    }
                }

                Connections {
                    target: mainView.bottomEdge
                    onStatusChanged: {
                        if (mainView.bottomEdge.status === BottomEdge.Committed) {
                            multiRecipient.forceFocus()
                        }
                    }
                }
            }

            PropertyChanges {
                target: pageHeader
                title: " "
                trailingActions: newMessageState.trailingActions
                contents: newMessageState.contents
            }
        },
        State {
            id: knownContactState
            name: "knownContact"
            when: participants.length == 1 && !contactWatcher.isUnknown
            property list<QtObject> trailingActions: [
                Action {
                    objectName: "contactCallKnownAction"
                    visible: participants.length == 1
                    iconName: "call-start"
                    text: i18n.tr("Call")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        // FIXME: support other things than just phone numbers
                        Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.identifier))
                    }
                },
                Action {
                    objectName: "contactProfileAction"
                    visible: !contactWatcher.isUnknown && participants.length == 1
                    iconSource: "image://theme/contact"
                    text: i18n.tr("Contact")
                    onTriggered: {
                        mainView.showContactDetails(messages, contactWatcher.contactId, null, null)
                    }
                }
            ]
            PropertyChanges {
                target: pageHeader
                contents: headerContents
                trailingActions: knownContactState.trailingActions
            }
        }
    ]

    Component.onCompleted: {
        // we only revert back to phone account if this is a 1-1 chat,
        // in which case the handler will fallback to multimedia if needed
        if (messages.accountId !== "" && chatType !== HistoryThreadModel.ChatTypeRoom) {
            var account = telepathyHelper.accountForId(messages.accountId)

            // if the account is not supposed to be displayed, we check if it has a fallback
            if (account && !account.protocolInfo.showOnSelector) {
                // check if there is a fallback account to use
                var accounts = telepathyHelper.checkAccountFallback(account);
                if (accounts.length > 0) {
                    messages.accountId = accounts[0].accountId
                }
            }
        }
        newMessage = (messages.accountId == "" && messages.participants.length === 0)
        restoreBindings()
        if (threadId !== "" && accountId !== "" && threads.length == 0) {
            addNewThreadToFilter(accountId, {"threadId": threadId, "chatType": chatType})
        }
        // if we add multiple attachments at the same time, it break the Repeater + Loaders
        fillAttachmentsTimer.start()
        mainView.updateNewMessageStatus()
    }

    Component.onDestruction: {
        newMessage = false
        active = false
        mainView.updateNewMessageStatus()
    }

    Timer {
        id: selfTypingTimer
        interval: 15000
        onTriggered: {
            if (composeBar.text != "" || composeBar.inputMethodComposing) {
                messages.chatEntry.setChatState(ChatEntry.ChannelChatStatePaused)
            } else {
                messages.chatEntry.setChatState(ChatEntry.ChannelChatStateActive)
            }
        }
    }

    Timer {
        id: fillAttachmentsTimer
        interval: 50
        onTriggered: composeBar.addAttachments(sharedAttachmentsTransfer)
    }

    onReady: {
        isReady = true
        if (participants.length === 0 && keyboardFocus)
            multiRecipient.forceFocus()
    }

    onActiveChanged: {
        if (active && (eventModel.count > 0)){
            swipeItemDemo.enable()
        }
        mainView.updateNewMessageStatus()
        if (!isReady) {
            messages.ready()
        }
        processPendingEvents()
    }

    // These fake items are used to track if there are instances loaded
    // on the second column because we have no access to the page stack
    Item {
        objectName:"fakeItem"
    }

    ActionSelectionPopover {
        id: contextMenu
        z: 100

        delegate: ListItem.Standard {
            text: action.text
        }
        actions: ActionList {
            id: actionList
        }

        Action {
            id: mmsGroupAction
            text: i18n.tr("Create MMS Group...")
            onTriggered: {
                // FIXME: remove that, there is no need to have a MMS group chat option anymore
                if (!telepathyHelper.mmsGroupChat) {
                    var properties = {}
                    properties["title"] = i18n.tr("MMS group chat is disabled")
                    properties["text"] = i18n.tr("You need to enable MMS group chat in the app settings")
                    PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, properties)
                    return
                }
                mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("NewGroupPage.qml"), {"participants": multiRecipient.participants, "account": messages.account})
            }
        }

        Repeater {
            id: otherGroupsRepeater
            model: telepathyHelper.textAccounts.active

            Action {
                text: {
                    var protocolDisplayName = modelData.protocolInfo.serviceDisplayName;
                    if (protocolDisplayName === "") {
                       protocolDisplayName = modelData.protocolInfo.serviceName;
                    }
                    return i18n.tr("Create %1 Group...").arg(protocolDisplayName);
                }
                // FIXME: this multimedia: true property needs to be replaced by the accountId
                onTriggered: mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("NewGroupPage.qml"), {"multimedia": true, "participants": multiRecipient.participants, "account": modelData})
                visible: modelData.type != AccountEntry.PhoneAccount
            }
        }

        function updateGroupTypes() {
            actionList.actions = []
            actionList.addAction(mmsGroupAction)

            for (var i in otherGroupsRepeater.children) {
                actionList.addAction(otherGroupsRepeater.children[i])
            }
        }
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            // force reevaluation
            if (threads.length == 0) {
                var properties = {"chatType": chatType,
                                  "accountId": accountId,
                                  "threadId": threadId,
                                  "participantIds": participantIds}
                messages.threads = getThreadsForProperties(properties)
            }
            messages.reloadFilters = !messages.reloadFilters
            headerSections.model = getSectionsModel()
            restoreBindings()
        }
    }

    // this is necessary to automatically update the view when the
    // default account changes in system settings
    Connections {
        target: mainView
        onAccountChanged: {
            messages.account = mainView.account
            headerSections.selectedIndex = getSelectedIndex()
        }

        onApplicationActiveChanged: {
            processPendingEvents()
        }
    }

    Timer {
        id: typingTimer
        interval: 15000
        onTriggered: {
            messages.userTyping = false;
        }
    }

    ChatEntry {
        id: chatEntryObject
        chatType: messages.chatType
        participantIds: messages.participantIds
        chatId: messages.threadId
        accountId: messages.accountId
        autoRequest: !newMessage

        onChatTypeChanged: {
            messages.chatType = chatEntryObject.chatType
        }

        onMessageSent: {
            // create the new thread and update the threadId list
            if (accountId != messages.account.accountId ||
                messages.threads.length === 0) {
                addNewThreadToFilter(accountId, properties)
            }
        }
        onMessageSendingFailed: {
            // create the new thread and update the threadId list
            if (accountId != messages.account.accountId ||
                messages.threads.length === 0) {
                addNewThreadToFilter(accountId, properties)
            }
        }
    }

    Repeater {
        model: messages.chatEntry.chatStates
        Item {
            function processChatState() {
                if (modelData.state == ChatEntry.ChannelChatStateComposing) {
                    messages.userTyping = true
                    messages.userTypingId = modelData.contactId
                    typingTimer.restart()
                } else {
                    messages.userTyping = false
                }
            }
            Component.onCompleted: processChatState()
            Connections {
                target: modelData
                onStateChanged: processChatState()
            }
        }
    }

    ContactWatcher {
        id: typingContactWatcher
        identifier: messages.userTypingId
        addressableFields: messages.account ? messages.account.addressableVCardFields : ["tel"] // just to have a fallback there
    }

    MessagesHeader {
        id: headerContents
        width: parent ? parent.width - units.gu(2) : undefined
        height: units.gu(5)
        title: pageHeader.title
        subtitle: {
            if (userTyping) {
                if (groupChat) {
                    var contactAlias = typingContactWatcher.alias != "" ? typingContactWatcher.alias : typingContactWatcher.identifier
                    return i18n.tr("%1 is typing..").arg(contactAlias)
                } else {
                    return i18n.tr("Typing..")
                }
            }
            var presenceAccount = telepathyHelper.accountForId(presenceRequest.accountId)
            if (!presenceAccount || !presenceAccount.protocolInfo.showOnlineStatus) {
                return ""
            }
            switch (presenceRequest.type) {
            case PresenceRequest.PresenceTypeAvailable:
                return i18n.tr("Online")
            case PresenceRequest.PresenceTypeOffline:
                return i18n.tr("Offline")
            case PresenceRequest.PresenceTypeAway:
                return i18n.tr("Away")
            case PresenceRequest.PresenceTypeBusy:
                return i18n.tr("Busy")
            default:
                return ""
            }
        }
        visible: true
    }

    PresenceRequest {
        id: presenceItem
        accountId: {
            // if this is a regular sms chat, try requesting the presence on
            // a multimedia account
            if (!account || chatType != HistoryThreadModel.ChatTypeContact) {
                return ""
            }
            // FIXME: for accounts that we don't want to show the online status, we have to check if the overloaded account
            // might be available for that. If that account should not use the
            if (account.type == AccountEntry.PhoneAccount) {
                var accounts = telepathyHelper.checkAccountOverload(account)
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
        identifier: participants.length == 1 ? participants[0].identifier : ""
    }

    ActivityIndicator {
        id: activityIndicator
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        running: isSearching
        visible: running
    }

    Component {
        id: noNetworkDialogComponent
        Dialog {
            id: noNetworkDialog
            objectName: "noNetworkDialog"
            title: i18n.tr("No network")
            text: multiplePhoneAccounts ? i18n.tr("There is currently no network on %1").arg(messages.account.displayName) : i18n.tr("There is currently no network.")
            Button {
                objectName: "closeNoNetworkDialog"
                text: i18n.tr("Close")
                color: UbuntuColors.orange
                onClicked: {
                    PopupUtils.close(noNetworkDialog)
                    Qt.inputMethod.hide()
                }
            }
        }
    }

    Loader {
        id: searchListLoader

        property int resultCount: (status === Loader.Ready) ? item.count : 0

        source: (multiRecipient.searchString !== "") && multiRecipient.focus ?
                Qt.resolvedUrl("ContactSearchList.qml") : ""
        clip: true
        visible: source != ""
        anchors {
            top: parent.top
            topMargin: header.height
            left: parent.left
            right: parent.right
            bottom: chatInactiveLabel.top
        }

        z: 1
        Behavior on height {
            UbuntuNumberAnimation { }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.palette.normal.background
        }

        Binding {
            target: searchListLoader.item
            property: "filterTerm"
            value: multiRecipient.searchString
            when: (searchListLoader.status === Loader.Ready)
        }

        Timer {
            id: checkHeight

            interval: 300
            repeat: false
            onTriggered: {
                searchListLoader.height = searchListLoader.resultCount > 0 ? searchListLoader.parent.height - keyboard.height : 0
            }
        }

        onStatusChanged: {
            if (status === Loader.Ready) {
                item.contactPicked.connect(messages.onContactPickedDuringSearch)
            }
        }

        // WORKAROUND: Contact model get all contacts removed in every search, to avoid the view to blick
        // we will wait some msecs before reduce the size to 0 to confirm that there is no results on the view
        onResultCountChanged: {
            if (searchListLoader.resultCount > 0) {
                searchListLoader.height = searchListLoader.parent.height - keyboard.height
            } else {
                checkHeight.restart()
            }
        }

    }

    ContactWatcher {
        id: contactWatcherInternal
        identifier: firstParticipant ? firstParticipant.identifier : ""
        contactId: firstParticipant ? firstParticipant.contactId : ""
        alias: firstParticipant ? firstParticipant.alias : ""
        avatar: firstParticipant ? firstParticipant.avatar : ""
        detailProperties: firstParticipant ? firstParticipant.detailProperties : {}
        addressableFields: messages.account ? messages.account.addressableVCardFields : ["tel"] // just to have a fallback there
    }

    HistoryUnionFilter {
        id: filters
        HistoryIntersectionFilter { 
            HistoryFilter { filterProperty: "accountId"; filterValue: messages.accountId }
            HistoryFilter { filterProperty: "threadId"; filterValue: messages.threadId }
        }
    }

    HistoryGroupedThreadsModel {
        id: threadsModel
        type: HistoryThreadModel.EventTypeText
        sort: HistorySort {}
        groupingProperty: "participants"
        filter: messages.accountId != "" && messages.threadId != "" ? filters : null
        matchContacts: true
    }

    ListView {
        id: threadInformation
        property var chatRoomInfo: null
        property var participants: null
        property var threads: null
        model: threadsModel
        visible: false
        delegate: Item {
            property var threads: model.threads
            onThreadsChanged: {
                threadInformation.chatRoomInfo = model.threads[0].chatRoomInfo
                threadInformation.participants = model.threads[0].participants
                threadInformation.threads = model.threads
            }
        }
    }

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: updateFilters(telepathyHelper.textAccounts.all, messages.chatType, messages.participantIds, messages.reloadFilters, messages.threads)
        matchContacts: true
        sort: HistorySort {
           sortField: "timestamp"
           sortOrder: HistorySort.DescendingOrder
        }
        onCountChanged: {
            if (isSearching) {
                // if we ask for more items manually listview will stop working,
                // so we only set again once the item was found
                messageList.listModel = null
                // always check last 15 items
                var maxItems = 15
                for (var i = count-1; count >= i; i--) {
                    if (--maxItems < 0) {
                        break;
                    }
                    if (eventModel.get(i).eventId == scrollToEventId) {
                        scrollToEventId = ""
                        messageList.listModel = eventModel
                        messageList.positionViewAtIndex(i, ListView.Center)
                        return;
                    }
                }

                if (eventModel.canFetchMore && isSearching) {
                    fetchMoreTimer.running = true
                } else {
                    // event not found
                    scrollToEventId = ""
                    messageList.listModel = eventModel
                }
            }
        }
    }

    Timer {
       id: fetchMoreTimer
       running: false
       interval: 100
       repeat: false
       onTriggered: eventModel.fetchMore()
    }

    // this item is used as parent of the participants popup. using
    // messages.header as parent was hanging the app
    Item {
        id: screenTop
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
        }
        height: 0
    }

    MessagesListView {
        id: messageList
        objectName: "messageList"
        visible: !isSearching
        listModel: messages.newMessage ? null : eventModel

        Rectangle {
            color: Theme.palette.normal.background
            anchors.fill: parent
            Image {
                width: units.gu(20)
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                visible: source !== ""
                source: {
                    var accountId = ""

                    if (messages.account) {
                        accountId = messages.account.accountId
                    }

                    if (presenceRequest.type != PresenceRequest.PresenceTypeUnknown
                            && presenceRequest.type != PresenceRequest.PresenceTypeUnset) {
                        accountId = presenceRequest.accountId
                    }

                    return telepathyHelper.accountForId(accountId).protocolInfo.backgroundImage
                }
                z: 1
            }
            z: -1
        }

        // because of the header
        clip: true
        anchors {
            top: screenTop.bottom
            left: parent.left
            right: parent.right
            bottom: chatInactiveLabel.top
        }
    }

    Item {
        id: chatInactiveLabel
        height: visible ? units.gu(8) : 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: composeBar.top
        }
        ListItem.ThinDivider {
            anchors.top: parent.top
        }

        visible: {
            if (messages.newMessage || messages.chatType !== HistoryThreadModel.ChatTypeRoom) {
               return false
            }
            if (threads.length > 0) {
                return !threadInformation.chatRoomInfo.Joined
            }
            return false
        }
        Label {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: i18n.tr("You can't send messages to this group because the group is no longer active")
        }
    }

    ComposeBar {
        id: composeBar
        anchors {
            bottom: isSearching ? parent.bottom : keyboard.top
            left: parent.left
            right: parent.right
        }

        showContents: !selectionMode && !isSearching && !chatInactiveLabel.visible
        maxHeight: messages.height - keyboard.height - screenTop.y
        text: messages.text
        onTextChanged: {
            if (text == "" && !composeBar.inputMethodComposing) {
                messages.chatEntry.setChatState(ChatEntry.ChannelChatStateActive)
                selfTypingTimer.stop()
                return
            }
            var currentTimestamp = new Date().getTime()
            if (!selfTypingTimer.running) {
                messages.lastTypingTimestamp = currentTimestamp
                messages.chatEntry.setChatState(ChatEntry.ChannelChatStateComposing)
            } else {
                // if more than 8 seconds passed since last typing signal, then send another one
                if ((currentTimestamp - messages.lastTypingTimestamp) > 8000) {
                    messages.lastTypingTimestamp = currentTimestamp
                    messages.chatEntry.setChatState(ChatEntry.ChannelChatStateComposing)
                }
            }
            selfTypingTimer.restart()

        }
        canSend: chatType == 2 || participants.length > 0 || multiRecipient.recipientCount > 0 || multiRecipient.searchString !== ""
        oskEnabled: messages.oskEnabled
        usingMMS: (participantIds.length > 1 || multiRecipient.recipientCount > 1 ) && telepathyHelper.mmsGroupChat && messages.account.type == AccountEntry.PhoneAccount

        Component.onCompleted: {
            // if page is active, it means this is not a bottom edge page
            if (messages.active && messages.keyboardFocus && participants.length != 0) {
                forceFocus()
            }
        }

        onSendRequested: {
            // refresh the recipient list
            multiRecipient.focus = false

            if (messages.account && messages.accountId == "") {
                messages.accountId = messages.account.accountId
            }

            var newAttachments = []
            var videoSize = 0;
            for (var i = 0; i < attachments.count; i++) {
                var attachment = []
                var item = attachments.get(i)
                // we dont include smil files. they will be auto generated
                if (item.contentType.toLowerCase() === "application/smil") {
                    continue
                }
                if (startsWith(item.contentType.toLowerCase(),"video/")) {
                    videoSize += FileOperations.size(item.filePath)
                }
                attachment.push(item.name)
                attachment.push(item.contentType)
                attachment.push(item.filePath)
                newAttachments.push(attachment)
            }
            if (videoSize > 307200 && !settings.messagesDontShowFileSizeWarning) {
                // FIXME we are guessing here if the handler will try to send it over an overloaded account
                // FIXME: this should be revisited when changing the MMS group implementation
                var isPhone = (account && account.type == AccountEntry.PhoneAccount)
                if (isPhone) {
                    // check if an account overload might be used
                    var accounts = telepathyHelper.checkAccountOverload(account)
                    for (var i in accounts) {
                        var tmpAccount = accounts[i]
                        if (tmpAccount.active) {
                            isPhone = false
                        }
                    }
                }
 
                if (isPhone) {
                    PopupUtils.open(Qt.createComponent("Dialogs/FileSizeWarningDialog.qml").createObject(messages))
                }
            }

            var recipients = participantIds.length > 0 ? participantIds :
                                                         multiRecipient.recipients
            var properties = {}
            if (composeBar.audioAttached) {
                properties["x-canonical-tmp-files"] = true
            }

            // if sendMessage succeeds it means the message was either sent or
            // injected into the history service so the user can retry later
            if (sendMessage(text, recipients, newAttachments, properties)) {
                composeBar.reset()
            }
            if (eventModel.filter == null) {
                reloadFilters = !reloadFilters
            }
        }
    }

    KeyboardRectangle {
        id: keyboard
    }

    MessageInfoDialog {
        id: messageInfoDialog
    }

    SwipeItemDemo {
        id: swipeItemDemo
        objectName: "swipeItemDemo"

        property bool parentActive: messages.active

        parent: QuickUtils.rootItem(this)
        anchors.fill: parent
        onStatusChanged: {
            if (status === Loader.Ready) {
                Qt.inputMethod.hide()
            }
        }
    }

    Scrollbar {
        flickableItem: messageList
        align: Qt.AlignTrailing
    }
}
