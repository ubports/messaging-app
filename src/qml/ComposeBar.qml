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

import QtQuick 2.0
import QtMultimedia 5.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 0.1
import Ubuntu.Telephony 0.1
import messagingapp.private 0.1
import "Stickers"

Item {
    id: composeBar

    property bool showContents: true
    property int maxHeight: textEntry.height + units.gu(2)
    property variant attachments: []
    property bool canSend: true
    property alias text: messageTextArea.text
    property bool audioAttached: attachments.count == 1 && attachments.get(0).contentType.toLowerCase().indexOf("audio/") > -1
    // Audio QML component needs to process the recorded audio do find duration and AudioRecorder seems to erase duration after some events
    property int audioRecordedDuration: 0
    property bool oskEnabled: true

    signal sendRequested(string text, var attachments)

    // internal properties
    property int _activeAttachmentIndex: -1
    property int _defaultHeight: textEntry.height + attachmentPanel.height + stickersPicker.height + units.gu(2)

    Component.onDestruction: {
        composeBar.reset()
    }

    function forceFocus() {
        messageTextArea.forceActiveFocus()
    }

    function reset() {
        if (composeBar.audioAttached) {
            FileOperations.remove(attachments.get(0).filePath)
        }

        textEntry.text = ""
        attachments.clear()
    }

    function addAttachments(transfer) {
        for (var i = 0; i < transfer.items.length; i++) {
            if (String(transfer.items[i].text).length > 0) {
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

    function formattedTime(time) {
        var d = new Date(0, 0, 0, 0, 0, time)
        return d.getHours() == 0 ? Qt.formatTime(d, "mm:ss") : Qt.formatTime(d, "h:mm:ss")
    }

    anchors.bottom: isSearching ? parent.bottom : keyboard.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: showContents ? Math.min(_defaultHeight, maxHeight) : 0
    visible: showContents
    clip: true

    Behavior on height {
        UbuntuNumberAnimation { }
    }

    MouseArea {
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

    AudioRecorder {
        id: audioRecorder

        readonly property bool recording: recorderState == AudioRecorder.RecordingState

        onRecorderStateChanged: {
            if (recorderState == AudioRecorder.StoppedState && actualLocation != "") {
                var filePath = actualLocation

                if (application.fileMimeType(filePath).toLowerCase().indexOf("audio/") <= -1) {
                    //If the recording process is too quick the generated file is not an audio one and should be ignored
                    return;
                }

                var attachment = {}
                attachment["contentType"] = application.fileMimeType(filePath)
                attachment["name"] = filePath.split('/').reverse()[0]
                attachment["filePath"] = filePath
                attachments.append(attachment)

                composeBar.audioRecordedDuration = duration
            }
        }

        codec: "audio/vorbis"
        quality: AudioRecorder.VeryHighQuality
    }

    Audio {
        id: audioPlayer

        readonly property bool playing: audioPlayer.playbackState == Audio.PlayingState

        source: composeBar.audioAttached ? attachments.get(0).filePath : ""
    }

    ListItem.ThinDivider {
        anchors.top: parent.top
    }

    Row {
        id: leftSideActions
        opacity: audioRecorder.recording || composeBar.audioAttached ? 0.0 : 1.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        width: childrenRect.width
        height: childrenRect.height

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: sendButton.verticalCenter
        }
        spacing: units.gu(2)

        TransparentButton {
            id: attachButton
            objectName: "attachButton"
            iconName: "add"
            iconRotation: attachmentPanel.expanded ? 45 : 0
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
            visible: stickersPicker.packCount > 0
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

    TransparentButton {
        id: recordingIcon
        objectName: "recordingIcon"

        anchors {
            top: parent.top
            left: parent.left
            topMargin: units.gu(1.5)
            leftMargin: units.gu(2)
        }

        opacity: audioRecorder.recording ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        focus: false

        iconColor: "red"
        iconName: "audio-input-microphone-symbolic"

        textSize: FontUtils.sizeToPixels("x-small")
        text: {
            if (audioRecorder.recording) {
                return composeBar.formattedTime(audioRecorder.duration / 1000)
            }
            return composeBar.formattedTime(0)
        }
    }

    TransparentButton {
        id: closeButton
        objectName: "closeButton"

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: sendButton.verticalCenter
        }

        opacity: composeBar.audioAttached ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        iconName: "close"

        onClicked: {
            composeBar.reset()
        }
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
            left: leftSideActions.right
            leftMargin: units.gu(2)
            right: sendButton.left
            rightMargin: units.gu(2)
        }
        height: attachments.count !== 0 && !composeBar.audioAttached ? fullSize + units.gu(1.5) : fullSize
        onActiveFocusChanged: {
            if(activeFocus) {
                messageTextArea.forceActiveFocus()
            } else {
                focus = false
            }
        }
        focus: false
        opacity: audioRecorder.recording || composeBar.audioAttached ? 0.0 : 1.0
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
                    id: loader
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
                            item.index = index
                            item.filePath = filePath
                        }
                    }

                    Connections {
                        target: loader.status == Loader.Ready ? loader.item : null
                        ignoreUnknownSignals: true
                        onPressAndHold: {
                            Qt.inputMethod.hide()
                            _activeAttachmentIndex = target.index
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

        TextArea {
            id: messageTextArea
            objectName: "messageTextArea"
            anchors {
                top: attachments.count == 0 ? textEntry.top : attachmentThumbnails.bottom
                left: parent.left
                right: parent.right
            }
            // this value is to avoid letter being cut off
            height: units.gu(4.3)
            style: LocalTextAreaStyle {}
            autoSize: true
            maximumLineCount: attachments.count == 0 ? 8 : 4
            placeholderText: {
                if (telepathyHelper.ready) {
                    var account = telepathyHelper.accountForId(presenceRequest.accountId)
                    if (account && 
                            (presenceRequest.type != PresenceRequest.PresenceTypeUnknown &&
                             presenceRequest.type != PresenceRequest.PresenceTypeUnset) &&
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
            color: "#5d5d5d"
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

    StickersPicker {
        id: stickersPicker
        anchors {
            left: parent.left
            right: parent.right
            top: textEntry.bottom
        }

        onExpandedChanged: {
            if (expanded && Qt.inputMethod.visible) {
                stickersPicker.forceActiveFocus()
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

    Item {
        id: audioPreview
        anchors {
            top: parent.top
            bottom: attachmentPanel.top
            left: closeButton.right
            right: sendButton.left
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            leftMargin: units.gu(3)
            rightMargin: units.gu(1)
        }

        opacity: composeBar.audioAttached ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        TransparentButton {
            id: playButton

            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(0.5)
            }

            iconColor: "grey"
            iconName: audioPlayer.playing ? "media-playback-stop" : "media-playback-start"

            textSize: FontUtils.sizeToPixels("x-small")
            text: {
                if (audioPlayer.playing) {
                    return composeBar.formattedTime(audioPlayer.position/ 1000)
                }
                return composeBar.formattedTime(composeBar.audioRecordedDuration / 1000)
            }

            onClicked: {
                if (audioPlayer.playing) {
                    audioPlayer.stop()
                } else {
                    audioPlayer.play()
                }
            }
        }

        Image {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: playButton.right
                right: parent.right
                leftMargin: units.gu(1)
            }

            source: Qt.resolvedUrl("./assets/sine.svg")
        }
    }

    Image {
        anchors {
            top: parent.top
            bottom: attachmentPanel.top
            left: recordingIcon.right
            right: sendButton.left
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }

        opacity: audioRecorder.recording ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        source: Qt.resolvedUrl("./assets/sine.svg")
    }

    TransparentButton {
        id: sendButton
        objectName: "sendButton"
        anchors.verticalCenter: textEntry.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        iconSource: Qt.resolvedUrl("./assets/send.svg")
        enabled: (canSend && (textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0))
        opacity: textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0 ? 1.0 : 0.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        onClicked: {
            // make sure we flush everything we have prepared in the OSK preedit
            Qt.inputMethod.commit();
            if (textEntry.text == "" && attachments.count == 0) {
                return
            }

            if (composeBar.audioAttached) {
                textEntry.text = ""
            }

            composeBar.sendRequested(textEntry.text, attachments)
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

        opacity: textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0 ? 0.0 : 1.0
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0

        iconColor: audioRecorder.recording ? "black" : "gray"
        iconName: "audio-input-microphone-symbolic"

        onPressed: audioRecorder.record()
        onReleased: audioRecorder.stop()
    }
}
