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
    property QtObject bottomEdge: null
    property bool composingNewMessage: bottomEdge.status === BottomEdge.Committed
    property alias inputInfo: inputInfoObject

    signal emptyStackRequested()

    activeFocusOnPress: false

    function defaultPhoneAccount() {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multiplePhoneAccounts && telepathyHelper.defaultMessagingAccount) {
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
        var initialProperties =  { "contactListPage": contactListPage,
                                   "model": contactsModel}

        if (typeof(contact) == 'string') {
            initialProperties['contactId'] = contact
        } else {
            initialProperties['contact'] = contact
        }

        mainStack.addFileToCurrentColumnSync(currentPage,
                                         Qt.resolvedUrl("MessagingContactViewPage.qml"),
                                         initialProperties)
    }

    function addNewContact(currentPage, phoneNumber, contactListPage) {
        mainStack.addFileToCurrentColumnSync(currentPage,
                                         Qt.resolvedUrl("MessagingContactEditorPage.qml"),
                                         { "contactId": contactId,
                                           "addPhoneToContact": phoneNumber,
                                           "contactListPage": contactListPage })
    }

    function addPhoneToContact(currentPage, contact, phoneNumber, contactListPage, contactsModel) {
        if (contact === "") {
            mainStack.addFileToCurrentColumnSync(currentPage,
                                             Qt.resolvedUrl("NewRecipientPage.qml"),
                                             { "phoneToAdd": phoneNumber })
        } else {
            var initialProperties = { "addPhoneToContact": phoneNumber,
                                      "contactListPage": contactListPage,
                                      "model": contactsModel }
            if (typeof(contact) == 'string') {
                initialProperties['contactId'] = contact
            } else {
                initialProperties['contact'] = contact
            }
            mainStack.addFileToCurrentColumnSync(currentPage,
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

    function showBottomEdgePage(properties) {
        bottomEdge.commitWithProperties(properties)
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
    width: units.gu(90)
    height: units.gu(71)
    anchorToKeyboard: false

    Component.onCompleted: {
        i18n.domain = "messaging-app"
        i18n.bindtextdomain("messaging-app", i18nDirectory)

        // when running in windowed mode, do not allow resizing
        view.minimumWidth  = units.gu(40)
        view.minimumHeight = units.gu(60)
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
            emptyStack()
            properties["sharedAttachmentsTransfer"] = transfer
            mainView.showBottomEdgePage(properties)
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

    function emptyStack() {
        mainView.emptyStackRequested()
        mainStack.removePage(mainPage)
        layout.deleteInstances()
        showEmptyState()
        mainPage.displayedThreadIndex = -1
    }

    function showEmptyState() {
        if (mainStack.columns > 1 && !application.findMessagingChild("emptyStatePage")) {
            layout.addComponentToNextColumnSync(mainPage, emptyStatePageComponent)
        }
    }

    function startNewMessage() {
        var properties = {}
        emptyStack()
        mainView.showBottomEdgePage(properties)
    }

    function startChat(properties) {
        var participantIds = []
        var threadId = ""
        var accountId = ""
        var chatType = 0
        var match = HistoryThreadModel.MatchCaseSensitive;

        if (properties.hasOwnProperty("participantIds")) {
            participantIds = properties["participantIds"]
        }

        if (properties.hasOwnProperty("threadId")) {
            threadId = properties["threadId"]
        }

        // fallback account if none is provided
        if (properties.hasOwnProperty("accountId")) {
            accountId = properties["accountId"]
        } else {
            accountId = mainView.account ? mainView.account.accountId : ""
        }

        // we might have changed the accountId, so we set it again
        properties["accountId"] = accountId

        if (accountId != "") {
            var tmpAccount = telepathyHelper.accountForId(accountId)
            if (tmpAccount && (tmpAccount.type == AccountEntry.PhoneAccount || AccountEntry.MultimediaAccount)) {
                match = HistoryThreadModel.MatchPhoneNumber
            }
        } else {
            // if no accountId is provided fallback to phone
            match = HistoryThreadModel.MatchPhoneNumber
        }

        if (properties.hasOwnProperty("chatType")) {
            chatType = parseInt(properties["chatType"])
        } else {
            // try to guess chatType based on participants
            if (participantIds.length == 1) {
                chatType = 1
                properties["chatType"] = chatType;
            }
        }

        // we need a list of participants for chatTypes: None or Contact
        if (participantIds.length === 0 && (chatType == 0 || chatType == 1)) {
            return;
        }

        if (accountId != "") {
            var thread = threadModel.threadForProperties(accountId,
                                                         HistoryThreadModel.EventTypeText,
                                                         properties,
                                                         match,
                                                         false)
            properties["threads"] = [thread]

            if (thread.hasOwnProperty("participants")) {
                properties["participants"] = thread.participants
            }
        }

        // generate the list of participants manually if not provided
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

        emptyStack()
        // FIXME: AdaptivePageLayout takes a really long time to create pages,
        // so we create manually and push that
        mainStack.addComponentToNextColumnSync(mainPage, messagesWithBottomEdge, properties)
    }

    InputInfo {
        id: inputInfoObject
    }

    // WORKAROUND: Due the missing feature on SDK, they can not detect if
    // there is a mouse attached to device or not. And this will cause the
    // bootom edge component to not work correct on desktop.
    Binding {
        target:  QuickUtils
        property: "mouseAttached"
        value: inputInfo.hasMouse
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
        id: messagesWithBottomEdge

        Messages {
            id: messages
            height: mainPage.height

            Component.onCompleted: mainPage._messagesPage = messages
            Loader {
                id: messagesBottomEdgeLoader
                active: mainView.dualPanel
                sourceComponent: MessagingBottomEdge {
                    id: messagesBottomEdge
                    parent: messages
                    hint.text: ""
                    hint.height: 0
                }
            }
        }
    }

    Component {
        id: emptyStatePageComponent
        Page {
            id: emptyStatePage
            objectName: "emptyStatePage"

            function deleteMe() {
                emptyStatePage.destroy(1)
                emptyStatePage.objectName = ""
            }

            Connections {
                target: layout
                onColumnsChanged: {
                    if (layout.columns == 1) {
                        emptyStatePage.deleteMe()
                        if (!application.findMessagingChild("fakeItem")) {
                            layout.removePage(mainPage)
                        }
                    }
                }
            }

            Connections {
                target: mainView
                onEmptyStackRequested: {
                    emptyStatePage.deleteMe()
                }
            }

            EmptyState {
                labelVisible: false
            }

            header: PageHeader { }

            Loader {
                id: bottomEdgeLoader
                sourceComponent: MessagingBottomEdge {
                    parent: emptyStatePage
                    hint.text: ""
                    hint.height: 0
                }
            }
        }
    }

    MessagingPageLayout {
        id: layout
        anchors.fill: parent
        primaryPage: MainPage {
            id: mainPage
        }

        onColumnsChanged: {
            // we only have things to do here in case no thread is selected
            if (layout.columns == 2 && !application.findMessagingChild("emptyStatePage") && !application.findMessagingChild("fakeItem")) {
                layout.removePage(mainPage)
                emptyStack()
            }
        }
        Component.onCompleted: {
            if (layout.columns == 2 && !application.findMessagingChild("emptyStatePage")) {
                emptyStack()
            }
        }
    }
}
