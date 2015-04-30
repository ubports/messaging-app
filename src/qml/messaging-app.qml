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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Content 0.1
import Ubuntu.History 0.1

MainView {
    id: mainView

    property string newPhoneNumber
    property bool multipleAccounts: telepathyHelper.activeAccounts.length > 1
    property QtObject account: defaultAccount()
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

    function showContactDetails(contactId) {
        mainStack.push(Qt.resolvedUrl("MessagingContactViewPage.qml"),
                       { "contactId": contactId })
    }

    function addNewContact(phoneNumber, contactListPage) {
        mainStack.push(Qt.resolvedUrl("MessagingContactEditorPage.qml"),
                       { "contactId": contactId,
                         "addPhoneToContact": phoneNumber,
                         "contactListPage": contactListPage })
    }

    function addPhoneToContact(contactId, phoneNumber, contactListPage) {
        if (contactId === "") {
            mainStack.push(Qt.resolvedUrl("NewRecipientPage.qml"),
                           { "phoneToAdd": phoneNumber })
        } else {
            mainStack.push(Qt.resolvedUrl("MessagingContactViewPage.qml"),
                           { "contactId": contactId,
                             "addPhoneToContact": phoneNumber,
                             "contactListPage": contactListPage })
        }
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
    useDeprecatedToolbar: false
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
        filter: HistoryFilter {}
        groupingProperty: "participants"
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

    function startChat(phoneNumbers, text) {
        var properties = {}
        var participants = phoneNumbers.split(";")
        properties["participants"] = participants
        properties["text"] = text
        emptyStack()
        if (participants.length === 0) {
            return;
        }
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
