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

    function validateMessageAndSend(text, participantIds, attachments, properties, postSendActions) {
        var message = { "text" : text,
                        "participantIds" : participantIds,
                        "attachments" : attachments,
                        "properties" : properties }

        // now populate a list of validation functions
        var validators = [
            validator.checkVideoSize,
            validator.checkMMSEnabled,
            validator.checkMMSBroadcast,
            validator.checkValidAccount
        ]

        message["validators"] = validators

        if (postSendActions) {
            message["postSendActions"] = postSendActions
        }

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

                // check if the message has postSendActions
                var postSendActions = message["postSendActions"]
                if (postSendActions) {
                    for (var i in postSendActions) {
                        var postAction = postSendActions[i]
                        postAction(message)
                    }
                }
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

    function _isMMSBroadcast(message) {
        var account = messages.account
        // if we don't have the account or if it is not a phone one, it is
        // not an MMS broadcast
        if (!account || account.type != AccountEntry.PhoneAccount) {
            return false
        }

        // if chatType is Room, this is not a broadcast
        if (messages.chatType == ChatEntry.ChatTypeRoom) {
            return false
        }

        // if there is only one participant, it is also not a broadcast
        if (message["participantIds"].length == 1) {
            return false
        }

        // if there is no attachments, that's not going via MMS
        if (message["attachments"].length == 0) {
            return false
        }

        // if there is an active account overload, assume it is going to be used
        // and thus this won't be an MMS broadcast
        if (message["overloadedAccounts"].length > 0) {
            return false
        }

        // if none of the cases above match, this is an MMS broadcast
        return true
    }

    // **************** starting here we have all the validation functions ***************************************

    function checkVideoSize(message) {
        var attachments = message["attachments"]
        var videoSize = 0

        for (var i in attachments) {
            var item = attachments[i]
            if (startsWith(item[1].toLowerCase(),"video/")) {
                videoSize += FileOperations.size(item[2])
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

        // last but not least, show a dialog asking if the user wants to enable MMS
        var popup = PopupUtils.open(Qt.resolvedUrl("Dialogs/MMSEnableDialog.qml"), messages, {"message" : message})
        popup.accepted.connect(validator.nextStep)
        return false
    }

    function checkMMSBroadcast(message) {
        if (_isMMSBroadcast(message)) {
            var popup = PopupUtils.open(Qt.resolvedUrl("Dialogs/MMSBroadcastDialog.qml"), messages, {"message" : message})
            popup.accepted.connect(validator.nextStep)
            return false
        }

        // if this is not an MMS broadcast, we can proceed normally
        return true
    }

    function checkValidAccount(message) {
        // check if at least one account is selected
        if (!messages.account) {
            Qt.inputMethod.hide()
            // workaround for bug #1461861
            messages.focus = false
            var properties = {}

            if (telepathyHelper.flightMode) {
                properties["title"] = i18n.tr("You have to disable flight mode")
                properties["text"] = i18n.tr("It is not possible to send messages in flight mode")
            } else if (multiplePhoneAccounts) {
                properties["title"] = i18n.tr("No SIM card selected")
                properties["text"] = i18n.tr("You need to select a SIM card")
            } else if (telepathyHelper.phoneAccounts.all.length > 0 && telepathyHelper.phoneAccounts.active.length == 0) {
                properties["title"] = i18n.tr("No SIM card")
                properties["text"] = i18n.tr("Please insert a SIM card and try again.")
            } else {
                properties["text"] = i18n.tr("It is not possible to send the message")
                properties["title"] = i18n.tr("Failed to send the message")
            }
            PopupUtils.open(Qt.createComponent("Dialogs/InformationDialog.qml").createObject(messages), messages, properties)
            return false
        }
        return true
    }
}
