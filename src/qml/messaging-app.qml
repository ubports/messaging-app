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
    property bool composingNewMessage: {
        var messages = application.findMessagingChild("messagesPage")
        return messages && messages.newMessage
    }

    signal emptyStackRequested()

    activeFocusOnPress: false

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
            chatManager.acknowledgeAllMessages(participants, thread.accountId)
        }
        // at last remove the threads
        threadModel.removeThreads(threads);
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
    }

    StickerPacksModel {
        id: stickerPacksModel
    }

    StickersModel {
        id: stickersModel
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            var properties = {}
            properties["sharedAttachmentsTransfer"] = transfer
            mainView.showMessagesView(properties)
        }
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
        mainView.emptyStackRequested()
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
        var properties = {}
        showMessagesView(properties)
    }

    function showMessagesView(properties) {
        layout.addPageToNextColumn(mainPage, Qt.resolvedUrl("Messages.qml"), properties)
    }

    function startChat(identifiers, text, accountId) {
        var properties = {}
        var participantIds = identifiers.split(";")

        if (participantIds.length === 0) {
            return;
        }

        if (mainView.account) {
            var thread = threadModel.threadForParticipants(mainView.account.accountId,
                                                           HistoryThreadModel.EventTypeText,
                                                           participantIds,
                                                           mainView.account.type == AccountEntry.PhoneAccount ? HistoryThreadModel.MatchPhoneNumber
                                                                                                              : HistoryThreadModel.MatchCaseSensitive,
                                                           false)
            if (thread.hasOwnProperty("participants")) {
                properties["participants"] = thread.participants
            }
        }

        if (!properties.hasOwnProperty("participants")) {
            var participants = []
            for (var i in participantIds) {
                var participant = {}
                participant["identifier"] = participantIds[i]
                participant["contactId"] = ""
                participant["alias"] = ""
                participant["avatar"] = ""
                participant["detailProperties"] = {}
                participants.push(participant)
            }
            properties["participants"] = participants;
        }

        properties["participantIds"] = participantIds
        properties["text"] = text
        if (typeof(accountId)!=='undefined') {
            properties["accountId"] = accountId
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
                if (application.findMessagingChild("emptyStatePage")) {
                    console.log("FOOOOOOOOOOOOOOOO")
                    emptyStack()
                }
            } else if (layout.completed && layout.columns == 2 && !application.findMessagingChild("emptyStatePage") && !application.findMessagingChild("fakeItem")) {
                // we only have things to do here in case no thread is selected
                emptyStack()
            }
        }
        Component.onCompleted: {
            if (layout.columns == 2 && !application.findMessagingChild("emptyStatePage")) {
                emptyStack()
            }
            layout.completed = true;
        }
    }
}
