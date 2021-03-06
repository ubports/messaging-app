/*
 * Copyright 2016 Canonical Ltd.
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
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.History 0.1

Item {
    id: root

    width: units.gu(40)
    height: units.gu(70)


    Item {
        id: application
        function findMessagingChild(name)
        {
            return null
        }
    }

    QtObject {
        id: testAccount
        property string accountId: "ofono/ofono/account0"
        property var emergencyNumbers: [ "444", "555"]
        property int type: AccountEntry.PhoneAccount
        property string displayName: "SIM 1"
        property bool connected: true
        property bool emergencyCallsAvailable: true
        property bool active: true
        property string networkName: "Network name"
        property bool simLocked: false
        property var addressableVCardFields: ["tel"]
    }

    QtObject {
        id: testAccount2
        property string accountId: "ofono/ofono/account1"
        property var emergencyNumbers: [ "444", "555"]
        property int type: AccountEntry.PhoneAccount
        property string displayName: "SIM 2"
        property bool connected: true
        property bool emergencyCallsAvailable: true
        property bool active: true
        property string networkName: "Network name 2"
        property bool simLocked: false
        property var addressableVCardFields: ["tel"]
    }

    Item {
        id: telepathyHelper
        property var activeAccounts: [testAccount, testAccount2]
        property alias accounts: telepathyHelper.activeAccounts        
        property QtObject defaultMessagingAccount: null
        property bool flightMode: false
        function registerChannelObserver() {}
        function unregisterChannelObserver() {}
        function accountForId(accountId) {
            for (var i in accounts) {
               if (accounts[i].accountId == accountId) {
                  return accounts[i]
               }
            }
            return null
        }

        function accountOverload(account) {
            return []
        }

        function accountFallback(account) {
            return []
        }

        property alias textAccounts: textAccountsItem
        property alias phoneAccounts: phoneAccountsItem

        Item {
            id: textAccountsItem
            property alias all: telepathyHelper.activeAccounts
            property alias active: telepathyHelper.activeAccounts
            property alias displayed: telepathyHelper.activeAccounts
        }

        Item {
            id: phoneAccountsItem
            property alias all: telepathyHelper.activeAccounts
            property alias active: telepathyHelper.activeAccounts
            property alias displayed: telepathyHelper.activeAccounts
        }
    }

    Item {
        id: chatEntryObject
        property int chatType: 1
        property var participants: []
        property var chatId: ""
        property var accountId: testAccount.accountId

        signal messageSent(string accountId, string text, var attachments, var properties)

        function setChatState(state) {}
        function sendMessage(accountId, text, attachments, properties) {
            chatEntryObject.messageSent(accountId, text, attachments, properties)
        }
    }

    Loader {
        id: mainViewLoader
        active: false
        property string i18nDirectory: ""
        source: '../../src/qml/messaging-app.qml'
    }

    SignalSpy {
       id: messageSentSpy
       target: chatEntryObject
       signalName: "messageSent"
    }

    UbuntuTestCase {
        id: dualSim
        name: 'dualSim'

        when: windowShown

        // we reimplement the function here and add a special
        // case to deal with a null child without failing
        function findChild(obj,objectName) {
            var childs = new Array(0);
            childs.push(obj)
            while (childs.length > 0) {
                // this is the special case
                if (!childs[0]) {
                    childs.splice(0, 1);
                    continue
                }
                if (childs[0].objectName == objectName) {
                    return childs[0]
                }
                for (var i in childs[0].children) {
                    childs.push(childs[0].children[i])
                }
                childs.splice(0, 1);
            }
            return null;
        }

        function waitFindChild(obj,objectName) {
            var child = findChild(obj, objectName);
            var timeout = 3000;
            var interval = 50;
            while (!child && timeout > 0) {
                wait(interval)
                timeout -= interval
                child = findChild(obj, objectName)
            }
            return child
        }

        function init() {
        }

        function cleanup() {
        }

        function test_checkDefaultSimSelected() {
            mainViewLoader.active = false
            mainViewLoader.active = true
            tryCompare(mainViewLoader.item, 'applicationActive', true)

            mainViewLoader.item.startNewMessage()
            waitForRendering(mainViewLoader.item)

            var messagesView = waitFindChild(mainViewLoader, "messagesPage")
            var headerSections = findChild(messagesView, "headerSections")
            compare(headerSections.selectedIndex, -1)

            var sendButton = findChild(messagesView, "sendButton")
            var textArea = findChild(messagesView, "messageTextArea")
            var contactSearchInput = findChild(messagesView, "contactSearchInput")
            contactSearchInput.text = "123"
            textArea.text = "test text"
            // on vivid mouseClick() does not work here
            messagesView.chatEntry = chatEntryObject
            sendButton.clicked()

            var dialogButton = findChild(root, "closeInformationDialog")
            compare(dialogButton == null, false)
            mouseClick(dialogButton)

            telepathyHelper.defaultMessagingAccount = testAccount
            mainViewLoader.active = false
            mainViewLoader.active = true
            tryCompare(mainViewLoader.item, 'applicationActive', true)

            mainViewLoader.item.startNewMessage()
            waitForRendering(mainViewLoader.item)

            messagesView = waitFindChild(mainViewLoader, "messagesPage")
            headerSections = findChild(messagesView, "headerSections")

            compare(headerSections.selectedIndex, 0)

            telepathyHelper.defaultMessagingAccount = testAccount2
            mainViewLoader.active = false
            mainViewLoader.active = true
            tryCompare(mainViewLoader.item, 'applicationActive', true)

            mainViewLoader.item.startNewMessage()
            waitForRendering(mainViewLoader.item)


            messagesView = waitFindChild(mainViewLoader, "messagesPage")
            headerSections = findChild(messagesView, "headerSections")
            compare(headerSections.selectedIndex, 1)

            var properties = {}
            properties["accountId"] = testAccount.accountId
            properties["participantIds"] = ["123"]
            mainViewLoader.item.startChat(properties)
            waitForRendering(mainViewLoader.item)

            messagesView = waitFindChild(mainViewLoader, "messagesPage")
            headerSections = findChild(messagesView, "headerSections")
            compare(headerSections.selectedIndex, 1)

        }

        function test_messageSentViaRightSim() {
            telepathyHelper.defaultMessagingAccount = testAccount2
            mainViewLoader.active = false
            mainViewLoader.active = true

            tryCompare(mainViewLoader.item, 'applicationActive', true)

            mainViewLoader.item.startNewMessage()
            waitForRendering(mainViewLoader.item)

            var messagesView = waitFindChild(mainViewLoader, "messagesPage")
            var textArea = findChild(messagesView, "messageTextArea")
            var contactSearchInput = findChild(messagesView, "contactSearchInput")
            var sendButton = findChild(messagesView, "sendButton")
            contactSearchInput.text = "123"
            textArea.text = "test text"
            // on vivid mouseClick() does not work here
            messagesView.chatEntry = chatEntryObject
            sendButton.clicked()
            tryCompare(messageSentSpy, 'count', 1)
            tryCompare(telepathyHelper.defaultMessagingAccount, 'accountId', messageSentSpy.signalArguments[0][0])
        }
    }
}
