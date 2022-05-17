/*
 * Copyright 2020 Ubports Foundation.
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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import QtGraphicalEffects 1.0

ListItemWithActions{

    id: root
    property var messageData: null
    property var account: null //not used but needed to avoid error in logs

    readonly property var messageStatus: messageData.textMessageStatus

    readonly property string permanentErrorText: i18n.tr("Could not fetch the MMS message. Maybe the MMS settings are incorrect or cellular data is off? Ask to have the message sent again if everything is OK.")
    readonly property string temporaryErrorText: i18n.tr("Could not fetch the MMS message. Maybe the MMS settings are incorrect or cellular data is off?")
    readonly property string mmsReceivedText: i18n.tr("New MMS message (of %1 kB) to be downloaded before %2")

    readonly property bool permanentError: (messageData.textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed) || (messageData.textMessageStatus === HistoryThreadModel.MessageStatusUnknown)

    height: errorTxt.height + redownloadButton.height + textTimestamp.height + units.gu(2)
    anchors {
        topMargin: units.gu(0.5)
        bottomMargin: units.gu(0.5)
    }

    /*
      Structure of the textMessage for failed MMS message:

    Code [string] - contains one of following error code:
        x-ubports-nuntium-mms-error-unknown - unknown error, should not happen.
        x-ubports-nuntium-mms-error-activate-context - failed first contact with MMS service & context activation. Redownload is allowed if not expired.
        x-ubports-nuntium-mms-error-get-proxy - first contact was successful, but getting proxy failed. Very rare, should occur only with bad signal. Redownload is allowed if not expired.
        x-ubports-nuntium-mms-error-download-content - context & proxy ok, but download failed. Very rare, should occur only with bad signal or maybe if message expires (needs investigation what happens if trying to redownload expired message). Redownload is allowed if not expired.
        x-ubports-nuntium-mms-error-storage - the downloaded message file can't be saved to storage. Should happen only if disk full, or bad permissions (almost never). Redownload is NOT allowed (maybe should be?).
        x-ubports-nuntium-mms-error-forward - everything went ok, but for some unexplained reason, can't forward the message to telepathy-ofono. But if that's the case, I'll be a miracle if the error message can be sent o telepathy-ofono, so should never happen. Redownload is NOT allowed.
    Message [string] - raw error message caught in nuntium (just for debug purposes).
    Expire [string, optional] - date-time in RFC3339 format, when the message expires in MMS service. If field not present, the Expire field was not sent by provider (how do we handle this?). Edit: However, if expiry time not provided by operator, we assume 7 days expiry time, so this field will not be empty ever (unless some bug).
    Size [int, optional] - Size in bytes of message. If not present, size info was no sent by provider or size is 0.
    MobileData [bool, optional] - if mobile data was enabled in the time of error handling. If not present, the mobile data property could not be determined.
    */
    onMessageStatusChanged: {
        if (permanentError) {
            errorTxt.text = permanentErrorText
        } else {
            var error = JSON.parse(textMessage)
            if (error) {
                if (error.Code === 'x-ubports-nuntium-mms-error-activate-context' && error.MobileData === false) {
                    //display as standard message
                    errorTxt.text = mmsReceivedText.arg(Math.round(error.Size/1000)).arg(Qt.formatDateTime(error.Expire))
                } else {
                    //for now display as temporary error
                    errorTxt.text = temporaryErrorText
                }

                //deal with expired mms
                var expireDate = Date.parse(error.Expire)
                if (!isNaN(expireDate) && Date.now() > expireDate) {
                    redownloadButton.enabled = false
                }

            } else {
                //for now display as temporary error
                errorTxt.text = temporaryErrorText
            }
        }
    }

    Image {
        id: image
        source: "image://theme/mail-mark-important"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: units.gu(4)
        anchors {
            left: parent.left
            verticalCenter: rectangle.verticalCenter
        }
    }

    ColorOverlay {
        anchors.fill: image
        source: image
        color: "red"
    }

    Rectangle {
        id: rectangle
        anchors {
            left: image.right
            leftMargin: units.gu(1)
        }
        height: errorTxt.height + redownloadButton.height + units.gu(1)
        width: units.gu(0.5)
        color: "red"
    }

    Label {
        id: errorTxt
        fontSize: "medium"
        anchors {
            left: rectangle.right
            leftMargin: units.gu(1)
            right: parent.right
        }
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        color: Theme.palette.normal.backgroundText
    }


    Label {
        id: textTimestamp
        objectName: "messageDate"

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        height: units.gu(2)
        fontSize: "x-small"
        color: Theme.palette.normal.backgroundText
        elide: Text.ElideRight
        text: Qt.formatTime(messageData.timestamp, Qt.DefaultLocaleShortDate)
    }

    Button {
        id: redownloadButton
        text: i18n.tr("Download")
        visible: !permanentError
        enabled: messageData.textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed

        anchors {
            top: errorTxt.bottom
            topMargin: units.gu(1)
            left: errorTxt.left
        }

        onClicked: function() {
            chatManager.redownloadMessage(messageData.accountId, messageData.threadId, messageData.eventId)
        }

        ActivityIndicator {
            id: indicator
            anchors.centerIn: parent
            running: messageData.textMessageStatus === HistoryThreadModel.MessageStatusPending
        }
    }


    leftSideAction: Action {
        id: deleteAction
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: eventModel.removeEvents([messageData.properties]);
    }

    Component.onCompleted: {
        console.log('textMessage:', textMessage)
    }

}
