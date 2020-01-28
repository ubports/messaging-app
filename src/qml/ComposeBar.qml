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

import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import Ubuntu.Telephony 0.1
import Ubuntu.History 0.1
import messagingapp.private 0.1
import "Stickers"

Item {
    id: composeBar

    property bool showContents: true
    property int maxHeight: textEntry.height + units.gu(2)
    property bool canSend: true
    property alias text: messageTextArea.text
    property bool audioAttached: manuallyRecorded && attachments.count == 1 && attachments.get(0).contentType.toLowerCase().indexOf("audio/") > -1
    property bool manuallyRecorded: false
    // Audio QML component needs to process the recorded audio to find duration and AudioRecorder seems to erase duration after some events
    property alias audioRecordedDuration: audioRecordingBar.duration
    property alias recording: audioRecordingBar.recording
    property bool oskEnabled: true
    property alias inputMethodComposing: messageTextArea.inputMethodComposing
    property bool usingMMS: false
    property bool isBroadcast: false
    property bool returnToSend: false
    property bool enableAttachments: true
    property alias participants: participantPopover.participants
    property string threadId: ""
    property QtObject presenceRequest : null
    readonly property alias textArea: messageTextArea
    readonly property int maxSMSLength: 160
    readonly property int maxSMSLengthMultiple: 153

    onRecordingChanged: {
        if (recording) {
            manuallyRecorded = true
        }
    }

    signal sendRequested(string text, var attachments)

    // internal properties
    property int _activeAttachmentIndex: -1
    property int _defaultHeight: charCount.height + textEntry.height + attachmentPanel.height + stickersPicker.height + units.gu(2)
    property int messageCount: 0
    property int smsLength: 160

    function forceFocus() {
        if (showContents)
            messageTextArea.forceActiveFocus()
    }

    function reset() {
        // avoid removing files coming from forward
        if (composeBar.audioAttached) {
            FileOperations.remove(attachments.get(0).filePath)
        }

        textEntry.text = ""
        attachments.clear()
    }

    function addAttachments(transfer) {
        if (!transfer || !transfer.items) {
            return
        }

        for (var i = 0; i < transfer.items.length; i++) {
            if (String(transfer.items[i].text).length > 0 && String(transfer.items[i].url).length == 0) {
                composeBar.text = String(transfer.items[i].text)
                continue
            }
            var attachment = {}
            if (!startsWith(String(transfer.items[i].url),"file://")) {
                composeBar.text = String(transfer.items[i].url)
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

    anchors.bottom: isSearching ? parent.bottom : keyboard.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: showContents ? Math.min(_defaultHeight, maxHeight) : 0
    visible: showContents
    clip: true

    MouseArea {
        enabled: !composeBar.audioAttached
        anchors.fill: parent
        onClicked: {
            forceFocus()
        }
    }

    ListModel {
        id: attachments
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
                        attachments.remove(_activeAttachmentIndex)
                        PopupUtils.close(popover)
                    }
                }
            }
            Component.onDestruction: _activeAttachmentIndex = -1
        }
    }

    Component {
        id: microphoneWarningPopover

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
                    text: i18n.tr("You have to press and hold the record icon")
                    onClicked: {
                        PopupUtils.close(popover)
                    }
                }
                Connections {
                    target: composeBar
                    onTextChanged: PopupUtils.close(popover)
                }
            }
        }
    }

    ListItem.ThinDivider {
        anchors.top: parent.top
    }

    Row {
        id: leftSideActions
        opacity: {
            if (composeBar.recording) {
                // we need to fade the buttons in when dragging
                return dragTarget.dragAmount
            } else if (composeBar.audioAttached) {
                return 0;
            } else {
                return 1
            }
        }

        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0 && composeBar.enableAttachments

        width: opacity > 0 ? childrenRect.width : 0
        height: opacity > 0 ? childrenRect.height : 0

        anchors {
            left: parent.left
            leftMargin: visible ? units.gu(2) : 0
            verticalCenter: sendButton.verticalCenter
        }
        spacing: units.gu(2)

        TransparentButton {
            id: attachButton
            objectName: "attachButton"
            iconName: attachmentPanel.expanded ? "close" : "attachment"
            onClicked: {
                attachmentPanel.expanded = !attachmentPanel.expanded
                if (attachmentPanel.expanded) {
                    stickersPicker.expanded = false
                }
            }
        }

        TransparentButton {
            id: stickersButton
            objectName: "stickersButton"
            iconSource: (stickersPicker.expanded && oskEnabled) ? Qt.resolvedUrl("./assets/input-keyboard-symbolic.svg") :
                                                                  Qt.resolvedUrl("./assets/face-smile-big-symbolic-2.svg")
            visible: stickerPacksModel.count > 0
            onClicked: {
                if (!stickersPicker.expanded) {
                    messageTextArea.focus = false
                    stickersPicker.expanded = true
                    attachmentPanel.expanded = false
                } else {
                    stickersPicker.expanded = false
                    messageTextArea.forceActiveFocus()
                }
            }
        }
    }

    AudioPlaybackBar {
        id: audioPlaybackBar

        anchors {
            left: parent.left
            right: audioRecordingBar.right
            top: parent.top
            bottom: attachmentPanel.top
        }

        source: composeBar.audioAttached ? attachments.get(0).filePath : ""
        duration: audioRecordedDuration

        opacity: composeBar.audioAttached ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        onResetRequested: {
            composeBar.reset()
        }
    }

    AudioRecordingBar {
        id: audioRecordingBar

        anchors {
            left: parent.left
            right: anchorPoint.left
            top: parent.top
            bottom: attachmentPanel.top
        }

        buttonOpacity: recording ? 1 - dragTarget.dragAmount : 0

        onAudioRecorded:  {
            attachments.append(audio)
        }
    }

    Item {
        id: dragTarget

        property real recordingX: recordButton.x
        property real normalX: leftSideActions.x + leftSideActions.width
        property real delta: recordingX - normalX
        property real dragAmount: 1 - (x - normalX) / (delta > 0 ? delta : 0.0001)
        x: recordingX
        width: 0

        function reset() {
            x = Qt.binding(function(){return recordingX})
        }
    }

    Item {
        id: anchorPoint
        x: (composeBar.recording || composeBar.audioAttached) ? dragTarget.x : dragTarget.normalX
        Behavior on x { UbuntuNumberAnimation { } }
    }

    StyledItem {
        id: textEntry
        property alias text: messageTextArea.text
        property alias inputMethodComposing: messageTextArea.inputMethodComposing
        property int fullSize: composeBar.audioAttached ? messageTextArea.height : attachmentThumbnails.height + messageTextArea.height
        style: Theme.createStyleComponent("TextAreaStyle.qml", textEntry)
        anchors {
            topMargin: units.gu(1)
            top: parent.top
            left: anchorPoint.right
            leftMargin: units.gu(2)
            right: sendButton.left
            rightMargin: units.gu(2)
        }
        height: attachments.count !== 0 && !composeBar.audioAttached ? fullSize + units.gu(1.5) : fullSize
        onActiveFocusChanged: {
            if(activeFocus) {
                stickersPicker.expanded = false
                messageTextArea.forceActiveFocus()
            } else {
                focus = false
            }
        }

        onTextChanged: {
            // in case there is audio attached and the user starts typing, we remove the attachment
            // and continue the text message
            if (text !== "" && composeBar.audioAttached) {
                attachments.clear()
            }
            messageCount = (messageTextArea.length + smsLength - 1) / smsLength
        }

        focus: false
        opacity: composeBar.audioAttached ? 0.0 : 1.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        MouseArea {
            anchors.fill: parent
            onClicked: forceFocus()
        }
        Flow {
            id: attachmentThumbnails
            spacing: units.gu(1)
            anchors{
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: units.gu(1)
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            height: childrenRect.height

            Repeater {
                model: attachments
                delegate: Loader {
                    height: units.gu(8)
                    source: {
                        var contentType = getContentType(filePath)
                        console.log(contentType)
                        switch(contentType) {
                        case ContentType.Contacts:
                            return Qt.resolvedUrl("ThumbnailContact.qml")
                        case ContentType.Pictures:
                            return Qt.resolvedUrl("ThumbnailImage.qml")
                        case ContentType.Videos:
                            return Qt.resolvedUrl("ThumbnailVideo.qml")
                        case ContentType.Unknown:
                            return Qt.resolvedUrl("ThumbnailUnknown.qml")
                        default:
                            console.log("unknown content Type")
                        }
                    }
                    onStatusChanged: {
                        if (status == Loader.Ready) {
                            item.filePath = filePath
                        }
                    }

                    Connections {
                        target: status == Loader.Ready ? item : null
                        ignoreUnknownSignals: true
                        onPressAndHold: {
                            Qt.inputMethod.hide()
                            _activeAttachmentIndex = index
                            PopupUtils.open(attachmentPopover, parent)
                        }
                    }
                }
            }
        }

        ListItem.ThinDivider {
            id: divider

            anchors {
                left: parent.left
                right: parent.right
                top: attachmentThumbnails.bottom
                margins: units.gu(0.5)
            }
            visible: attachments.count > 0
        }

        Item {
            anchors {
                top: attachments.count == 0 ? textEntry.top : attachmentThumbnails.bottom
                left: parent.left
                right: parent.right
            }
            DraftTextArea {
                id: messageTextArea
                objectName: "messageTextArea"

                draftKey: composeBar.threadId


                property bool autoCompleteLock: false

                property int autoCompleteStartIndex: -1

                function updateAutoComplete(startIndex, input)
                {
                    var showPopup = false
                    if (input.charAt(startIndex) === "@") {
                        showPopup = true
                        startIndex += 1
                    }

                    var autoCompletePrefix = input.slice(startIndex, input.length)

                    return participantPopover.showParticpantsStartWith(composeBar, autoCompletePrefix, showPopup)
                }

                function autoComplete()
                {
                    autoCompleteLock = true
                    var suggestion = ""
                    var lastSpace = -1

                    var autoCompleteText = text
                    if (participantPopover.active) {
                        if (participantPopover.popupVisible) {
                            suggestion = updateAutoComplete(autoCompleteStartIndex, autoCompleteText)
                        } else {
                            suggestion = participantPopover.nextItem()
                        }
                    } else if (autoCompleteText.length > 0) {
                        autoCompleteStartIndex = autoCompleteText.lastIndexOf(" ")  + 1
                        suggestion = updateAutoComplete(autoCompleteStartIndex, autoCompleteText)
                        forceFocus()
                    } else {
                        autoCompleteLock = false
                        return false
                    }

                    if (suggestion.length > 0) {
                        var sliceEnd = autoCompleteText.charAt(autoCompleteStartIndex) === "@" ? autoCompleteStartIndex + 1 : autoCompleteStartIndex
                        messageTextArea.text = text.slice(0, sliceEnd) + suggestion + ", "
                        if (participantPopover.popupVisible) {
                            messageTextArea.select(autoCompleteText.length, text.length)
                        } else {
                            messageTextArea.cursorPosition = messageTextArea.text.length
                        }

                    } else {
                        participantPopover.close()
                        autoCompleteStartIndex = -1
                    }

                    autoCompleteLock = false
                    return true
                }

                onTextChanged: {
                    if (autoCompleteLock)
                        return

                    // non-visual popover does not care about text change
                    if (!participantPopover.popupVisible) {
                        participantPopover.close()
                        autoCompleteStartIndex = -1
                        return
                    }

                    if (autoCompleteStartIndex != -1)
                        autoComplete()
                }

                function returnPressed() {
                    if (composeBar.returnToSend) {
                        sendButton.processSend()
                        return true
                    }
                    return false
                }
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                Keys.onReturnPressed: event.accepted = returnPressed()
                Keys.onEnterPressed: event.accepted = returnPressed()
                // this value is to avoid letter being cut off
                height: units.gu(4.3)
                style: LocalTextAreaStyle {}
                autoSize: true
                maximumLineCount: attachments.count == 0 ? 8 : 4
                placeholderText: {
                    if (isBroadcast) {
                        return i18n.tr("Write a broadcast message...")
                    } else if (telepathyHelper.ready) {
                        var account = telepathyHelper.accountForId(presenceRequest.accountId)
                        if (account &&
                                (presenceRequest.type !== PresenceRequest.PresenceTypeUnknown &&
                                 presenceRequest.type !== PresenceRequest.PresenceTypeUnset) &&
                                account.protocolInfo.serviceName !== "") {
                            console.log(presenceRequest.accountId)
                            console.log(presenceRequest.type)
                            return account.protocolInfo.serviceName
                        }
                    }
                    return i18n.tr("Write a message...")
                }
                focus: textEntry.focus
                font.family: "Ubuntu"
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: Theme.palette.normal.backgroundText
                Keys.onPressed: {
                    if (event.key === Qt.Key_Tab) {
                        event.accepted = autoComplete()
                    } else if (participantPopover.popupVisible) {
                        // cancel non-visual autocomplete if any other key is pressed
                        participantPopover.close()
                        autoCompleteStartIndex = -1
                    }
                }

                Keys.onReleased: {
                    if (event.key === Qt.Key_At) {
                        event.accepted = autoComplete()
                    }
                }
            }

            // show the counts if option is enabled, and more than one line
            // If MMS indicate such on the label and don't show the count
            // if word prediction is on italicize the count while its still composing
            Label {
                id: charCount
                anchors {
                    right: messageTextArea.right
                    top: messageTextArea.bottom
                    topMargin: visible ? units.gu(.5) : 0
                    bottomMargin: visible ? units.gu(.5) : 0
                }
                height: visible ? units.gu(2) : 0
                readonly property int smsLength: length<=maxSMSLength ? maxSMSLength : maxSMSLengthMultiple
                readonly property int digitsLeft: smsCount*smsLength - length
                property int length: {
                    var str = messageTextArea.displayText
                    var m = encodeURIComponent(str).match(/%[89ABab]/g)
                    return str.length + (m ? m.length : 0)
                }
                property int smsCount: Math.ceil(length/smsLength)
                text: {
                    if ((attachments.count > 0) || usingMMS) {
                        return i18n.tr("MMS")
                    } else {
                        return "%1 / %2".arg(digitsLeft).arg(smsCount)
                    }
                }
                textSize: Label.XSmall
                font.italic: messageTextArea.inputMethodComposing && (attachments.count == 0) && !usingMMS
                color: Theme.palette.normal.backgroundTertiaryText
                visible: messageTextArea.displayText.length > 0 && (smsCount > 1 || digitsLeft <= 10)
            }
        }
    }

    AttachmentPanel {
        id: attachmentPanel

        anchors {
            left: parent.left
            right: parent.right
            top: textEntry.bottom
            topMargin: units.gu(1)
        }

        Connections {
            target: composeBar
            onAudioAttachedChanged: {
                if (composeBar.audioAttached) {
                    attachmentPanel.expanded = false;
                }
            }
        }

        onAttachmentAvailable: {
            attachments.append(attachment)
            forceFocus()
        }

        onExpandedChanged: {
            if (expanded && Qt.inputMethod.visible) {
                attachmentPanel.forceActiveFocus()
            }
        }
    }

    Loader {
        id: stickersPicker
        property bool expanded: false
        height: expanded ? item.height : 0
        active: false
        sourceComponent: stickersPickerComponent
        anchors {
            left: parent.left
            right: parent.right
            top: textEntry.bottom
        }
        onExpandedChanged: {
            if (expanded) {
               stickersPicker.active = expanded
            }
            if (active) {
                item.expanded = expanded
            }
        }
    }

    Component {
        id: stickersPickerComponent
        StickersPicker {
            id: stickersPicker1

            onExpandedChanged: {
                if (expanded && Qt.inputMethod.visible) {
                    stickersPicker1.forceActiveFocus()
                }
            }

            onStickerSelected: {
                if (!canSend) {
                    // FIXME: show a dialog saying what we need to do to be able to send
                    return
                }

                var attachment = {}
                var filePath = String(path).replace('file://', '')
                attachment["contentType"] = application.fileMimeType(filePath)
                attachment["name"] = filePath.split('/').reverse()[0]
                attachment["filePath"] = filePath

                // we need to append the attachment to a ListModel, so create it dynamically
                var attachments = Qt.createQmlObject("import QtQuick 2.0; ListModel { }", composeBar)
                attachments.append(attachment)
                composeBar.sendRequested("", attachments)
                stickersPicker.expanded = false
            }
        }
    }


    SequentialAnimation {
        id: enableRecordButton
        running: false
        alwaysRunToEnd: false
        UbuntuNumberAnimation { target: sendButton; property: "opacity"; to: 0 }
        UbuntuNumberAnimation { target: recordButton; property: "opacity"; to: 1 }
    }

    SequentialAnimation {
        id: enableSendButton
        running: false
        alwaysRunToEnd: false
        UbuntuNumberAnimation { target: recordButton; property: "opacity"; to: 0 }
        UbuntuNumberAnimation { target: sendButton; property: "opacity"; to: 1 }
    }

    TransparentButton {
        id: sendButton
        objectName: "sendButton"
        anchors.verticalCenter: textEntry.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        iconName: "send"
        enabled: !recordButton.enabled
        function processSend() {
            // make sure we flush everything we have prepared in the OSK preedit
            Qt.inputMethod.commit();
            if ((textEntry.text == "" && attachments.count == 0) || !canSend) {
                return
            }

            if (composeBar.audioAttached) {
                textEntry.text = ""
            }

            composeBar.sendRequested(textEntry.text, attachments)
        }
        onEnabledChanged: {
            if (enabled) {
                enableSendButton.start()
            }
        }
        opacity: composeBar.enableAttachments ? 0 : 1
        visible: enabled

        onClicked: {
            processSend()
        }
    }

    TransparentButton {
        id: recordButton
        objectName: "recordButton"

        anchors {
            verticalCenter: textEntry.verticalCenter
            right: parent.right
            rightMargin: units.gu(2)
        }

        enabled: textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0 || !composeBar.enableAttachments ? false : true
        onEnabledChanged: {
            if (enabled) {
                enableRecordButton.start()
            }
        }

        visible: enabled

        iconName: "audio-input-microphone-symbolic"

        onClicked: {
            if (!composeBar.audioAttached) {
                var oskFocus = null
                if (textEntry.activeFocus) {
                    oskFocus = composeBar.forceFocus
                } else if (multiRecipient.activeFocus) {
                    oskFocus = multiRecipient.forceActiveFocus
                }
                PopupUtils.open(microphoneWarningPopover, recordButton)
                // avoid dismissing the osk
                if (oskFocus) {
                    oskFocus()
                }
            }
        }
        onPressed: audioRecordingBar.startRecording()
        onReleased: {
            audioRecordingBar.stopRecording()

            // if dragged past the threshold, cancel
            if (dragTarget.dragAmount >= 0.5) {
                composeBar.reset()
            }
            dragTarget.reset()
        }

        // drag-to-cancel
        drag.target: dragTarget
        drag.axis: Drag.XAxis
        drag.minimumX: (leftSideActions.x + leftSideActions.width)
        drag.maximumX: recordButton.x
    }

    ParticipantsPopover {
        id: participantPopover

        height: parent.parent.height
        width: parent.width
    }
}
