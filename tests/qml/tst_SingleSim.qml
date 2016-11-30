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
import "../../src/qml"

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
        property var protocolInfo: Item {
            property bool showOnSelector: true
        }
    }

    Item {
        id: telepathyHelper
        property bool flightMode: false
        property var activeAccounts: [testAccount]
        property alias accounts: telepathyHelper.activeAccounts
        property QtObject defaultMessagingAccount: null
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

    Item {
        id: mainView
        property var account: testAccount
        property bool applicationActive: true
        function updateNewMessageStatus() {}
    }

    Messages {
        id: messagesView
        active: true
    }

    SignalSpy {
       id: messageSentSpy
       target: chatEntryObject
       signalName: "messageSent"
    }

    UbuntuTestCase {
        id: singleSim
        name: 'singleSim'

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

        function init() {
        }

        function cleanup() {
        }

        function test_messageSentViaOnlySim() {
            waitForRendering(messagesView)

            var textArea = findChild(messagesView, "messageTextArea")
            var contactSearchInput = findChild(messagesView, "contactSearchInput")
            var sendButton = findChild(messagesView, "sendButton")
            contactSearchInput.text = "123"
            textArea.text = "test text"
            messagesView.chatEntry = chatEntryObject
            // on vivid mouseClick() does not work here
            sendButton.clicked()
            tryCompare(messageSentSpy, 'count', 1)
            tryCompare(testAccount, 'accountId', messageSentSpy.signalArguments[0][0])
        }
    }
}
