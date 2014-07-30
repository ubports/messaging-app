/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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

import QtQuick 2.0
import QtQuick.Window 2.0
import QtContacts 5.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.Content 0.1
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import Ubuntu.Contacts 0.1
import QtContacts 5.0

Page {
    id: messages
    objectName: "messagesPage"
    // FIXME this info must come from system settings or telephony-service
    property var accounts: {"ofono/ofono/account0": "SIM 1", "ofono/ofono/account1": "SIM 2"}
    property string accountId: telepathyHelper.accountIds[0]
    property bool multipleAccounts: telepathyHelper.accountIds.length > 1
    property variant participants: []
    property bool groupChat: participants.length > 1
    property bool keyboardFocus: true
    property alias selectionMode: messageList.isInSelectionMode
    // FIXME: MainView should provide if the view is in portait or landscape
    property int orientationAngle: Screen.angleBetween(Screen.primaryOrientation, Screen.orientation)
    property bool landscape: orientationAngle == 90 || orientationAngle == 270
    property bool pendingMessage: false
    property var activeTransfer: null
    property int activeAttachmentIndex: -1
    property var sharedAttachmentsTransfer: []
    property string lastFilter: ""
    property string text: ""

    function addAttachmentsToModel(transfer) {
        for (var i = 0; i < transfer.items.length; i++) {
            var attachment = {}
            if (!startsWith(String(transfer.items[i].url),"file://")) {
                messages.text = String(transfer.items[i].url)
                continue
            }
            var filePath = String(transfer.items[i].url).replace('file://', '')
            // get only the basename
            attachment["contentType"] = application.fileMimeType(filePath)
            if (startsWith(attachment["contentType"], "text/vcard") ||
                startsWith(attachment["contentType"], "text/x-vcard")) {
                attachment["name"] = "contact.vcf"
            } else {
                attachment["name"] = filePath.split('/').reverse()[0]
            }
            attachment["filePath"] = filePath
            attachments.append(attachment)
        }
    }

    function checkNetwork() {
        return telepathyHelper.isAccountConnected(messages.accountId)
    }

    ListModel {
        id: attachments
    }

    Connections {
        target: activeTransfer !== null ? activeTransfer : null
        onStateChanged: {
            var done = ((activeTransfer.state === ContentTransfer.Charged) ||
                        (activeTransfer.state === ContentTransfer.Aborted));

            if (activeTransfer.state === ContentTransfer.Charged) {
                if (activeTransfer.items.length > 0) {
                    addAttachmentsToModel(activeTransfer)
                    textEntry.forceActiveFocus()
                }
            }
        }
    }

    flickable: null

    property bool isReady: false
    signal ready
    onReady: {
        isReady = true
        if (participants.length === 0 && keyboardFocus)
            multiRecipient.forceFocus()
    }

    title: {
        if (selectionMode) {
            return i18n.tr("Edit")
        }

        if (landscape) {
            return ""
        }
        if (participants.length > 0) {
            var firstRecipient = ""
            if (contactWatcher.isUnknown) {
                firstRecipient = contactWatcher.phoneNumber
            } else {
                firstRecipient = contactWatcher.alias
            }
            if (participants.length == 1) {
                return firstRecipient
            } else {
                return i18n.tr("Group (%1 members)").arg(participants.length)
            }
        }
        return i18n.tr("New Message")
    }

    Component.onCompleted: {
        updateFilters()
        addAttachmentsToModel(sharedAttachmentsTransfer)
    }

    function updateFilters() {
        if (participants.length == 0) {
            eventModel.filter = null
            return
        }
        var componentUnion = "import Ubuntu.History 0.1; HistoryUnionFilter { %1 }"
        var componentFilters = ""
        for (var i = 0; i < telepathyHelper.accountIds.length; i++) {
            var filterValue = eventModel.threadIdForParticipants(telepathyHelper.accountIds[i],
                                                                 HistoryThreadModel.EventTypeText,
                                                                 participants,
                                                                 HistoryThreadModel.MatchPhoneNumber)
            if (filterValue === "") {
                continue
            }
            componentFilters += 'HistoryFilter { filterProperty: "threadId"; filterValue: "%1" } '.arg(filterValue)
        }
        if (componentFilters === "") {
            eventModel.filter = null
            lastFilter = ""
            return
        }
        if (componentFilters != lastFilter) {
            var finalString = componentUnion.arg(componentFilters)
            eventModel.filter = Qt.createQmlObject(finalString, eventModel)
            lastFilter = componentFilters
        }
    }

    function markMessageAsRead(accountId, threadId, eventId, type) {
        chatManager.acknowledgeMessage(participants[0], eventId, accountId)
        return eventModel.markEventAsRead(accountId, threadId, eventId, type);
    }

    ContentPeer {
        id: defaultSource
        contentType: ContentType.Pictures
        handler: ContentHandler.Source
        selectionType: ContentTransfer.Single
    }

    Component {
        id: attachmentPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard {
                    text: i18n.tr("Remove")
                    onClicked: {
                        attachments.remove(activeAttachmentIndex)
                        PopupUtils.close(popover)
                    }
                }
            }
            Component.onDestruction: activeAttachmentIndex = -1
        }
    }

    Component {
        id: participantsPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                Repeater {
                    model: participants
                    Item {
                        height: childrenRect.height
                        width: popover.width
                        ListItem.Standard {
                            id: listItem
                            text: contactWatcher.isUnknown ? contactWatcher.phoneNumber : contactWatcher.alias
                        }
                        ContactWatcher {
                            id: contactWatcher
                            phoneNumber: modelData
                        }
                    }
                }
            }
        }
    }

    Component {
        id: noNetworkDialog
        Dialog {
            id: dialogue
            title: i18n.tr("No network")
            text: multipleAccounts ? i18n.tr("There is currently no network on %1").arg(messages.accounts[messages.accountId]) : i18n.tr("There is currently no network.")
            Button {
                objectName: "closeNoNetworkDialog"
                text: i18n.tr("Close")
                color: UbuntuColors.orange
                onClicked: {
                    PopupUtils.close(dialogue)
                    Qt.inputMethod.hide()
                }
            }
        }
    }

    head.sections.model: {
        // does not show dual sim switch if there is only one sim
        if (telepathyHelper.accountIds.length <= 1) {
            return []
        }

        var accountNames = []
        for(var i=0; i < telepathyHelper.accountIds.length; i++) {
            var accountId = telepathyHelper.accountIds[i]
            accountNames.push(messages.accounts[accountId])
        }
        return accountNames
    }
    head.sections.selectedIndex: Math.max(0, telepathyHelper.accountIds.indexOf(messages.accountId))
    Connections {
        target: messages.head.sections
        onSelectedIndexChanged: {
            messages.accountId = telepathyHelper.accountIds[head.sections.selectedIndex]
        }
    }

    Component {
        id: contactSearchComponent

        ContactListView {
            id: contactSearch

            detailToPick: ContactDetail.PhoneNumber
            clip: true
            z: 1
            autoUpdate: false
            filterTerm: multiRecipient.searchString
            showSections: false

            states: [
                State {
                    name: "empty"
                    when: contactSearch.count === 0
                    PropertyChanges {
                        target: contactSearch
                        height: 0
                    }
                }
            ]

            anchors {
                top: accountList.bottom
                topMargin: units.gu(1)
                left: parent.left
                right: parent.right
                bottom: bottomPanel.top
            }

            Behavior on height {
                UbuntuNumberAnimation { }
            }

            InvalidFilter {
                id: invalidFilter
            }

            // clear list if it is invisible to save some memory
            onVisibleChanged: {
                if (visible && (filter != null)) {
                    changeFilter(null)
                    update()
                } else if (!visible && filter != invalidFilter) {
                    changeFilter(invalidFilter)
                    update()
                }
            }

            ContactDetailPhoneNumberTypeModel {
                id: phoneTypeModel
            }

            listDelegate: Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                height: phoneRepeater.count * units.gu(6)
                Column {
                    anchors.fill: parent
                    spacing: units.gu(1)

                    Repeater {
                        id: phoneRepeater

                        model: contact.phoneNumbers.length

                        delegate: MouseArea {
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            height: units.gu(5)

                            onClicked: {
                                multiRecipient.addRecipient(contact.phoneNumbers[index].number)
                                multiRecipient.clearSearch()
                                multiRecipient.forceActiveFocus()
                            }

                            Column {
                                anchors.fill: parent

                                Label {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    height: units.gu(2)
                                    text: {
                                        // this is necessary to keep the string in the original format
                                        var originalText = contact.displayLabel.label
                                        var lowerSearchText =  multiRecipient.searchString.toLowerCase()
                                        var lowerText = originalText.toLowerCase()
                                        var searchIndex = lowerText.indexOf(lowerSearchText)
                                        if (searchIndex !== -1) {
                                            var piece = originalText.substr(searchIndex, lowerSearchText.length)
                                            return originalText.replace(piece, "<b>" + piece + "</b>")
                                        } else {
                                            return originalText
                                        }
                                    }
                                    fontSize: "medium"
                                    color: UbuntuColors.lightAubergine
                                }
                                Label {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    height: units.gu(2)
                                    text: {
                                        var phoneDetail = contact.phoneNumbers[index]
                                        return ("%1 %2").arg(phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label)
                                                        .arg(phoneDetail.number)
                                    }
                                }
                                Item {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    height: units.gu(1)
                                }

                                ListItem.ThinDivider {}
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: multiRecipient.searchString !== "" && multiRecipient.focus
        sourceComponent: contactSearchComponent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        z: 1
    }

    ContactWatcher {
        id: contactWatcher
        phoneNumber: participants.length > 0 ? participants[0] : ""
    }

    onParticipantsChanged: {
        updateFilters()
    }

    state: {
        if (participants.length === 0 && isReady) {
            return "newMessage"
        } else if (selectionMode) {
           return "selection"
        } else if (participants.length == 1) {
           if (contactWatcher.isUnknown) {
               return "unknownContact"
           } else {
               return "knownContact"
           }
        } else if (groupChat){
           return "groupChat"
        } else {
            return ""
        }
   }

    states: [
        PageHeadState {
            name: "selection"
            head: messages.head

            backAction: Action {
                objectName: "selectionModeCancelAction"
                iconName: "close"
                onTriggered: messageList.cancelSelection()
            }

            actions: [
                Action {
                    objectName: "selectionModeSelectAllAction"
                    iconName: "select"
                    onTriggered: messageList.selectAll()
                },
                Action {
                    objectName: "selectionModeDeleteAction"
                    enabled: messageList.selectedItems.count > 0
                    iconName: "delete"
                    onTriggered: messageList.endSelection()
                }
            ]
        },
        PageHeadState {
            name: "groupChat"
            head: messages.head

            actions: [
                Action {
                    objectName: "groupChatAction"
                    iconName: "contact-group"
                    onTriggered: PopupUtils.open(participantsPopover, messages.header)
                }
            ]
        },
        PageHeadState {
            name: "unknownContact"
            head: messages.head

            actions: [
                Action {
                    objectName: "contactCallAction"
                    visible: participants.length == 1
                    iconName: "call-start"
                    text: i18n.tr("Call")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.phoneNumber))
                    }
                },
                Action {
                    objectName: "addContactAction"
                    visible: contactWatcher.isUnknown && participants.length == 1
                    iconName: "new-contact"
                    text: i18n.tr("Add")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        Qt.openUrlExternally("addressbook:///addnewphone?callback=messaging-app.desktop&phone=" + encodeURIComponent(contactWatcher.phoneNumber));
                    }
                }
            ]
        },
        PageHeadState {
            name: "newMessage"
            head: messages.head
            actions: [
                Action {
                    objectName: "contactList"
                    iconName: "contact"
                    onTriggered: {
                        Qt.inputMethod.hide()
                        mainStack.push(Qt.resolvedUrl("NewRecipientPage.qml"), {"multiRecipient": multiRecipient, "parentPage": messages})
                    }
                }
            ]

            contents: MultiRecipientInput {
                id: multiRecipient
                objectName: "multiRecipient"
                enabled: visible
                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                    rightMargin: units.gu(2)
                }
            }
        },
        PageHeadState {
            name: "knownContact"
            head: messages.head

            actions: [
                Action {
                    objectName: "contactCallKnownAction"
                    visible: participants.length == 1
                    iconName: "call-start"
                    text: i18n.tr("Call")
                    onTriggered: {
                        Qt.inputMethod.hide()
                        Qt.openUrlExternally("tel:///" + encodeURIComponent(contactWatcher.phoneNumber))
                    }
                },
                Action {
                    objectName: "contactProfileAction"
                    visible: !contactWatcher.isUnknown && participants.length == 1
                    iconSource: "image://theme/contact"
                    text: i18n.tr("Contact")
                    onTriggered: {
                        Qt.openUrlExternally("addressbook:///contact?callback=messaging-app.desktop&id=" + encodeURIComponent(contactWatcher.contactId))
                    }
                }
            ]
        }
    ]

    HistoryEventModel {
        id: eventModel
        type: HistoryThreadModel.EventTypeText
        filter: null
        sort: HistorySort {
           sortField: "timestamp"
           sortOrder: HistorySort.DescendingOrder
        }
    }

    SortProxyModel {
        id: sortProxy
        sourceModel: eventModel.filter ? eventModel : null
        sortRole: HistoryEventModel.TimestampRole
        ascending: false
    }

    MultipleSelectionListView {
        id: messageList
        objectName: "messageList"
        clip: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomPanel.top
        }
        listModel: participants.length > 0 ? sortProxy : null
        verticalLayoutDirection: ListView.BottomToTop
        highlightFollowsCurrentItem: false
        /*add: Transition {
            UbuntuNumberAnimation {
                properties: "anchors.leftMargin"
                from: -width
                to: 0
            }
            UbuntuNumberAnimation {
                properties: "anchors.rightMargin"
                from: -width
                to: 0
            }
        }*/

        listDelegate: MessageDelegate {
            id: messageDelegate
            objectName: "message%1".arg(index)
            incoming: senderId != "self"
            // TODO: we have several items inside
            selected: messageList.isSelected(messageDelegate)
            unread: newEvent
            selectionMode: messages.selectionMode
            accountLabel: multipleAccounts ? messages.accounts[accountId] : ""
            // TODO: need select only the item
            onItemClicked: {
                console.debug("WILL SELECTED")
                if (messageList.isInSelectionMode) {
                    if (!messageList.selectItem(messageDelegate)) {
                        messageList.deselectItem(messageDelegate)
                    }
                }
            }
            onItemPressAndHold: {
                messageList.startSelection()
                messageList.selectItem(messageDelegate)
            }

            Component.onCompleted: {
                if (newEvent) {
                    messages.markMessageAsRead(accountId, threadId, eventId, type);
                }
            }
            onResend: {
                // resend this message and remove the old one
                if (textMessageAttachments.length > 0) {
                    var newAttachments = []
                    for (var i = 0; i < textMessageAttachments.length; i++) {
                        var attachment = []
                        var item = textMessageAttachments[i]
                        // we dont include smil files. they will be auto generated
                        if (item.contentType.toLowerCase() == "application/smil") {
                            continue
                        }
                        attachment.push(item.attachmentId)
                        attachment.push(item.contentType)
                        attachment.push(item.filePath)
                        newAttachments.push(attachment)
                    }
                    eventModel.removeEvent(accountId, threadId, eventId, type)
                    chatManager.sendMMS(participants, textMessage, newAttachments, messages.accountId)
                    return
                }
                eventModel.removeEvent(accountId, threadId, eventId, type)
                chatManager.sendMessage(messages.participants, textMessage, messages.accountId)
            }
        }
        onSelectionDone: {
            for (var i=0; i < items.count; i++) {
                var event = items.get(i).model
                eventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
            }
        }
        onCountChanged: {
            if (messages.pendingMessage) {
                messageList.contentY = 0
                messages.pendingMessage = false
            }
        }
    }

    Item {
        id: bottomPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: selectionMode ? 0 : textEntry.height + units.gu(2)
        visible: !selectionMode
        clip: true

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        ListItem.ThinDivider {
            anchors.top: parent.top
        }

        Icon {
            id: attachButton
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.verticalCenter: sendButton.verticalCenter
            height: units.gu(3)
            width: units.gu(3)
            color: "gray"
            name: "camera-app-symbolic"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    activeTransfer = defaultSource.request();
                }
            }
        }

        StyledItem {
            id: textEntry
            property alias text: messageTextArea.text
            property alias inputMethodComposing: messageTextArea.inputMethodComposing
            property int fullSize: attachmentThumbnails.height + messageTextArea.height
            style: Theme.createStyleComponent("TextFieldStyle.qml", textEntry)
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: parent.bottom
            anchors.left: attachButton.right
            anchors.leftMargin: units.gu(1)
            anchors.right: sendButton.left
            anchors.rightMargin: units.gu(1)
            height: attachments.count !== 0 ? fullSize + units.gu(1) : fullSize
            onActiveFocusChanged: {
                if(activeFocus) {
                    messageTextArea.forceActiveFocus()
                } else {
                    focus = false
                }
            }
            focus: false
            MouseArea {
                anchors.fill: parent
                onClicked: messageTextArea.forceActiveFocus()
            }
            Flow {
                id: attachmentThumbnails
                spacing: units.gu(1)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                anchors.topMargin: units.gu(1)
                height: childrenRect.height
                Component {
                    id: thumbnailImage
                    UbuntuShape {
                        property int index
                        property string filePath
                        width: childrenRect.width
                        height: childrenRect.height
                        image: Image {
                            id: avatarImage
                            width: units.gu(8)
                            height: units.gu(8)
                            fillMode: Image.PreserveAspectCrop
                            source: filePath
                            asynchronous: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mouse.accept = true
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Component {
                    id: thumbnailContact
                    UbuntuShape {
                        property int index
                        property string filePath
                        width: childrenRect.width
                        height: childrenRect.height
                        Icon {
                            anchors.centerIn: parent
                            width: units.gu(6)
                            height: units.gu(6)
                            name: "contact"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mouse.accept = true
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Component {
                    id: thumbnailUnknown
                    UbuntuShape {
                        property int index
                        property string filePath
                        width: childrenRect.width
                        height: childrenRect.height
                        Icon {
                            anchors.centerIn: parent
                            width: units.gu(6)
                            height: units.gu(6)
                            name: "attachment"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mouse.accept = true
                                activeAttachmentIndex = index
                                PopupUtils.open(attachmentPopover, parent)
                            }
                        }
                    }
                }

                Repeater {
                    model: attachments
                    delegate: Loader {
                        height: units.gu(8)
                        width: units.gu(8)
                        sourceComponent: {
                            var contentType = getContentType(filePath)
                            console.log(contentType)
                            switch(contentType) {
                            case ContentType.Contacts:
                                return thumbnailContact
                            case ContentType.Pictures:
                                return thumbnailImage
                            case ContentType.Unknown:
                                return thumbnailUnknown
                            default:
                                console.log("unknown content Type")
                            }
                        }
                        onStatusChanged: {
                            if (status == Loader.Ready) {
                                item.index = index
                                item.filePath = filePath
                            }
                        }
                    }
                }
            }

            TextArea {
                id: messageTextArea
                anchors.top: attachments.count == 0 ? textEntry.top : attachmentThumbnails.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.gu(4)
                style: MultiRecipientFieldStyle {}
                autoSize: true
                maximumLineCount: 0
                placeholderText: i18n.tr("Write a message...")
                focus: textEntry.focus
                font.family: "Ubuntu"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: "#5d5d5d"
                text: messages.text
            }

            /*InverseMouseArea {
                anchors.fill: parent
                visible: textEntry.activeFocus
                onClicked: {
                    textEntry.focus = false;
                }
            }*/
            Component.onCompleted: {
                // if page is active, it means this is not a bottom edge page
                if (messages.active && messages.keyboardFocus && participants.length != 0) {
                    messageTextArea.forceActiveFocus()
                }
            }
        }

        Button {
            id: sendButton
            anchors.bottomMargin: units.gu(1)
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            text: "Send"
            color: "green"
            width: units.gu(7)
            height: units.gu(4)
            font.pixelSize: FontUtils.sizeToPixels("small")
            enabled: {
               if (participants.length > 0 || multiRecipient.recipientCount > 0) {
                    if (textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0) {
                        return true
                    }
                }
                return false
            }
            onClicked: {
                if (!checkNetwork()) {
                    Qt.inputMethod.hide()
                    PopupUtils.open(noNetworkDialog)
                    return
                }
                // make sure we flush everything we have prepared in the OSK preedit
                Qt.inputMethod.commit();
                if (textEntry.text == "" && attachments.count == 0) {
                    return
                }
                if (messages.accountId == "") {
                    // FIXME: handle dual sim
                    messages.accountId = telepathyHelper.accountIds[0]
                }
                // dont change the participants list
                if (participants.length == 0) {
                    participants = multiRecipient.recipients
                }
                // create the new thread and update the threadId list
                eventModel.threadIdForParticipants(messages.accountId,
                                                   HistoryThreadModel.EventTypeText,
                                                   participants,
                                                   HistoryThreadModel.MatchPhoneNumber,
                                                   true)

                updateFilters()
                messages.pendingMessage = true
                if (attachments.count > 0) {
                    var newAttachments = []
                    for (var i = 0; i < attachments.count; i++) {
                        var attachment = []
                        var item = attachments.get(i)
                        attachment.push(item.name)
                        attachment.push(item.contentType)
                        attachment.push(item.filePath)
                        newAttachments.push(attachment)
                    }
                    chatManager.sendMMS(participants, textEntry.text, newAttachments, messages.accountId)
                    textEntry.text = ""
                    attachments.clear()
                    return
                }

                chatManager.sendMessage(participants, textEntry.text, messages.accountId)
                textEntry.text = ""
            }
        }
    }

    Scrollbar {
        flickableItem: messageList
        align: Qt.AlignTrailing
    }
}
