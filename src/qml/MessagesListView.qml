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

import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1

import "dateUtils.js" as DateUtils

MultipleSelectionListView {
    id: root

    property var _currentSwipedItem: null
    property string latestEventId: ""
    property var account: null

    function shareSelectedMessages()
    {
        var aggregatedText = [];
        var transfer = {}
        var items = []
        for (var i = root.selectedItems.count -1; i >= 0 ; i--) {
            var event = root.selectedItems.get(i).model
            for (var j = 0; j < event.textMessageAttachments.length; j++) {
                var attachment = event.textMessageAttachments[j]
                var item = {"text":"", "url":""}
                var hasAttachmentText = false
                var contentType = application.fileMimeType(String(attachment.filePath))
                // we dont include smil files. they will be auto generated
                if (startsWith(contentType.toLowerCase(), "application/smil")) {
                    continue
                }
                if (startsWith(contentType.toLowerCase(), "text/plain")) {
                    item["text"] = application.readTextFile(attachment.filePath)
                    hasAttachmentText = true
                    items.push(item)
                    continue
                }
                item["url"] = "file://" + attachment.filePath
                items.push(item)
            }
            if (event.textMessage !== "" && !hasAttachmentText) {
                aggregatedText.push(event.textMessage)
            }
        }
        if (aggregatedText.length > 0) {
            items.push({"text": aggregatedText.join("\n"), "url":""})
        }
        var properties = {}
        var transfer = {}
        transfer["items"] = items

        properties["sharedAttachmentsTransfer"] = transfer
        mainView.showMessagesView(properties)

        root.cancelSelection()
    }

    // fake bottomMargin
    header: Item {
        height: units.gu(1)
    }
    verticalLayoutDirection: ListView.BottomToTop
    highlightFollowsCurrentItem: true
    currentIndex: 0
    spacing: units.gu(1)

    listDelegate: Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        height: status == Loader.Ready ? item.height : 0

        Component.onCompleted: {
            var properties = {"messageData": model,
                              "index": Qt.binding(function(){ return index }),
                              "delegateItem": Qt.binding(function(){ return loader })}
            var sourceFile =textMessageType == HistoryThreadModel.MessageTypeInformation ? "AccountSectionDelegate.qml" : "RegularMessageDelegate.qml"
            sourceFile = application.delegateFromProtocol(Qt.resolvedUrl(sourceFile), account ? account.protocolInfo.name : "")
            loader.setSource(sourceFile, properties)
        }

        Binding {
            target: loader.item
            property: "account"
            value: root.account
            when: (textMessageType !== HistoryThreadModel.MessageTypeInformation && Loader.Ready)
        }
    }

    onSelectionDone: {
        var removeDividers = (items.count == eventModel.count)
        var events = [];
        for (var i=0; i < items.count; i++) {
            var event = items.get(i).model
            if (!removeDividers && event.textMessageType == HistoryThreadModel.MessageTypeInformation) {
                continue;
            }
            events.push(event.properties);
        }
        if (events.length > 0) {
            eventModel.removeEvents(events);
        }
    }

    Timer {
        id: newMessageTimer
        interval: 50
        repeat: false
        onTriggered: positionViewAtBeginning()
    }

    onCountChanged: {
        if (count == 0) {
            latestEventId = ""
            return
        }
        if (latestEventId == "") {
            latestEventId = eventModel.get(0).eventId
        } else if (latestEventId != eventModel.get(0).eventId) {
            latestEventId = eventModel.get(0).eventId
            newMessageTimer.start()
        }
    }
}
