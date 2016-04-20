/*
 * Copyright 2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import messagingapp.private 0.1
import "dateUtils.js" as DateUtils

Item {
    id: recordingBar
    opacity: audioRecorder.recording ? 1.0 : 0.0
    Behavior on opacity { UbuntuNumberAnimation {} }
    visible: opacity > 0
    property bool handleError: false

    property int duration: 0
    readonly property bool recording: audioRecorder.recording
    property real buttonOpacity: 1

    signal audioRecorded(var audio)

    function startRecording() {
        handleError = true
        audioRecorder.record()
    }

    function stopRecording() {
        audioRecorder.stop()
    }

    Loader {
        id: audioRecorder
        readonly property bool ready: status == Loader.Ready
        readonly property bool recording: ready ? item.recorderStatus == AudioRecorder.RecordingStatus : false
        readonly property int duration: ready ? item.duration : 0
        function record() {
            audioRecorder.active = true
            item.record()
        }
        function stop() {
            item.stop()
            audioRecorder.active = false
        }
 
        active: false
        sourceComponent: audioRecorderComponent
    }

    Component {
        id: audioRecorderComponent
        AudioRecorder {
            readonly property bool recording: recorderStatus == AudioRecorder.RecordingStatus

            onRecorderStatusChanged: {
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
                    recordingBar.audioRecorded(attachment)

                    recordingBar.duration = duration
                }
            }
            onErrorChanged: {
                switch(errorCode) {
                    case AudioRecorder.ResourceError:
                        if (handleError) {
                            timer.start()
                        }
                        break
                    default:
                }
            }
            codec: "audio/vorbis"
            quality: AudioRecorder.VeryHighQuality
        }
    }

    // WORKAROUND we can't trigger the dialog from the onErrorChanged signal.
    Timer {
        id: timer
        interval: 1
        onTriggered: {
            Qt.inputMethod.hide()
            messages.focus = false
            PopupUtils.open(Qt.createComponent("Dialogs/NoMicrophonePermission.qml").createObject(messages))
            handleError = false
        }
    }

    TransparentButton {
        id: recordingIcon
        objectName: "recordingIcon"
        iconPulsate: recordingBar.recording
        sideBySide: true
        spacing: units.gu(1)
        opacity: buttonOpacity

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }

        focus: false

        iconColor: "red"
        iconName: "audio-input-microphone-symbolic"

        textSize: FontUtils.sizeToPixels("small")
        text: {
            if (audioRecorder.recording) {
                return DateUtils.formattedTime(audioRecorder.duration / 1000)
            }
            return DateUtils.formattedTime(0)
        }
    }

    Label {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: recordingIcon.right
            right: parent.right
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }
        opacity: buttonOpacity

        text: i18n.tr("<<< Swipe to cancel")
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}

