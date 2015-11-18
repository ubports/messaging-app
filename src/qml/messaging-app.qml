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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.Content 0.1
import Ubuntu.History 0.1

MainView {
    id: mainView

    property string newPhoneNumber
    property bool multipleAccounts: telepathyHelper.activeAccounts.length > 1
    property QtObject account: defaultAccount()
    property bool applicationActive: Qt.application.active

    activeFocusOnPress: false

    function defaultAccount() {
        // we only use the default account property if we have more
        // than one account, otherwise we use always the first one
        if (multipleAccounts) {
            return telepathyHelper.defaultMessagingAccount
        } else {
            return telepathyHelper.activeAccounts[0]
        }
    }

    function showContactDetails(contact, contactListPage, contactsModel) {
        var initialProperties =  { "contactListPage": contactListPage,
                                   "model": contactsModel}

        if (typeof(contact) == 'string') {
            initialProperties['contactId'] = contact
        } else {
            initialProperties['contact'] = contact
        }

        mainStack.push(Qt.resolvedUrl("MessagingContactViewPage.qml"),
                       initialProperties)
    }

    function addNewContact(phoneNumber, contactListPage) {
        mainStack.push(Qt.resolvedUrl("MessagingContactEditorPage.qml"),
                       { "contactId": contactId,
                         "addPhoneToContact": phoneNumber,
                         "contactListPage": contactListPage })
    }

    function addPhoneToContact(contact, phoneNumber, contactListPage, contactsModel) {
        if (contact === "") {
            mainStack.push(Qt.resolvedUrl("NewRecipientPage.qml"),
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
            mainStack.push(Qt.resolvedUrl("MessagingContactViewPage.qml"),
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
            account = Qt.binding(defaultAccount)
        }
        onDefaultMessagingAccountChanged: account = Qt.binding(defaultAccount)
    }


    automaticOrientation: true
    width: units.gu(40)
    height: units.gu(71)
    anchorToKeyboard: false

    Component.onCompleted: {
        i18n.domain = "messaging-app"
        i18n.bindtextdomain("messaging-app", i18nDirectory)
    }

    Connections {
        target: telepathyHelper
        onSetupReady: {
            if (multipleAccounts && !telepathyHelper.defaultMessagingAccount &&
                settings.mainViewDontAskCount < 3 && mainStack.depth === 1) {
                // FIXME: soon it will be more than just SIM cards, update the dialog accordingly
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
        property bool messagesDontAsk: false
        property int mainViewDontAskCount: 0
    }

    Connections {
        target: ContentHub
        onShareRequested: {
            var properties = {}
            emptyStack()
            properties["sharedAttachmentsTransfer"] = transfer
            mainStack.currentPage.showBottomEdgePage(Qt.resolvedUrl("Messages.qml"), properties)
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
        while (mainStack.depth !== 1 && mainStack.depth !== 0) {
            mainStack.pop()
        }
    }

    function startNewMessage() {
        var properties = {}
        emptyStack()
        mainStack.currentPage.showBottomEdgePage(Qt.resolvedUrl("Messages.qml"))
    }

    function startChat(identifiers, text) {
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
                                                           true)
            properties["participants"] = thread.participants
        } else {
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
        emptyStack()
        mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
    }

    Connections {
        target: UriHandler
        onOpened: {
           for (var i = 0; i < uris.length; ++i) {
               application.parseArgument(uris[i])
           }
       }
    }


    PageStack {
        id: mainStack

        objectName: "mainStack"
        Component.onCompleted: mainStack.push(Qt.resolvedUrl("MainPage.qml"))
    }
}
