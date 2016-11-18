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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Item {
    id: validator

    signal messageSent()

    function validateMessageAndSend(text, participantIds, attachments, properties) {
        var message = { "text" : text,
                        "participantIds" : participantIds,
                        "attachments" : attachments,
                        "properties" : properties }

        // now populate a list of validation functions
        var validators = [
            validator.checkVideoSize,
            validator.checkMMSEnabled,
        ]

        message["validators"] = validators

        // just to simplify, store the active accounts that might be used as overload for this message
        var possibleAccounts = telepathyHelper.accountOverload(messages.account)
        var activeAccounts = []
        for (var i in possibleAccounts) {
            var account = possibleAccounts[i]
            if (account.active) {
                activeAccounts.push(account)
            }
        }
        message["overloadedAccounts"] = activeAccounts

        nextStep(message)
    }

    function nextStep(message) {
        var validators = message["validators"]

        // if we cleared all the validators, we can send the message
        if (validators.length == 0) {
            if (messages.sendMessage(message["text"],
                                     message["participantIds"],
                                     message["attachments"],
                                     message["properties"])) {
                validator.messageSent()
            }
            return
        }

        // get the next validator
        var validateFunction = validators[0]
        validators.shift()
        message["validators"] = validators

        if (validateFunction(message)) {
            nextStep(message)
        }
    }

    // **************** starting here we have all the validation functions ***************************************

    function checkVideoSize(message) {
        console.log("BLABLA checkVideoSize called")
        var attachments = message["attachments"]
        var videoSize = 0
        for (var i in attachments) {
            var item = attachments[i]
            if (startsWith(item.contentType.toLowerCase(),"video/")) {
                videoSize += FileOperations.size(item.filePath)
            }
        }

        if (videoSize > 307200 && !settings.messagesDontShowFileSizeWarning) {
            // FIXME we are guessing here if the handler will try to send it over an overloaded account
            // FIXME: this should be revisited when changing the MMS group implementation
            var isPhone = (messages.account && messages.account.type == AccountEntry.PhoneAccount)
            if (isPhone && message["overloadedAccounts"].length > 0) {
                isPhone = false
            }

            if (isPhone) {
                PopupUtils.open(Qt.createComponent("Dialogs/FileSizeWarningDialog.qml").createObject(messages))
            }
        }
        // we don't block here, just show a warning to the user
        return true
    }

    function checkMMSEnabled(message) {
        console.log("BLABLA checkMMS called")
        // if MMS is enabled, we don't have to check for anything here
        if (telepathyHelper.mmsEnabled ) {
            return true
        }

        // if the account is not a phone one, we can also send the message
        if (messages.account.type != AccountEntry.PhoneAccount) {
            return true
        }

        // we need to check if there will be an overload for sending the message
        if (message["overloadedAccounts"].length > 0) {
            return true
        }

        // now we are here with a phone account that doesn't support MMS
        // we check if MMS is required or not
        // for now it is only required in two cases: attachments and MMS groups
        // so if chatType is not Room and the attachment list is empty, we can send
        var attachments = message["attachments"]
        if (messages.chatType != ChatEntry.ChatTypeRoom && attachments.length == 0) {
            return true
        }

        // last but not least, show a warning to the user saying he needs to enable MMS to send the message
        var props = {}
        props["title"] = i18n.tr("MMS support required")
        props["text"] = i18n.tr("MMS support is required to send this message.\nPlease enable it in Settings->Enable MMS messages")
        PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, props)
        return false
    }

}
