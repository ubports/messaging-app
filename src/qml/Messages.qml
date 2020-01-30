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

    property bool multiplePhoneAccounts: mainView.multiplePhoneAccounts
    // this property can be overriden by the user using the account switcher,
    // in the suru divider
    property string accountId: ""
    property var threadId: threads.length > 0 ? threads[0].threadId : "UNKNOWN"
    property int chatType: threads.length > 0 ? threads[0].chatType : HistoryThreadModel.ChatTypeNone
    property QtObject account: getCurrentAccount()
    property variant participants: {
        if (threads.length > 0) {
            return threadInformation.participants
        } else if (chatEntry.active) {
            return chatEntry.participants
        }
        return []
    }
    property variant localPendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.localPendingParticipants
        } else if (threads.length > 0) {
            return threadInformation.localPendingParticipants
        }
        return []
    }
    property variant remotePendingParticipants: {
        if (chatEntry.active) {
            return chatEntry.remotePendingParticipants
        } else if (threads.length > 0) {
            return threadInformation.remotePendingParticipants
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
    property bool groupChat: chatType == HistoryThreadModel.ChatTypeRoom || (participants !== null && participants.length > 1)
    property bool keyboardFocus: true
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property var sharedAttachmentsTransfer: []
    property alias contactWatcher: contactWatcherInternal
    property string scrollToEventId: ""
    property bool isSearching: scrollToEventId !== ""
    property string latestEventId: ""
    property bool reloadFilters: false
    // to be used by tests as variant does not work with autopilot
    property bool userTyping: false
    property string userTypingId: ""
    property string firstParticipantId: participantIds.length > 0 ? participantIds[0] : ""
    property variant firstParticipant: {
        if (!participants || participants.length == 0) {
            return null
        }
        var participant = participants[0]
        if (typeof participant === "string") {
            return {identifier: participant, alias: participant}
        } else {
            return participant
        }
    }

    property var threads: []
    property QtObject presenceRequest: presenceItem
    property var accountsModel: getAccountsModel()
    property alias oskEnabled: keyboard.oskEnabled
    property bool isReady: false
    property QtObject chatEntry
    property string firstRecipientAlias: ((contactWatcher.isUnknown &&
                                           contactWatcher.isInteractive) ||
                                          contactWatcher.alias === "") ? contactWatcher.identifier : contactWatcher.alias
    property bool newMessage: false
    property var lastTypingTimestamp: 0

    property bool isBroadcast: chatType != ChatEntry.ChatTypeRoom && (participantIds.length  > 1 || multiRecipient.recipientCount > 1)

    property alias validator: sendMessageValidator
    property string chatTitle: {
        if (chatEntry.title !== "") {
            return chatEntry.title
        }
        var roomInfo = threadInformation.chatRoomInfo
        if (roomInfo) {
            if (typeof roomInfo.Title === "string" && roomInfo.Title != "") {
                return roomInfo.Title
            } else if (typeof roomInfo.RoomName === "string" && roomInfo.RoomName != "") {
                return roomInfo.RoomName
            }
        }
        return ""
    }

    signal ready
    signal cancel

    function restoreBindings() {
        messages.account = Qt.binding(getCurrentAccount)
        headerSections.selectedIndex = Qt.binding(getSelectedIndex)
    }

    function getAccountsModel() {
        // on chat rooms we don't give the option to switch to another account
        // also, if we have a broadcast chat of a protocol we display on selector,
        // we should not display other accounts
        var tmpAccount = telepathyHelper.accountForId(messages.accountId)
        if (!newMessage && tmpAccount && tmpAccount.type != AccountEntry.PhoneAccount &&
            (messages.chatType == HistoryThreadModel.ChatTypeRoom ||
             tmpAccount.protocolInfo.showOnSelector)) {
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
        if (messages.accountsModel.length == 1 && messages.accountsModel[0].type == AccountEntry.GenericAccount) {
            return accountNames
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
        } else if (!(telepathyHelper.phoneAccounts.active.length > 0) && messages.accountsModel.length > 0) {
            return messages.accountsModel[0]
        }
        return mainView.account
    }

    function checkThreadInFilters(newAccountId, threadId) {
        for (var i in messages.threads) {
            if (messages.threads[i].threadId == threadId && messages.threads[i].accountId == newAccountId) {
                return true
            }
        }
        return false
    }

    function resetFilters(){
        messages.participants.length = 0
        messages.participantIds.length = 0
        messages.threads = []
        reloadFilters = !reloadFilters
    }

    function addNewThreadToFilter(newAccountId, properties) {
        var newAccount = telepathyHelper.accountForId(newAccountId)
        var matchType = HistoryThreadModel.MatchCaseSensitive
        // if the addressable fields contains "tel", assume we should do phone match
        if (newAccount.usePhoneNumbers) {
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

        if (!checkThreadInFilters(newAccountId, threadId)) {
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
            PopupUtils.open(Qt.resolvedUrl("Dialogs/NoNetworkDialog.qml"), null, {'multiplePhoneAccounts': multiplePhoneAccounts,
                                                                          'accountName': messages.account.displayName})
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
                var thread = eventModel.threadForProperties(messages.account.accountId,
                                                            HistoryEventModel.EventTypeText,
                                                            properties,
                                                            messages.account.usePhoneNumbers ? HistoryEventModel.MatchPhoneNumber : HistoryEventModel.MatchCaseSensitive,
                                                            true);
                if (!checkThreadInFilters(thread.accountId, thread.threadId)) {
                    addNewThreadToFilter(thread.accountId, thread)
                }

                messages.threadId = thread.threadId
                eventModel.writeTextInformationEvent(messages.account.accountId,
                                                     messages.threadId,
                                                     newParticipantsIds,
                                                     "",
                                                     HistoryThreadModel.InformationTypeSimChange, "")
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

            // FIXME: we need to review this case. In case of account overload, this will be saved in the wrong thread

            // create the thread
            var thread = eventModel.threadForProperties(messages.account.accountId,
                                                        HistoryEventModel.EventTypeText,
                                                        properties,
                                                        messages.account.usePhoneNumbers ? HistoryEventModel.MatchPhoneNumber : HistoryEventModel.MatchCaseSensitive,
                                                        true);
            if (!checkThreadInFilters(thread.accountId, thread.threadId)) {
                addNewThreadToFilter(thread.accountId, thread)
            }
            messages.threadId = thread.threadId

            var event = {}
            var timestamp = new Date()
            var tmpEventId = timestamp.toISOString()
            event["accountId"] = messages.account.accountId
            event["threadId"] = messages.threadId
            event["eventId"] =  tmpEventId
            event["type"] = HistoryEventModel.MessageTypeText
            event["participants"] = messages.participants
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
                    attachment["threadId"] = messages.threadId
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
            var isMmsGroupChat = messages.account.type == AccountEntry.PhoneAccount && messages.chatType == ChatEntry.ChatTypeRoom
            // mms group chat only works if we know our own phone number
            var isSelfContactKnown = account.selfContactId != ""
            if (isMmsGroupChat && !isSelfContactKnown) {
                // TODO: inform the user to enter the phone number of the selected sim card manually
                // and use it in the telepathy-ofono account as selfContactId.
                console.warn("The selected SIM card does not have a number set on it, can't create group")
                application.showNotificationMessage(i18n.tr("The SIM card does not provide the owner's phone number. Because of that sending MMS group messages is not possible."), "contact-group")
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
        selectThreadOnIdle.restart()
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
                                                                 account.usePhoneNumbers ? HistoryThreadModel.MatchPhoneNumber :
                                                                                           HistoryThreadModel.MatchCaseSensitive);
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
        return Qt.createQmlObject(componentUnion.arg(componentFilters), eventModel)
    }

    function markThreadAsRead() {
        if (!mainView.applicationActive || !messages.active || !messages.threads || messages.threads.length == 0) {
           return
        }

        threadModel.markThreadsAsRead(messages.threads);
        var properties = {'accountId': threads[0].accountId, 'threadId': threads[0].threadId, 'chatType': threads[0].chatType}
        chatManager.acknowledgeAllMessages(properties)
    }

    function selectActiveThread(threads) {
        if ((messages.chatType == HistoryEventModel.ChatTypeContact) &&
            (messages.threads.length > 0)) {
            var index = threadModel.indexOf(messages.threads[0].threadId, messages.threads[0].accountId)
            if (index != -1) {
                mainPage.selectMessage(index)
            }
        }
    }

    function participantIdentifierByProtocol(account, baseIdentifier) {
        if (account && account.protocolInfo) {
            switch(account.protocolInfo.name) {
            case "irc":
                if (account.parameters.server != "")
                    return "%1@%2".arg(baseIdentifier).arg(account.parameters.server)
                return baseIdentifier
            default:
                return baseIdentifier
            }
        }
    }

    function contactMatchFieldFromProtocol(protocol, fallback) {
         switch(protocol) {
         case "irc":
             return ["X-IRC"];
         default:
             return fallback
         }
    }

    // Use a timer to make sure that 'threads' are correct set before try to select it
    Timer {
        id: selectThreadOnIdle
        interval: 100
        repeat: false
        running: false
        onTriggered: selectActiveThread(messages.threads)
    }


    header: PageHeader {
        id: pageHeader

        property bool backEnabled: true
        property alias trailingActions: trailingBar.actions
        property bool showSections: {
            if (headerSections.model.length > 1) {
                return true
            }
            return (messages.accountsModel.length == 1 && messages.accountsModel[0].type == AccountEntry.GenericAccount)
        }

        title: {
            if (landscape) {
                return ""
            }

            if (participants && participants.length === 1) {
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
            visible: pageHeader.showSections
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

        extension: pageHeader.showSections ? headerSections : null

        leadingActionBar.actions: [
            Action {
               iconName: "back"
               text: i18n.tr("Back")
               shortcut: visible ? "Esc" : ""
               visible: pageHeader.backEnabled
               onTriggered: {
                   if (messages.state == "selection") {
                        messageList.cancelSelection()
                   } else {
                        mainView.emptyStack(true)
                   }
               }
            }
        ]

        trailingActionBar {
            id: trailingBar
        }

        Item {
            id: trailingActionArea
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: -headerSections.height
            }
        }
    }

    states: [
        State {
            id: selectionState
            name: "selection"
            when: selectionMode

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
                trailingActions: selectionState.trailingActions
                backEnabled: true
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
                    onTriggered: {
                        // at this point we are interested in the thread participants no matter what the channel type is
                        messagesModel.requestThreadParticipants(messages.threads)
                        mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("GroupChatInfoPage.qml"), { threadInformation: threadInformation, chatEntry: messages.chatEntry, eventModel: eventModel})
                    }
                },
                Action {
                    id: rejoinGroupChatAction
                    objectName: "rejoinGroupChatAction"
                    enabled: !chatEntry.active && messages.account.protocolInfo.enableRejoin && messages.account.connected
                    visible: enabled
                    iconName: "view-refresh"
                    onTriggered: messages.chatEntry.startChat()
                },
                Action {
                    id: favoriteAction
                    visible: chatEntry.active && (messages.chatType == HistoryThreadModel.ChatTypeRoom)
                    iconName: mainView.favoriteChannels.isFavorite(messages.accountId, messages.chatTitle) ? "starred" : "non-starred"
                    onTriggered: {
                        if (iconName == "starred")
                            mainView.favoriteChannels.removeFavorite(messages.accountId, messages.chatTitle)
                        else
                            mainView.favoriteChannels.addFavorite(messages.accountId, messages.chatTitle)
                    }
                }

            ]

            PropertyChanges {
                target: pageHeader
                // TRANSLATORS: %1 refers to the number of participants in a group chat
                title: {
                    var finalParticipants = (participants ? participants.length : 0)
                    if (messages.chatType == HistoryThreadModel.ChatTypeRoom) {
                        if (messages.chatTitle != "") {
                            return messages.chatTitle
                        }

                        // include the "Me" participant to be consistent with
                        // group info page
                        if (roomInfo.Joined) {
                            finalParticipants++
                        }
                    }
                    return i18n.tr("Group (%1)").arg(finalParticipants)
                }
                contents: headerContents
                trailingActions: groupChatState.trailingActions
                backEnabled: pageStack.columns === 1
            }
        },
        State {
            id: unknownContactState
            name: "unknownContact"
            when: !messages.newMessage && (participants.length === 1) && contactWatcher.isUnknown

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "contactCallAction"
                    visible: participants && participants.length === 1 && contactWatcher.interactive && messages.account.addressableVCardFields.lastIndexOf("tel") != -1
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
                    visible: contactWatcher.isUnknown && participants && participants.length === 1 && contactWatcher.interactive
                    enabled: messages.account != null
                    iconName: "contact-new"
                    text: i18n.tr("Add")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        mainView.addAccountToContact(messages,
                                                     "",
                                                     messages.account.protocolInfo.name,
                                                     contactWatcher.identifier,
                                                     null, null)
                    }
                }
            ]
            PropertyChanges {
                target: pageHeader
                contents: headerContents
                trailingActions: unknownContactState.trailingActions
                backEnabled: pageStack.columns === 1
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
                            // invoke the MMS group action directly
                            mmsGroupAction.trigger()
                            return
                        }
                        contextMenu.caller = trailingActionArea;
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
                    top: parent ? parent.top: undefined
                    topMargin: parent ? (parent.height - multiRecipient.height)/2 : units.gu(1)
                }
                onActiveFocusChanged: {
                    if (!activeFocus && (searchListLoader.status != Loader.Ready || !searchListLoader.item.activeFocus))
                        commit()
                }

                onSelectedRecipients: function(recipientsIds) {
                    //cleanup the filter
                    resetFilters()

                    if (recipientsIds.length === 1) { //only refresh message history for single participant, otherwise it have UI side effect (unable to add more 2 participants )
                        addNewThreadToFilter(messages.account.accountId, {"participantIds": recipientsIds})
                    }
                }

                KeyNavigation.down: searchListLoader.item ? searchListLoader.item : composeBar.textArea
            }

            PropertyChanges {
                target: pageHeader
                title: " "
                trailingActions: newMessageState.trailingActions
                contents: newMessageState.contents
                backEnabled: true
            }
        },
        State {
            id: knownContactState
            name: "knownContact"
            when: !messages.newMessage && participants && participants.length === 1 && !contactWatcher.isUnknown

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "contactCallKnownAction"
                    visible: participants && participants.length === 1
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
                backEnabled: pageStack.columns === 1
            }
        }
    ]

    Component.onCompleted: {
        if (!chatEntry) {
            chatEntry = chatEntryComponent.createObject(this)
        }

        // we only revert back to phone account if this is a 1-1 chat,
        // in which case the handler will fallback to multimedia if needed
        if (messages.accountId !== "" && chatType !== HistoryThreadModel.ChatTypeRoom) {
            var account = telepathyHelper.accountForId(messages.accountId)

            // if the account is not supposed to be displayed, we check if it has a fallback
            if (account && !account.protocolInfo.showOnSelector) {
                // check if there is a fallback account to use
                var accounts = telepathyHelper.accountFallback(account);
                if (accounts.length > 0) {
                    messages.accountId = accounts[0].accountId
                }
            }
        }
        restoreBindings()
        if (threadId !== "" && accountId !== "" && threads.length == 0) {
            addNewThreadToFilter(accountId, {"threadId": threadId, "chatType": chatType})
        }
        newMessage = (messages.threadId == "") || (messages.accountId == "" && messages.participants.length === 0)
        // if it is a new message we need to add participants into the multiRecipient list
        if (newMessage) {
            for (var i in participantIds) {
                multiRecipient.addRecipient(participantIds[i])
            }
        }
        // if we add multiple attachments at the same time, it break the Repeater + Loaders
        fillAttachmentsTimer.start()
        mainView.updateNewMessageStatus()
        markThreadAsRead()
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
        if (participants && participants.length === 0 && keyboardFocus)
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
        markThreadAsRead()
        if (!newMessage)
            composeBar.forceFocus()
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
                if (!telepathyHelper.mmsEnabled) {
                    var properties = {}
                    var dialog = PopupUtils.open(Qt.resolvedUrl("Dialogs/MMSEnableDialog.qml"), messages, {})
                    dialog.accepted.connect(mmsGroupAction.showNewGroupPage)
                    return
                }
                showNewGroupPage(messages)
            }

            function showNewGroupPage(message) {
                mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("NewGroupPage.qml"), {"participants": multiRecipient.participants, "account": messages.account})
            }
        }

        Component {
            id: customGroupChatActionComponent
            Action {
                property var participants: null
                property var account: null
                text: {
                    // FIXME: temporary workaround
                    if (account.protocolInfo.name == "irc") {
                        return i18n.tr("Join IRC Channel...")
                    }
                    var protocolDisplayName = account.protocolInfo.serviceDisplayName;
                    if (protocolDisplayName === "") {
                       protocolDisplayName = account.protocolInfo.serviceName;
                    }
                    return i18n.tr("Create %1 Group...").arg(protocolDisplayName);
                }
                onTriggered: mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("NewGroupPage.qml"), {"mmsGroup": false, "participants": participants, "account": account})
            }
        }

        function updateGroupTypes() {
            // remove the previous actions
            actionList.removeAction(mmsGroupAction)
            for (var i in actionList.actions) {
                actionList.actions[i].destroy()
            }
            actionList.actions = []

            if (telepathyHelper.phoneAccounts.active.length > 0) {
                actionList.addAction(mmsGroupAction)
            }
            if (!account || account.type == AccountEntry.PhoneAccount) {
                return
            }
            var action = customGroupChatActionComponent.createObject(actionList, {"account": account, "participants": multiRecipient.participants})
            actionList.addAction(action)
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
            markThreadAsRead()
        }
    }

    Timer {
        id: typingTimer
        interval: 15000
        onTriggered: {
            messages.userTyping = false;
        }
    }

    Component {
        id: chatEntryComponent

        ChatEntry {
            id: chatEntryObject
            chatType: messages.chatType
            participantIds: messages.participantIds
            chatId: messages.threadId
            accountId: messages.accountId
        }
    }

    Connections {
        target: messages.chatEntry
        onChatTypeChanged: {
            messages.chatType = chatEntry.chatType
        }

        onMessageSent: {
            // create the new thread and update the threadId list
            if (!checkThreadInFilters(accountId, messages.threadId)) {
                addNewThreadToFilter(accountId, properties)
            }
        }
        onMessageSendingFailed: {
            // create the new thread and update the threadId list
            if (!checkThreadInFilters(accountId, messages.threadId)) {
                addNewThreadToFilter(accountId, properties)
            }
        }
    }

    Binding {
        target: messages.chatEntry
        property: "autoRequest"
        value: !messages.newMessage && !messages.account.protocolInfo.enableRejoin
    }

    Repeater {
        model: account ? (account.protocolInfo.enableChatStates ? messages.chatEntry.chatStates : null) : null
        delegate: Item {
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
        identifier: messages.participantIdentifierByProtocol(messages.account, userTypingId)
        addressableFields: messages.account ?
                               messages.contactMatchFieldFromProtocol(messages.account.protocolInfo.name, messages.account.addressableVCardFields) : []
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
            // might be available for that.
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
        identifier: participants && participants.length === 1 ? participants[0].identifier : ""
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

    Loader {
        id: searchListLoader

        property int resultCount: (status === Loader.Ready) ? item.count : 0

        source: (multiRecipient.searchString !== "") ?
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

        Connections {
            target: searchListLoader.item
            onActiveFocusChanged: {
                if (!searchListLoader.item.activeFocus && !multiRecipient.activeFocus)
                    multiRecipient.commit()
            }
            onFocusUp: {
                multiRecipient.forceActiveFocus()
            }
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
        identifier: firstParticipant && firstParticipant.identifier ? messages.participantIdentifierByProtocol(messages.account, firstParticipant.identifier) : ""
        contactId: firstParticipant && firstParticipant.contactId ? firstParticipant.contactId : ""
        alias: firstParticipant && firstParticipant.alias ? firstParticipant.alias : ""
        avatar: firstParticipant && firstParticipant.avatar ? firstParticipant.avatar : ""
        detailProperties: firstParticipant && firstParticipant.detailProperties ? firstParticipant.detailProperties : {}
        addressableFields:  messages.account && messages.account.protocolInfo ?
                               messages.contactMatchFieldFromProtocol(messages.account.protocolInfo.name, messages.account.addressableVCardFields) : []
    }

    HistoryUnionFilter {
        id: filters
        HistoryIntersectionFilter {
            HistoryFilter { filterProperty: "accountId"; filterValue: messages.accountId }
            HistoryFilter { filterProperty: "threadId"; filterValue: messages.threadId }
        }
    }

    HistoryGroupedThreadsModel {
        id: messagesModel
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
        property var localPendingParticipants: null
        property var remotePendingParticipants: null
        property var threads: null
        model: messagesModel
        visible: false
        delegate: Item {
            property var threads: model.threads
            onThreadsChanged: {
                //workaround for https://github.com/ubports/messaging-app/issues/66, model is loaded twice when sending a new message due to message status change (status = unknow and then active )
                //make sure there is really a participants list update to avoid unecessary reloading
                if (threadInformation.participants == null || threadInformation.participantsHasChanged(model.participants)){
                    threadInformation.participants = model.participants
                }
                threadInformation.chatRoomInfo = model.chatRoomInfo
                threadInformation.localPendingParticipants = model.localPendingParticipants
                threadInformation.remotePendingParticipants = model.remotePendingParticipants
                threadInformation.threads = model.threads

            }
        }

        function participantsHasChanged(newParticipants){
            var oldParticipantsIds = messages.participantIds
            if (newParticipants.length !== oldParticipantsIds.length) return true

            for (var i in newParticipants) {
                if (oldParticipantsIds.indexOf(newParticipants[i].identifier) === -1) return true
            }
            return false
        }
    }

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: updateFilters(telepathyHelper.textAccounts.all, messages.chatType, messages.participantIds, messages.reloadFilters, messages.threads)
        matchContacts: messages.account ? messages.account.addressableVCardFields.length > 0 : false
        sort: HistorySort {
           sortField: "timestamp"
           sortOrder: HistorySort.DescendingOrder
        }
        onCountChanged: {
            markThreadAsRead()
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
        listModel: eventModel
        account: messages.account
        activeFocusOnTab: false
        focus: false
        onActiveFocusChanged: {
            if (activeFocus) {
                composeBar.forceFocus()
            }
        }

        Rectangle {
            color: Theme.palette.normal.background
            anchors.fill: parent
            Image {
                width: units.gu(20)
                opacity: 0.1
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
                visible: source !== ""
                source: {
                    var accountId = ""

                    if (messages.account) {
                        accountId = messages.account.accountId
                    }

                    // display a different watermark for broadcast conversations
                    if (messages.isBroadcast) {
                        return Qt.resolvedUrl("./assets/broadcast_watermark.png")
                    }

                    if (presenceRequest.type != PresenceRequest.PresenceTypeUnknown
                            && presenceRequest.type != PresenceRequest.PresenceTypeUnset) {
                        accountId = presenceRequest.accountId
                    }

                    if (accountId == "") {
                        return ""
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
            var account = telepathyHelper.accountForId(messages.accountId)
            if (account && account.type == AccountEntry.PhoneAccount) {
                return false
            }
            if (threads.length > 0) {
                if (!chatEntry.active && messages.account.protocolInfo.enableRejoin) {
                    return true
                }
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

        participants: messages.participants
        threadId: messages.threadId
        presenceRequest: messages.presenceRequest
        isBroadcast: messages.isBroadcast
        returnToSend: messages.account.protocolInfo.returnToSend
        enableAttachments: messages.account.protocolInfo.enableAttachments

        showContents: !selectionMode && !isSearching && !chatInactiveLabel.visible
        maxHeight: messages.height - keyboard.height - screenTop.y
        onTextChanged: {
            if (!account.protocolInfo.enableChatStates) {
                return
            }
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
                    messages.chatEntry.setChatState(ChatEntry.ChannelChatStatePaused)
                    messages.chatEntry.setChatState(ChatEntry.ChannelChatStateComposing)
                }
            }
            selfTypingTimer.restart()

        }
        canSend: chatType == ChatEntry.ChatTypeRoom || (participants !== null && participants.length > 0) || multiRecipient.recipientCount > 0 || multiRecipient.searchString !== ""
        oskEnabled: messages.oskEnabled
        usingMMS: messages.account.type == AccountEntry.PhoneAccount && messages.chatType == ChatEntry.ChatTypeRoom

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
            for (var i = 0; i < attachments.count; i++) {
                var attachment = []
                var item = attachments.get(i)
                // we dont include smil files. they will be auto generated
                if (item.contentType.toLowerCase() === "application/smil") {
                    continue
                }
                attachment.push(item.name)
                attachment.push(item.contentType)
                attachment.push(item.filePath)
                newAttachments.push(attachment)
            }

            var recipients = participantIds.length > 0 ? participantIds :
                                                         multiRecipient.recipients
            var properties = {}
            if (composeBar.audioAttached) {
                properties["x-canonical-tmp-files"] = true
            }

            sendMessageValidator.validateMessageAndSend(text, recipients, newAttachments, properties)

            if (eventModel.filter == null) {
                reloadFilters = !reloadFilters
            }
        }

        KeyNavigation.up: messages.header.contents
    }

    SendMessageValidator {
        id: sendMessageValidator

        onMessageSent: composeBar.reset()
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

    Binding {
        target: pageStack
        property: "activePage"
        value: messages
        when: messages.active
    }

    onActiveFocusChanged: {
        if (activeFocus && !newMessage) {
            composeBar.textArea.forceActiveFocus()
        }
    }
}
