/*
 * Copyright 2012-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Content 1.3
import Ubuntu.History 0.1
import "Stickers"

MainView {
    id: mainView

    property bool multiplePhoneAccounts: {
        var numAccounts = 0
        for (var i in telepathyHelper.activeAccounts) {
            if (telepathyHelper.activeAccounts[i].type == AccountEntry.PhoneAccount) {
                numAccounts++
            }
        }
        return numAccounts > 1
    }
    property QtObject account: defaultPhoneAccount()
    property bool applicationActive: Qt.application.active
    property alias mainStack: layout
    property bool dualPanel: mainStack.columns > 1
    property bool composingNewMessage: activeMessagesView && activeMessagesView.newMessage
    property QtObject activeMessagesView: null
    property QtObject multimediaAccount: {
        for (var i in telepathyHelper.accounts) {
            var tmpAccount = telepathyHelper.accounts[i]
            // TODO: check for accounts that support room channels
            if (tmpAccount.type == AccountEntry.MultimediaAccount && tmpAccount.connected) {
                return tmpAccount
            }
        }
        return null
    }

    function updateNewMessageStatus() {
        activeMessagesView = application.findMessagingChild("messagesPage", "active", true)
    }

    function defaultPhoneAccount() {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multiplePhoneAccounts) {
            return telepathyHelper.defaultMessagingAccount
        } else {
            for (var i in telepathyHelper.activeAccounts) {
                var tmpAccount = telepathyHelper.activeAccounts[i]
                if (tmpAccount.type == AccountEntry.PhoneAccount) {
                    return tmpAccount
                }
            }
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

    function addPhoneToContact(currentPage, contact, phoneNumber, contactListPage, contactsModel) {
        if (contact === "") {
            mainStack.addPageToCurrentColumn(currentPage,
                                             Qt.resolvedUrl("NewRecipientPage.qml"),
                                             { "phoneToAdd": phoneNumber })
        } else {
            var initialProperties = { "addPhoneToContact": phoneNumber }
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

    onApplicationActiveChanged: {
        if (applicationActive) {
            telepathyHelper.registerChannelObserver()
        } else {
            telepathyHelper.unregisterChannelObserver()
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

    Connections {
        target: telepathyHelper
        // restore default bindings if any system settings changed
        onActiveAccountsChanged: {
            for (var i in telepathyHelper.activeAccounts) {
                if (telepathyHelper.activeAccounts[i] == account) {
                    return;
                }
            }
            account = Qt.binding(defaultPhoneAccount)
        }
        onDefaultMessagingAccountChanged: account = Qt.binding(defaultPhoneAccount)
    }

    automaticOrientation: true
    implicitWidth: units.gu(90)
    implicitHeight: units.gu(71)
    anchorToKeyboard: false
    activeFocusOnPress: false

    Component.onCompleted: {
        i18n.domain = "messaging-app"
        i18n.bindtextdomain("messaging-app", i18nDirectory)

        // when running in windowed mode, do not allow resizing
        view.minimumWidth  = Qt.binding( function() { return units.gu(40) } )
        view.minimumHeight = Qt.binding( function() { return units.gu(60) } )
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            if (multiplePhoneAccounts && !telepathyHelper.defaultMessagingAccount &&
                !settings.mainViewIgnoreFirstTimeDialog && mainPage.displayedThreadIndex < 0) {
                PopupUtils.open(Qt.createComponent("Dialogs/NoDefaultSIMCardDialog.qml").createObject(mainView))
            }
        }
    }

    HistoryGroupedThreadsModel {
        id: threadModel
        type: HistoryThreadModel.EventTypeText
        sort: HistorySort {
            sortField: "lastEventTimestamp"
            sortOrder: HistorySort.DescendingOrder
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
        property bool messagesDontShowEmptyGroupWarning: false
    }

    Settings {
        id: msgSettings
        category: "SMS"
        property bool showCharacterCount: false
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
        mainPage.displayedThreadIndex = -1
    }

    function showEmptyState() {
        if (mainStack.columns > 1 && !application.findMessagingChild("emptyStatePage")) {
            layout.addPageToNextColumn(mainPage, emptyStatePageComponent)
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
                account = mainView.account.accountId 
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


        // on phone and multimedia accounts we need to get threads for all available accounts
        switch(account.type) {
        case AccountEntry.PhoneAccount:
        case AccountEntry.MultimediaAccount:
            // get all accounts for phone and multimedia
            for (var i in [AccountEntry.PhoneAccount, AccountEntry.MultimediaAccount]) {
                var thisAccounts = telepathyHelper.accountsForType(i)
                for (var j in thisAccounts) {
                    var thisAccountId = telepathyHelper.accountForId(thisAccounts[j].accountId)
                    var thread = threadModel.threadForProperties(thisAccountId,
                                                                 HistoryThreadModel.EventTypeText,
                                                                 properties,
                                                                 HistoryThreadModel.MatchPhoneNumber,
                                                                 false)
                    // check if dict is not empty
                    if (Object.keys(thread).length != 0) {
                       threads.push(thread)
                    }
                }
            }
            break;
        case AccountEntry.GenericAccount:
            var thread = threadModel.threadForProperties(accountId,
                                                         HistoryThreadModel.EventTypeText,
                                                         properties,
                                                         HistoryThreadModel.MatchCaseSensitive,
                                                         false)
            // check if dict is not empty
            if (Object.keys(thread).length != 0) {
               threads.push(thread)
            }
            break;
        }
        return threads
    }

    function startChat(properties) {
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

        showMessagesView(properties)
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }

    Component {
        id: emptyStatePageComponent
        Page {
            id: emptyStatePage
            objectName: "emptyStatePage"

            EmptyState {
                labelVisible: false
            }

            header: PageHeader { }
        }
    }

    AdaptivePageLayout {
        id: layout
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
}
