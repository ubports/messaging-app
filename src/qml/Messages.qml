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
    property QtObject account: getCurrentAccount()
    property bool phoneAccount: isPhoneAccount()
    property variant participants: []
    property variant participantIds: []
    property bool groupChat: participants.length > 1
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
    property QtObject chatEntry: !account ? null : chatManager.chatEntryForParticipants(account.accountId, participants, true)
    property string firstParticipantId: participantIds.length > 0 ? participantIds[0] : ""
    property variant firstParticipant: participants.length > 0 ? participants[0] : null
    property var threads: []
    property QtObject presenceRequest: presenceItem
    property var accountsModel: getAccountsModel()
    property alias oskEnabled: keyboard.oskEnabled
    property bool isReady: false
    property string firstRecipientAlias: ((contactWatcher.isUnknown &&
                                           contactWatcher.isInteractive) ||
                                          contactWatcher.alias === "") ? contactWatcher.identifier : contactWatcher.alias

    // When using this view from the bottom edge, we are not in the stack, so we need to push on top of the parent page
    property var basePage: messages

    property bool startedFromBottomEdge: false

    signal ready
    signal cancel

    function getAccountsModel() {
        var accounts = []
        // on new chat dialogs display all possible accounts
        if (accountId == "" && participants.length === 0) {
            for (var i in telepathyHelper.activeAccounts) {
                accounts.push(telepathyHelper.activeAccounts[i])
            }
            // suru divider must be empty if there is only one sim card
            if (accounts.length == 1 && accounts[0].type == AccountEntry.PhoneAccount) {
                return []
            }
            return accounts
        }
 
        var tmpAccount = telepathyHelper.accountForId(messages.accountId)
        // on generic accounts we don't give the option to switch to another account
        if (tmpAccount && tmpAccount.type == AccountEntry.GenericAccount) {
            return [tmpAccount]
        }

        // if we get here, this is a regular sms conversation. just
        // add the available phone accounts next
        for (var i in telepathyHelper.activeAccounts) {
            var account = telepathyHelper.activeAccounts[i]
            if (account.type == AccountEntry.PhoneAccount) {
                accounts.push(account)
            }
        }

        return accounts
    }

    function getSectionsModel() {
        var accountNames = []
        // suru divider must be empty if there is only one sim card
        if (messages.accountsModel.length == 1 &&
                messages.accountsModel[0].type == AccountEntry.PhoneAccount) {
            return []
        }
 
        for (var i in messages.accountsModel) {
            accountNames.push(messages.accountsModel[i].displayName)
        }
        return accountNames.length > 0 ? accountNames : []
    }

    function getSelectedIndex() {
        if (accountId == "" && participants.length === 0) {
            // if this is a new message, just pre select the the 
            // default phone account for messages if available
            if (multiplePhoneAccounts && telepathyHelper.defaultMessagingAccount) {
                for (var i in messages.accountsModel) {
                    if (telepathyHelper.defaultMessagingAccount == messages.accountsModel[i]) {
                        return i
                    }
                }
            }
            // otherwise pre-select the first available phone account if any
            for (var i in messages.accountsModel) {
                if (messages.accountsModel[i].type == AccountEntry.PhoneAccount) {
                    return i
                }
            }
            // otherwise select none
            return -1
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
                if (telepathyHelper.defaultMessagingAccount) {
                    for (var i in messages.accountsModel) {
                        if (messages.accountsModel[i] == telepathyHelper.defaultMessagingAccount) {
                            return telepathyHelper.defaultMessagingAccount
                        }
                    }
                }
                for (var i in messages.accountsModel) {
                    if (messages.accountsModel[i].type == AccountEntry.PhoneAccount) {
                        return messages.accountsModel[i]
                    }
                }
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

    function isPhoneAccount() {
        var tmpAccount = telepathyHelper.accountForId(accountId)
        return (!tmpAccount || tmpAccount.type == AccountEntry.PhoneAccount || tmpAccount.type == AccountEntry.MultimediaAccount)
    }

    function addNewThreadToFilter(newAccountId, participantIds) {
        var newAccount = telepathyHelper.accountForId(newAccountId)
        var matchType = HistoryThreadModel.MatchCaseSensitive
        if (newAccount.type == AccountEntry.PhoneAccount || newAccount.type == AccountEntry.MultimediaAccount) {
            matchType = HistoryThreadModel.MatchPhoneNumber
        }

        var thread = eventModel.threadForParticipants(newAccountId,
                                           HistoryThreadModel.EventTypeText,
                                           participantIds,
                                           matchType,
                                           true)
        var threadId = thread.threadId

        // dont change the participants list
        if (messages.participants.length == 0) {
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
            messages.threads.push({"accountId": newAccountId, "threadId": threadId})
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

    // FIXME: support more stuff than just phone number
    function onPhonePickedDuringSearch(phoneNumber) {
        multiRecipient.addRecipient(phoneNumber)
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
            PopupUtils.open(Qt.createComponent("Dialogs/NoSIMCardSelectedDialog.qml").createObject(messages))
            return false
        }

        // create the new thread and update the threadId list
        var thread = addNewThreadToFilter(messages.account.accountId, participantIds)

        for (var i=0; i < eventModel.count; i++) {
            var event = eventModel.get(i)
            if (event.senderId == "self" && event.accountId != messages.account.accountId) {
                var tmpAccount = telepathyHelper.accountForId(event.accountId)
                if (!tmpAccount || (tmpAccount.type == AccountEntry.MultimediaAccount && messages.account.type == AccountEntry.PhoneAccount)) {
                    // we don't add the information event if the last outgoing message
                    // was a fallback to a multimedia service
                    break;
                }
                // if the last outgoing message used a different accountId, add an
                // information event and quit the loop
                eventModel.writeTextInformationEvent(messages.account.accountId,
                                                     thread.threadId,
                                                     participantIds,
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
            var isMmsGroupChat = participants.length > 1 && telepathyHelper.mmsGroupChat && messages.account.type == AccountEntry.PhoneAccount
            // mms group chat only works if we know our own phone number
            var isSelfContactKnown = account.selfContactId != ""
            if (isMmsGroupChat && !isSelfContactKnown) {
                // TODO: inform the user to enter the phone number of the selected sim card manually
                // and use it in the telepathy-ofono account as selfContactId.
                return false
            }
            var fallbackAccountId = chatManager.sendMessage(messages.account.accountId, participantIds, text, attachments, properties)
            // create the new thread and update the threadId list
            if (fallbackAccountId != messages.account.accountId) {
                addNewThreadToFilter(fallbackAccountId, participantIds)
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

    function updateFilters(accounts, participants, reload, threads) {
        if (participants.length == 0 || accounts.length == 0) {
            return null
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

        var filterAccounts = []

        if (messages.accountsModel.length == 1 && messages.accountsModel[0].type == AccountEntry.GenericAccount) {
            filterAccounts = [messages.accountsModel[0]]
        } else {
            for (var i in telepathyHelper.accounts) {
                var account = telepathyHelper.accounts[i]
                if (account.type === AccountEntry.PhoneAccount || account.type === AccountEntry.MultimediaAccount) {
                    filterAccounts.push(account)
                }
            }
        }

        for (var i in filterAccounts) {
            var account = filterAccounts[i];
            var filterValue = eventModel.threadIdForParticipants(account.accountId,
                                                                 HistoryThreadModel.EventTypeText,
                                                                 participants,
                                                                 account.type === AccountEntry.PhoneAccount || account.type === AccountEntry.MultimediaAccount ? HistoryThreadModel.MatchPhoneNumber
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
        return Qt.createQmlObject(componentUnion.arg(componentFilters), eventModel)
    }

    function markMessageAsRead(accountId, threadId, eventId, type) {
        if (!mainView.applicationActive) {
           var pendingEvent = {"accountId": accountId, "threadId": threadId, "eventId": eventId, "type": type}
           pendingEventsToMarkAsRead.push(pendingEvent)
           return false
        }
        chatManager.acknowledgeMessage(participantIds, eventId, accountId)
        return eventModel.markEventAsRead(accountId, threadId, eventId, type);
    }

    header: PageHeader {
        id: pageHeader

        property alias leadingActions: leadingBar.actions
        property alias trailingActions: trailingBar.actions

        property list<QtObject> bottomEdgeLeadingActions: [
            Action {
                id: backAction

                objectName: "cancel"
                name: "cancel"
                text: i18n.tr("Cancel")
                iconName: "down"
                shortcut: "Esc"
                onTriggered: {
                    messages.cancel()
                }
            }
        ]

        property list<QtObject> singlePanelLeadingActions: [
            Action {
                id: singlePanelBackAction
                objectName: "back"
                name: "cancel"
                text: i18n.tr("Cancel")
                iconName: "back"
                shortcut: "Esc"
                onTriggered: {
                    // emptyStack will make sure the page gets removed.
                    mainView.emptyStack()
                }
            }
        ]

        title: {
            if (landscape) {
                return ""
            }

            if (participants.length == 1) {
                return firstRecipientAlias
            }

            return i18n.tr("New Message")
        }
        flickable: null

        Sections {
            id: headerSections
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
        }

        extension: headerSections.model.length > 1 ? headerSections : null

        leadingActionBar {
            id: leadingBar

            states: [
                State {
                    name: "bottomEdgeBack"
                    when: startedFromBottomEdge
                    PropertyChanges {
                        target: leadingBar
                        actions: pageHeader.bottomEdgeLeadingActions
                    }
                },
                State {
                    name: "singlePanelBack"
                    when: !mainView.dualPanel && !startedFromBottomEdge
                    PropertyChanges {
                        target: leadingBar
                        actions: pageHeader.singlePanelLeadingActions
                    }
                }

            ]
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
                    onTriggered: PopupUtils.open(participantsPopover, trailingActionArea)
                }
            ]

            PropertyChanges {
                target: pageHeader
                // TRANSLATORS: %1 refers to the number of participants in a group chat
                title: i18n.tr("Group (%1)").arg(participants.length)
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
            when: participants.length === 0

            property list<QtObject> trailingActions: [
                Action {
                    objectName: "contactList"
                    iconName: "contact"
                    onTriggered: {
                        Qt.inputMethod.hide()
                        mainStack.addFileToCurrentColumnSync(messages.basePage,  Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": multiRecipient})
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
                    visible: participants.length == 1 && messages.phoneAccount
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
                    visible: !contactWatcher.isUnknown && participants.length == 1 && messages.phoneAccount
                    iconSource: "image://theme/contact"
                    text: i18n.tr("Contact")
                    onTriggered: {
                        mainView.showContactDetails(messages.basePage, contactWatcher.contactId, null, null)
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
        if (messages.accountId !== "") {
            var account = telepathyHelper.accountForId(messages.accountId)
            if (account && account.type == AccountEntry.MultimediaAccount) {
                // fallback the first available phone account
                if (telepathyHelper.phoneAccounts.length > 0) {
                    messages.accountId = telepathyHelper.phoneAccounts[0].accountId
                }
            }
        }
        // if we add multiple attachments at the same time, it break the Repeater + Loaders
        fillAttachmentsTimer.start()
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
    }

    // These fake items are used to track if there are instances loaded
    // on the second column because we have no access to the page stack
    Loader {
        sourceComponent: fakeItemComponent
        active: !startedFromBottomEdge
    }
    Component {
        id: fakeItemComponent
        Item { objectName:"fakeItem"}
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            // force reevaluation
            messages.account = Qt.binding(getCurrentAccount)
            messages.phoneAccount = Qt.binding(isPhoneAccount)
            headerSections.model = Qt.binding(getSectionsModel)
            headerSections.selectedIndex = Qt.binding(getSelectedIndex)
        }
    }

    Connections {
        target: chatManager
        onChatEntryCreated: {
            // TODO: track using chatId and not participants
            if (accountId == account.accountId &&
                firstParticipant && participants[0] == firstParticipant.identifier) {
                messages.chatEntry = chatEntry
            }
        }
        onChatsChanged: {
            for (var i in chatManager.chats) {
                var chat = chatManager.chats[i]
                // TODO: track using chatId and not participants
                if (chat.account.accountId == account.accountId &&
                    firstParticipant && chat.participants[0] == firstParticipant.identifier) {
                    messages.chatEntry = chat
                    return
                }
            }
            messages.chatEntry = null
        }
    }

    // this is necessary to automatically update the view when the
    // default account changes in system settings
    Connections {
        target: mainView
        onAccountChanged: {
            if (!messages.phoneAccount) {
                return
            }
            messages.account = mainView.account
        }

        onApplicationActiveChanged: {
            if (mainView.applicationActive) {
                for (var i in pendingEventsToMarkAsRead) {
                    var event = pendingEventsToMarkAsRead[i]
                    markMessageAsRead(event.accountId, event.threadId, event.eventId, event.type)
                }
                pendingEventsToMarkAsRead = []
            }
        }
    }

    Timer {
        id: typingTimer
        interval: 6000
        onTriggered: {
            messages.userTyping = false;
        }
    }

    Repeater {
        model: messages.chatEntry ? messages.chatEntry.chatStates : null
        Item {
            function processChatState() {
                if (modelData.state == ChatEntry.ChannelChatStateComposing) {
                    messages.userTyping = true
                    typingTimer.start()
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

    MessagesHeader {
        id: headerContents
        width: parent ? parent.width - units.gu(2) : undefined
        height: units.gu(5)
        title: pageHeader.title
        subtitle: {
            if (userTyping) {
                return i18n.tr("Typing..")
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
            if (!account) {
                return ""
            }
            if (account.type == AccountEntry.PhoneAccount) {
                for (var i in telepathyHelper.accounts) {
                    var tmpAccount = telepathyHelper.accounts[i]
                    if (tmpAccount.type == AccountEntry.MultimediaAccount) {
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
        id: participantsPopover

        Popover {
            id: popover
            anchorToKeyboard: false
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                Repeater {
                    model: participants
                    Item {
                        height: childrenRect.height
                        width: popover.width
                        ListItem.Standard {
                            id: participant
                            objectName: "participant%1".arg(index)
                            text: contactWatcher.isUnknown ? contactWatcher.identifier : contactWatcher.alias
                            onClicked: {
                                PopupUtils.close(popover)
                                mainView.startChat(contactWatcher.identifier)
                            }
                        }
                        ContactWatcher {
                            id: contactWatcher
                            identifier: modelData.identifier
                            contactId: modelData.contactId
                            alias: modelData.alias
                            avatar: modelData.avatar
                            detailProperties: modelData.detailProperties

                            addressableFields: messages.account.addressableVCardFields
                        }
                    }
                }
            }
        }
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
            topMargin: header.height + units.gu(2)
            left: parent.left
            right: parent.right
            bottom: composeBar.top
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
                item.phonePicked.connect(messages.onPhonePickedDuringSearch)
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

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: updateFilters(telepathyHelper.accounts, messages.participantIds, messages.reloadFilters, messages.threads)
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
            bottom: composeBar.top
        }
    }

    ComposeBar {
        id: composeBar
        anchors {
            bottom: isSearching ? parent.bottom : keyboard.top
            left: parent.left
            right: parent.right
        }

        showContents: !selectionMode && !isSearching
        maxHeight: messages.height - keyboard.height - screenTop.y
        text: messages.text
        canSend: participants.length > 0 || multiRecipient.recipientCount > 0 || multiRecipient.searchString !== ""
        oskEnabled: messages.oskEnabled

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
                headerSections.selectedIndex = Qt.binding(getSelectedIndex)
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
                // FIXME we are guessing here if the handler will try to send it over multimedia account
                var isPhone = (account && account.type == AccountEntry.PhoneAccount)
                if (isPhone) {
                    for (var i in telepathyHelper.accounts) {
                        var tmpAccount = telepathyHelper.accounts[i]
                        if (tmpAccount.type == AccountEntry.MultimediaAccount) {
                            // now check if the user is at least known by the account
                            if (presenceRequest.type != PresenceRequest.PresenceTypeUnknown
                                     && presenceRequest.type != PresenceRequest.PresenceTypeUnset) {
                                isPhone = false
                            }
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
