/*
 * Copyright 2015-2016 Canonical Ltd.
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


    ListModel {
        id: messagesModel
        ListElement {
            accountId: "ofono/ofono/account0"
            threadId: "1234567"
            participants: []
            type: HistoryThreadModel.EventTypeText
            properties: []
            eventId: "id1"
            senderId: "1234567"
            timestamp: 1439486685400
            date: ""
            newEvent: true
            textMessage: "test"
            textMessageType: HistoryThreadModel.MessageTypeText
            textMessageStatus: HistoryThreadModel.MessageStatusDelivered
            textMessageAttachments: []
            textReadTimestamp: 1439486685400
            textSubject: ""
            remoteParticipant: ""
        }
        ListElement {
            accountId: "ofono/ofono/account0"
            threadId: "1234567"
            participants: []
            type: HistoryThreadModel.EventTypeText
            properties: []
            eventId: "id2"
            senderId: "1234567"
            timestamp: 1439486685400
            date: ""
            newEvent: true
            textMessage: "test2"
            textMessageType: HistoryThreadModel.MessageTypeText
            textMessageStatus: HistoryThreadModel.MessageStatusDelivered
            textMessageAttachments: []
            textReadTimestamp: 1439486685400
            textSubject: ""
            remoteParticipant: ""
        }
    }

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

    Item {
        id: telepathyHelper
        function registerChannelObserver() {}
        function unregisterChannelObserver() {}
        property var activeAccounts: [testAccount]
        property alias accounts: telepathyHelper.activeAccounts

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
        id: chatManager
        signal messageAcknowledged
        function acknowledgeMessage(recipients, messageId, accountId) {
            chatManager.messageAcknowledged(recipients, messageId, accountId)
        }
    }

    Loader {
        id: mainViewLoader
        property string i18nDirectory: ""
        source: '../../src/qml/messaging-app.qml'
    }

    SignalSpy {
       id: messageAcknowledgeSpy
       target: chatManager
       signalName: "messageAcknowledged"
    }

    UbuntuTestCase {
        id: swipeItemTestCase
        name: 'swipeItemTestCase'

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

        function test_messagesViewAcknowledgeMessage() {
            var senderId = "1234567"
            var stack = findChild(mainViewLoader, "mainStack")
            tryCompare(mainViewLoader.item, 'applicationActive', true)
            // if messaging-app has no account set, it will not try to get the thread from history
            // and instead will generate the list of participants, take advantage of that
            var account = mainViewLoader.item.account
            mainViewLoader.item.account = null
            var properties = {}
            properties["participantIds"] = [senderId]
            mainViewLoader.item.startChat(properties)
            mainViewLoader.item.account = account
            var messageList
            while (true) {
                messageList = findChild(mainViewLoader, "messageList")
                if (messageList) {
                    break
                }
                wait(200)
            }

            messageList.listModel = messagesModel
            tryCompare(messageList, 'count', 2)
            compare(messageAcknowledgeSpy.count, 0)
            mainViewLoader.item.applicationActive = true
            tryCompare(messageAcknowledgeSpy, 'count', 2)
        }
    }
}
