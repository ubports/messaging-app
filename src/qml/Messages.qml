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

import QtQuick 2.2
import QtQuick.Window 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1

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
    property bool groupChat: participants.length > 1
    property bool keyboardFocus: true
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property var activeTransfer: null
    property int activeAttachmentIndex: -1
    property var sharedAttachmentsTransfer: []
    property alias contactWatcher: contactWatcherInternal
    property string lastFilter: ""
    property string text: ""
    property string scrollToEventId: ""
    property bool isSearching: scrollToEventId !== ""
    property string latestEventId: ""
    property var pendingEventsToMarkAsRead: []
    // to be used by tests as variant does not work with autopilot
    property string firstParticipant: participants.length > 0 ? participants[0] : ""
    property bool userTyping: false
    property QtObject chatEntry: !account ? null : chatManager.chatEntryForParticipants(account.accountId, participants, true)

    property var accountsModel: {
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

    Connections {
        target: telepathyHelper
        onSetupReady: {
            // force reevaluation
            messages.account = Qt.binding(getCurrentAccount)
            messages.phoneAccount = Qt.binding(isPhoneAccount)
        }
    }


    Connections {
        target: chatManager
        onChatEntryCreated: {
            // TODO: track using chatId and not participants
            if (accountId == account.accountId && 
                participants[0] == messages.participants[0]) {
                messages.chatEntry = chatEntry
            }
        }
        onChatsChanged: {
            for (var i in chatManager.chats) {
                var chat = chatManager.chats[i]
                // TODO: track using chatId and not participants
                if (chat.account.accountId == account.accountId &&
                    chat.participants[0] == messages.participants[0]) {
                    messages.chatEntry = chat
                    return
                }
            }
            messages.chatEntry = null
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
        id: header
        width: parent ? parent.width - units.gu(2) : undefined
        height: units.gu(5)
        title: messages.title
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

    head {
        sections.model: {
            var accountNames = []
            // suru divider must be empty if there is only one sim card
            if (messages.accountsModel.length == 1 &&
                    messages.accountsModel[0].type == AccountEntry.PhoneAccount) {
                return undefined
            }
 
            for (var i in messages.accountsModel) {
                accountNames.push(messages.accountsModel[i].displayName)
            }
            return accountNames.length > 0 ? accountNames : undefined
        }
        sections.selectedIndex: getSelectedIndex()
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

    function addAttachmentsToModel(transfer) {
        for (var i = 0; i < transfer.items.length; i++) {
            if (String(transfer.items[i].text).length > 0) {
                messages.text = String(transfer.items[i].text)
                continue
            }
            var attachment = {}
            if (!startsWith(String(transfer.items[i].url),"file://")) {
                messages.text = String(transfer.items[i].url)
                continue
            }
            var filePath = String(transfer.items[i].url).replace('file://', '')
            // get only the basename
            attachment["contentType"] = application.fileMimeType(filePath)
            if (startsWith(attachment["contentType"], "text/vcard") ||
                startsWith(attachment["contentType"], "text/x-vcard")) {
                attachment["name"] = "contact.vcf"
            } else {
                attachment["name"] = filePath.split('/').reverse()[0]
            }
            attachment["filePath"] = filePath
            attachments.append(attachment)
        }
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

    function sendMessage(text, participants, attachments, properties) {
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
        var threadId = eventModel.threadIdForParticipants(messages.account.accountId,
                                           HistoryThreadModel.EventTypeText,
                                           participants,
                                           messages.account.type == AccountEntry.PhoneAccount ? HistoryThreadModel.MatchPhoneNumber
                                                                                              : HistoryThreadModel.MatchCaseSensitive,
                                           true)
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
                                                     threadId,
                                                     participants,
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
            event["threadId"] = threadId
            event["eventId"] =  tmpEventId
            event["type"] = HistoryEventModel.MessageTypeText
            event["participants"] = participants
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
                    attachment["threadId"] = threadId
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
                return
            }
            chatManager.sendMessage(messages.account.accountId, participants, text, attachments, properties)
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

    PresenceRequest {
        id: presenceRequest
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
        identifier: participants.length == 1 ? participants[0] : ""
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
    }

    Connections {
        target: telepathyHelper
        onAccountsChanged: updateFilters()
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

    ListModel {
        id: attachments
    }

    PictureImport {
        id: pictureImporter

        onPictureReceived: {
            var attachment = {}
            var filePath = String(pictureUrl).replace('file://', '')
            attachment["contentType"] = application.fileMimeType(filePath)
            attachment["name"] = filePath.split('/').reverse()[0]
            attachment["filePath"] = filePath
            attachments.append(attachment)
            textEntry.forceActiveFocus()
        }
    }

    flickable: null

    property bool isReady: false
    signal ready
    onReady: {
        isReady = true
        if (participants.length === 0 && keyboardFocus)
            multiRecipient.forceFocus()
    }

    property string firstRecipientAlias: ""
    title: {
        if (selectionMode || participants.length == 0) {
            return " "
        }

        if (landscape) {
            return ""
        }
        if (participants.length > 0) {
            if (participants.length == 1) {
                return (firstRecipientAlias !== "") ? firstRecipientAlias : contactWatcher.identifier
            } else {
                // TRANSLATORS: %1 refers to the number of participants in a group chat
                return i18n.tr("Group (%1)").arg(participants.length)
            }
        }
        return i18n.tr("New Message")
    }

    Component.onCompleted: {
        updateFilters()
        addAttachmentsToModel(sharedAttachmentsTransfer)
    }

    onActiveChanged: {
        if (active && (eventModel.count > 0)){
            swipeItemDemo.enable()
        }
    }

    function updateFilters() {
        if (participants.length == 0) {
            eventModel.filter = null
            return
        }

        var componentUnion = "import Ubuntu.History 0.1; HistoryUnionFilter { %1 }"
        var componentFilters = ""
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
            componentFilters += 'HistoryFilter { filterProperty: "threadId"; filterValue: "%1" } '.arg(filterValue)
        }
        if (componentFilters === "") {
            eventModel.filter = null
            lastFilter = ""
            return
        }
        if (componentFilters != lastFilter) {
            var finalString = componentUnion.arg(componentFilters)
            eventModel.filter = Qt.createQmlObject(finalString, eventModel)
            lastFilter = componentFilters
        }
    }

    function markMessageAsRead(accountId, threadId, eventId, type) {
        if (!mainView.applicationActive) {
           var pendingEvent = {"accountId": accountId, "threadId": threadId, "eventId": eventId, "type": type}
           pendingEventsToMarkAsRead.push(pendingEvent)
           return false
        }
        chatManager.acknowledgeMessage(participants, eventId, accountId)
        return eventModel.markEventAsRead(accountId, threadId, eventId, type);
    }

    Connections {
        target: mainView
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

    Component {
        id: attachmentPopover

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
                    text: i18n.tr("Remove")
                    onClicked: {
                        attachments.remove(activeAttachmentIndex)
                        PopupUtils.close(popover)
                    }
                }
            }
            Component.onDestruction: activeAttachmentIndex = -1
        }
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
                            identifier: modelData
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

    Connections {
        target: messages.head.sections
        onSelectedIndexChanged: {
            messages.account = messages.accountsModel[head.sections.selectedIndex]
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
            topMargin: units.gu(2)
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
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
        identifier: participants.length === 0 ? "" : participants[0]
        onIsUnknownChanged: firstRecipientAlias = contactWatcherInternal.alias
        onAliasChanged: firstRecipientAlias = contactWatcherInternal.alias
        addressableFields: messages.account ? messages.account.addressableVCardFields : ["tel"] // just to have a fallback there
    }

    onParticipantsChanged: {
        updateFilters()
    }

    onAccountsModelChanged: {
        updateFilters()
    }

    Action {
        id: backButton
        objectName: "backButton"
        iconName: "back"
        onTriggered: {
            if (typeof mainPage !== 'undefined') {
                mainPage.temporaryProperties = null
            }
            mainStack.removePages(messages)
        }
    }

    states: [
        PageHeadState {
            name: "selection"
            head: messages.head
            when: selectionMode

            backAction: Action {
                objectName: "selectionModeCancelAction"
                iconName: "back"
                onTriggered: messageList.cancelSelection()
            }

            actions: [
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
        },
        PageHeadState {
            name: "groupChat"
            head: messages.head
            when: groupChat
            backAction: backButton

            actions: [
                Action {
                    objectName: "groupChatAction"
                    iconName: "contact-group"
                    onTriggered: PopupUtils.open(participantsPopover, screenTop)
                }
            ]
        },
        PageHeadState {
            name: "unknownContact"
            head: messages.head
            when: participants.length == 1 && contactWatcher.isUnknown
            backAction: backButton
            contents: header

            actions: [
                Action {
                    objectName: "contactCallAction"
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
                    objectName: "addContactAction"
                    visible: contactWatcher.isUnknown && participants.length == 1 && messages.phoneAccount
                    iconName: "contact-new"
                    text: i18n.tr("Add")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        // FIXME: support other things than just phone numbers
                        mainView.addPhoneToContact("", contactWatcher.identifier, null, null)
                    }
                }
            ]
        },
        PageHeadState {
            name: "newMessage"
            head: messages.head
            when: participants.length === 0 //&& isReady
            backAction: backButton
            actions: [
                Action {
                    objectName: "contactList"
                    iconName: "contact"
                    onTriggered: {
                        Qt.inputMethod.hide()
                        mainStack.addPageToCurrentColumn(messages, Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": multiRecipient, "parentPage": messages})
                    }
                }

            ]

            contents: MultiRecipientInput {
                id: multiRecipient
                objectName: "multiRecipient"
                enabled: visible
                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                    rightMargin: units.gu(2)
                }
            }
        },
        PageHeadState {
            name: "knownContact"
            head: messages.head
            when: participants.length == 1 && !contactWatcher.isUnknown
            backAction: backButton
            contents: header
            actions: [
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
                        mainView.showContactDetails(messages, contactWatcher.contactId, null, null)
                    }
                }
            ]
        }
    ]

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: null
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
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 0
    }

    MessagesListView {
        id: messageList
        objectName: "messageList"
        visible: !isSearching

        // because of the header
        clip: true
        anchors {
            top: screenTop.bottom
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
    }

    Item {
        id: bottomPanel
        anchors.bottom: isSearching ? parent.bottom : keyboard.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + units.gu(2)
        visible: !selectionMode && !isSearching
        clip: true
        MouseArea {
            anchors.fill: parent
            onClicked: {
                messageTextArea.forceActiveFocus()
            }
        }

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        ListItem.ThinDivider {
            anchors.top: parent.top
        }

        Icon {
            id: attachButton
            objectName: "attachButton"
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.verticalCenter: sendButton.verticalCenter
            height: units.gu(3)
            width: units.gu(3)
            color: "gray"
            name: "camera-app-symbolic"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.inputMethod.hide()
                    pictureImporter.requestNewPicture()
                }
            }
        }

        StyledItem {
            id: textEntry
            property alias text: messageTextArea.text
            property alias inputMethodComposing: messageTextArea.inputMethodComposing
            property int fullSize: attachmentThumbnails.height + messageTextArea.height
            style: Theme.createStyleComponent("TextAreaStyle.qml", textEntry)
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: parent.bottom
            anchors.left: attachButton.right
            anchors.leftMargin: units.gu(1)
            anchors.right: sendButton.left
            anchors.rightMargin: units.gu(1)
            height: attachments.count !== 0 ? fullSize + units.gu(1.5) : fullSize
            onActiveFocusChanged: {
                if(activeFocus) {
                    messageTextArea.forceActiveFocus()
                } else {
                    focus = false
                }
            }
            focus: false
            MouseArea {
                anchors.fill: parent
                onClicked: messageTextArea.forceActiveFocus()
            }
            Flow {
                id: attachmentThumbnails
                spacing: units.gu(1)
                anchors{
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: units.gu(1)
                    leftMargin: units.gu(1)
                    rightMargin: units.gu(1)
                }
                height: childrenRect.height

                Component {
                    id: thumbnailImage
                    UbuntuShape {
                        property int index
                        property string filePath

                        width: childrenRect.width
                        height: childrenRect.height

                        image: Image {
                            id: avatarImage
                            width: units.gu(8)
                            height: units.gu(8)
                            sourceSize.height: height
                            sourceSize.width: width
                            fillMode: Image.PreserveAspectCrop
                            source: filePath
                            asynchronous: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressAndHold: {
                                mouse.accept = true
                                Qt.inputMethod.hide()
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Component {
                    id: thumbnailContact
                    Item {
                        id: attachment

                        property int index
                        property string filePath
                        property var vcardInfo: application.contactNameFromVCard(attachment.filePath)

                        height: units.gu(6)
                        width: textEntry.width

                        ContactAvatar {
                            id: avatar

                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                            }
                            fallbackAvatarUrl: "image://theme/contact"
                            fallbackDisplayName: label.name
                            width: height
                        }
                        Label {
                            id: label

                            property string name: attachment.vcardInfo["name"] !== "" ?
                                                      attachment.vcardInfo["name"] :
                                                      i18n.tr("Unknown contact")

                            anchors {
                                left: avatar.right
                                leftMargin: units.gu(1)
                                top: avatar.top
                                bottom: avatar.bottom
                                right: parent.right
                                rightMargin: units.gu(1)
                            }

                            verticalAlignment: Text.AlignVCenter
                            text: {
                                if (attachment.vcardInfo["count"] > 1) {
                                    return label.name + " (+%1)".arg(attachment.vcardInfo["count"]-1)
                                } else {
                                    return label.name
                                }
                            }
                            elide: Text.ElideMiddle
                            color: UbuntuColors.lightAubergine
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressAndHold: {
                                mouse.accept = true
                                Qt.inputMethod.hide()
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Component {
                    id: thumbnailUnknown

                    UbuntuShape {
                        property int index
                        property string filePath

                        width: units.gu(8)
                        height: units.gu(8)

                        Icon {
                            anchors.centerIn: parent
                            width: units.gu(6)
                            height: units.gu(6)
                            name: "attachment"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressAndHold: {
                                mouse.accept = true
                                Qt.inputMethod.hide()
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Repeater {
                    model: attachments
                    delegate: Loader {
                        height: units.gu(8)
                        sourceComponent: {
                            var contentType = getContentType(filePath)
                            console.log(contentType)
                            switch(contentType) {
                            case ContentType.Contacts:
                                return thumbnailContact
                            case ContentType.Pictures:
                                return thumbnailImage
                            case ContentType.Unknown:
                                return thumbnailUnknown
                            default:
                                console.log("unknown content Type")
                            }
                        }
                        onStatusChanged: {
                            if (status == Loader.Ready) {
                                item.index = index
                                item.filePath = filePath
                            }
                        }
                    }
                }
            }

            ListItem.ThinDivider {
                id: divider

                anchors {
                    left: parent.left
                    right: parent.right
                    top: attachmentThumbnails.bottom
                    margins: units.gu(0.5)
                }
                visible: attachments.count > 0
            }

            TextArea {
                id: messageTextArea
                objectName: "messageTextArea"
                anchors {
                    top: attachments.count == 0 ? textEntry.top : attachmentThumbnails.bottom
                    left: parent.left
                    right: parent.right
                }
                // this value is to avoid letter being cut off
                height: units.gu(4.3)
                style: LocalTextAreaStyle {}
                autoSize: true
                maximumLineCount: attachments.count == 0 ? 8 : 4
                placeholderText: i18n.tr("Write a message...")
                focus: textEntry.focus
                font.family: "Ubuntu"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: "#5d5d5d"
                text: messages.text
            }

            /*InverseMouseArea {
                anchors.fill: parent
                visible: textEntry.activeFocus
                onClicked: {
                    textEntry.focus = false;
                }
            }*/
            Component.onCompleted: {
                // if page is active, it means this is not a bottom edge page
                if (messages.active && messages.keyboardFocus && participants.length != 0) {
                    messageTextArea.forceActiveFocus()
                }
            }
        }

        Icon {
            id: sendButton
            objectName: "sendButton"
            anchors.verticalCenter: textEntry.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            color: "gray"
            source: Qt.resolvedUrl("./assets/send.svg")
            width: units.gu(3)
            height: units.gu(3)
            enabled: {
               if (participants.length > 0 || multiRecipient.recipientCount > 0 || multiRecipient.searchString !== "") {
                    if (textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0) {
                        return true
                    }
                }
                return false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // make sure we flush everything we have prepared in the OSK preedit
                    Qt.inputMethod.commit();
                    if (textEntry.text == "" && attachments.count == 0) {
                        return
                    }
                    // refresh the recipient list
                    multiRecipient.focus = false
                    // dont change the participants list
                    if (participants.length == 0) {
                        participants = multiRecipient.recipients
                    }

                    if (messages.account && messages.accountId == "") {
                        messages.accountId = messages.account.accountId
                        messages.head.sections.selectedIndex = Qt.binding(getSelectedIndex)
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

                    // if sendMessage succeeds it means the message was either sent or
                    // injected into the history service so the user can retry later
                    if (sendMessage(textEntry.text, participants, newAttachments)) {
                        textEntry.text = ""
                        attachments.clear()
                    }
                    updateFilters()
                }
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
}
