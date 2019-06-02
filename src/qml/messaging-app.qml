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
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import QtContacts 5.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Content 1.3
import Ubuntu.History 0.1
import "Stickers"

MainView {
    id: mainView

    property bool multiplePhoneAccounts: telepathyHelper.phoneAccounts.active.length > 1
    property QtObject account: defaultPhoneAccount()
    property bool applicationActive: Qt.application.active
    property alias mainStack: layout
    property bool dualPanel: mainStack.columns > 1
    property bool composingNewMessage: activeMessagesView && activeMessagesView.newMessage
    property QtObject activeMessagesView: null
    // settings
    property alias sortThreadsBy: globalSettings.sortThreadsBy
    property alias compactView: globalSettings.compactView
    property alias userTheme: globalSettings.userTheme
    property alias favoriteChannels: favoriteChannelsItem

    // private
    property var _pendingProperties: null


    function updateNewMessageStatus() {
        activeMessagesView = application.findMessagingChild("messagesPage", "active", true)
    }

    function defaultPhoneAccount() {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multiplePhoneAccounts) {
            return telepathyHelper.defaultMessagingAccount
        } else if (telepathyHelper.phoneAccounts.active.length > 0){
            return telepathyHelper.phoneAccounts.active[0]
        }
        return null
    }

    function showContactDetails(currentPage, contact, contactListPage, contactsModel) {
        var initialProperties = {}
        if (contactListPage) {
            initialProperties["contactListPage"] = contactListPage
        }
        if (contactsModel) {
            initialProperties["model"] = contactsModel
        }

        if (typeof(contact) == 'string') {
            initialProperties['contactId'] = contact
        } else {
            initialProperties['contact'] = contact
        }

        mainStack.addPageToCurrentColumn(currentPage,
                                         Qt.resolvedUrl("MessagingContactViewPage.qml"),
                                         initialProperties)
    }

    function protocolFromString(protocolName)
    {
        if (protocolName.indexOf("OnlineAccount.") === 0) {
            // protocol already converted
            return protocolName
        }

        switch(protocolName) {
        case "irc":
            return "OnlineAccount.Irc"
        case "ofono":
        default:
            return "OnlineAccount.Unknown"
        }
    }

    function addAccountToContact(currentPage, contact, accountProtocol, accountUri, contactListPage, contactsModel)
    {
        var accountDetails = {"protocol": protocolFromString(accountProtocol),
                              "uri": accountUri}
        if (contact === "") {
            mainStack.addPageToCurrentColumn(currentPage,
                                             Qt.resolvedUrl("NewRecipientPage.qml"),
                                             { "accountToAdd": accountDetails })
        } else {
            var initialProperties = { "accountToAdd": accountDetails }
            if (contactListPage) {
                initialProperties["contactListPage"] = contactListPage
            }
            if (contactsModel) {
                initialProperties["model"] = contactsModel
            }
            if (typeof(contact) == 'string') {
                initialProperties['contactId'] = contact
            } else {
                initialProperties['contact'] = contact
            }
            mainStack.addPageToCurrentColumn(currentPage,
                                             Qt.resolvedUrl("MessagingContactViewPage.qml"),
                                             initialProperties)
        }
    }

    function removeThreads(threads) {
        for (var i in threads) {
            var thread = threads[i];
            var participants = [];
            for (var j in thread.participants) {
                participants.push(thread.participants[j].identifier)
            }
            // and acknowledge all messages for the threads to be removed
            var properties = {'accountId': thread.accountId, 'threadId': thread.threadId,'participantIds': participants, 'chatType': thread.chatType}
            chatManager.acknowledgeAllMessages(properties)
            chatManager.leaveRoom(properties, "")
        }
        // at last remove the threads
        threadModel.removeThreads(threads);
    }

    function startImport(transfer) {
        var properties = {}
        emptyStack()
        properties["sharedAttachmentsTransfer"] = transfer
        mainView.showMessagesView(properties)
    }

    function connectToFavoriteChannels(account) {
        var favs = favoriteChannels.getFavoriteChannels(account.accountId)
        for (var c in favs) {
            var favChannel = favs[c]
            if (favChannel) {
                console.debug("Start channel:" + account.accountId + "/" + favChannel)
                var properties = {'chatType': HistoryThreadModel.ChatTypeRoom,
                                  'accountId': account.accountId,
                                  'threadId': favChannel}
                chatManager.startChat(account.accountId, properties)
            }
        }
    }

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()
        } else {
            telepathyHelper.unregisterChannelObserver()
        }
    }

    Connections {
        target: telepathyHelper.textAccounts
        onAccountChanged: {
            if (active) {
                connectToFavoriteChannels(entry)
            }
        }

        onActiveChanged: {
            for (var i in telepathyHelper.textAccounts.active) {
                if (telepathyHelper.textAccounts.active[i] == account) {
                    return;
                }
            }
            account = Qt.binding(defaultPhoneAccount)
        }

    }

    Connections {
        target: telepathyHelper
        // restore default bindings if any system settings changed
        onDefaultMessagingAccountChanged: {
            account = Qt.binding(defaultPhoneAccount)
        }

        onSetupReady: {
            if (multiplePhoneAccounts && !telepathyHelper.defaultMessagingAccount &&
                !settings.mainViewIgnoreFirstTimeDialog && mainPage.displayedThreadIndex < 0) {
                PopupUtils.open(Qt.createComponent("Dialogs/NoDefaultSIMCardDialog.qml").createObject(mainView))
            }
            for (var i in telepathyHelper.textAccounts.active) {
                connectToFavoriteChannels(telepathyHelper.textAccounts.active[i])
            }
        }
    }

    automaticOrientation: true
    implicitWidth: units.gu(90)
    implicitHeight: units.gu(71)
    anchorToKeyboard: false
    activeFocusOnPress: false
    theme.name: userTheme === "default" ? "" : userTheme

    Component.onCompleted: {
        i18n.domain = "messaging-app"
        i18n.bindtextdomain("messaging-app", i18nDirectory)

        // when running in windowed mode, do not allow resizing
        view.minimumWidth  = Qt.binding( function() { return units.gu(40) } )
        view.minimumHeight = Qt.binding( function() { return units.gu(60) } )
    }

    HistoryGroupedThreadsModel {
        id: threadModel

        function indexOf(threadId, accountId) {
            for (var i=0; i < count; i++) {
                var threads = get(i)
                for (var t=0; t < threads.length; t++) {
                    var thread = threads[t]
                    if (thread.threadId === threadId) {
                        if (accountId && (thread.accountId == accountId))
                            return i
                        else if (!accountId)
                            return i
                    }
                }
            }
            return -1
        }

        type: HistoryThreadModel.EventTypeText
        sort: HistorySort {
            sortField: {
                switch(mainView.sortThreadsBy) {
                case "title":
                    //FIXME: ThreadId works for IRC, not sure if that will work for other protocols
                    return "accountId, threadId"
                case "timestamp":
                default:
                    return "lastEventTimestamp"
                }
            }
            sortOrder: {
                switch(mainView.sortThreadsBy) {
                case "title":
                    return HistorySort.AscendingOrder
                case "timestamp":
                default:
                    return HistorySort.DescendingOrder
                }
            }
        }
        groupingProperty: "participants"
        filter: HistoryFilter {}
        matchContacts: true
    }

    Settings {
        id: settings
        category: "DualSim"
        property bool messagesDontShowFileSizeWarning: false
        property bool messagesDontAsk: false
        property bool mainViewIgnoreFirstTimeDialog: false
    }

    Settings {
        id: msgSettings
        category: "SMS"
        property bool showCharacterCount: false
    }

    Settings {
        id: globalSettings
        property string sortThreadsBy: "timestamp"
        property bool compactView: false
        property string userTheme: "default"
    }

    StickerPacksModel {
        id: stickerPacksModel
    }

    StickersModel {
        id: stickersModel
    }

    Connections {
        target: ContentHub
        onImportRequested: startImport(transfer)
        onShareRequested: startImport(transfer)
    }

    signal applicationReady

    function startsWith(string, prefix) {
        return string.toLowerCase().slice(0, prefix.length) === prefix.toLowerCase();
    }

    function getContentType(filePath) {
        var contentType = application.fileMimeType(String(filePath).replace("file://",""))
        if (startsWith(contentType, "image/")) {
            return ContentType.Pictures
        } else if (startsWith(contentType, "text/vcard") ||
                   startsWith(contentType, "text/x-vcard")) {
            return ContentType.Contacts
        } else if (startsWith(contentType, "video/")) {
            return ContentType.Videos
        }
        return ContentType.Unknown
    }

    function emptyStack(showEmpty) {
        if (typeof showEmpty === 'undefined') { showEmpty = true; }
        mainStack.removePages(mainPage)
        if (showEmpty) {
            showEmptyState()
        }
        mainPage.forceActiveFocus()
    }

    function showEmptyState() {
        if (mainStack.columns > 1 && !application.findMessagingChild("emptyStatePage")) {
            layout.addPageToNextColumn(mainPage, Qt.resolvedUrl("EmptyStatePage.qml"))
            mainPage.displayedThreadIndex = -1
        }
    }

    function startNewMessage() {
        if (!mainView.composingNewMessage) {
            var properties = {}
            showMessagesView(properties)
        }
    }

    function showMessagesView(properties) {
        layout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Messages.qml"), properties)
    }

    function getThreadsForProperties(properties) {
        var threads = []
        var account = null
        var accountId = properties["accountId"]

        // dont do anything while telepathy isnt ready
        if (!telepathyHelper.ready) {
            return threads
        }

        if (accountId == "") {
            // no accountId means fallback to phone or multimedia
            if (mainView.account) {
                account = mainView.account
            } else {
                return threads
            }
        } else {
            // if the account is passed but not found, just return
            account = telepathyHelper.accountForId(accountId)
            if (!account) {
                return threads
            }
        }

        // we need to get the threads also for account overload and fallback
        var accounts = [account]
        accounts.concat(telepathyHelper.accountOverload(account))
        accounts.concat(telepathyHelper.accountFallback(account))

        // if any of the accounts in the list is a phone account, we need to get for all available SIMs
        // FIXME: there has to be a better way for doing this.
        var accountIds = [""]
        for (var i in accounts) {
            if (accounts[i].type == AccountEntry.PhoneAccount) {
                accountIds.push(accounts[i].accountId)
            }
        }
        if (accountIds.length > 0) {
            for (var i in telepathyHelper.phoneAccounts.all) {
                var phoneAccount = telepathyHelper.phoneAccounts.all[i]
                if (accountIds.indexOf(phoneAccount.accountId) < 0) {
                    accounts.push(phoneAccount)
                }
            }
        }

        // and finally, get the threads for all accounts
        for (var i in accounts) {
            var thisAccount = accounts[i]
            var thread = threadModel.threadForProperties(thisAccount.accountId,
                                                         HistoryThreadModel.EventTypeText,
                                                         properties,
                                                         thisAccount.usePhoneNumbers ? HistoryThreadModel.MatchPhoneNumber :
                                                                                       HistoryThreadModel.MatchCaseSensitive,
                                                         false)
            // check if dict is not empty
            if (Object.keys(thread).length != 0) {
               threads.push(thread)
            }
        }
        return threads
    }

    function startChatLate(properties) {
        if (!properties && !_pendingProperties)
            return

        if (!properties)
            properties = _pendingProperties

        // make sure that is called only once, disconnect
        _pendingProperties = null
        telepathyHelper.onSetupReady.disconnect(startChatLate)

        var participantIds = []
        var accountId = ""
        var match = HistoryThreadModel.MatchCaseSensitive

        properties["threads"] = getThreadsForProperties(properties)

        if (properties.hasOwnProperty("participantIds")) {
            participantIds = properties["participantIds"]
        }

        // generate the list of participants manually if not provided
        if (!properties.hasOwnProperty("participants")) {
            var participants = []
            for (var i in participantIds) {
                var participant = {}
                participant["accountId"] = accountId
                participant["identifier"] = participantIds[i]
                participant["contactId"] = ""
                participant["alias"] = ""
                participant["avatar"] = ""
                participant["detailProperties"] = {}
                participants.push(participant)
            }
            if (participants.length != 0) {
                properties["participants"] = participants;
            }
        }

        // Try to select the corrent thread on thread list
        accountId = properties.accountId
        var threadId = properties.threadId
        if (!threadId && (properties["threads"].length > 0)) {
            threadId = properties["threads"][0].threadId
            if (!accountId)
                accountId = properties["threads"][0].accountId
        }

        if (threadId) {
            var index = threadModel.indexOf(properties.threadId, accountId)
            if (index !== -1) {
                mainPage.selectMessage(index)
                return
            }
        }
        showMessagesView(properties)
    }

    function startChat(properties) {
        if (!telepathyHelper.ready) {
            if (_pendingProperties) {
                _pendingProperties = properties
            } else {
                _pendingProperties = properties
                // wait for telepathy
                telepathyHelper.onSetupReady.connect(startChatLate)
            }
        } else {
            startChatLate(properties)
        }
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }

    AdaptivePageLayout {
        id: layout

        property var activePage: null

        anchors.fill: parent
        layouts: PageColumnsLayout {
            when: mainStack.width >= units.gu(90)
            PageColumn {
                maximumWidth: units.gu(50)
                minimumWidth: units.gu(40)
                preferredWidth: units.gu(40)
            }
            PageColumn {
                fillWidth: true
            }
        }
        asynchronous: false
        primaryPage: MainPage {
            id: mainPage
        }

        property bool completed: false

        onColumnsChanged: {
            if (layout.completed && layout.columns == 1) {
                // in 1 column mode we don't have empty state as a page, so remove it
                if (application.findMessagingChild("emptyStatePage")) {
                    emptyStack(false)
                }
            } else if (layout.completed && layout.columns == 2 && !application.findMessagingChild("emptyStatePage") && !application.findMessagingChild("fakeItem")) {
                // we only have things to do here in case no thread is selected
                emptyStack()
            }
        }
        Component.onCompleted: {
            if (layout.columns == 2 && !application.findMessagingChild("emptyStatePage")) {
                // add the empty state page if necessary
                emptyStack()
            }
            layout.completed = true;
        }
    }

    FavoriteChannels {
        id: favoriteChannelsItem
    }
}
