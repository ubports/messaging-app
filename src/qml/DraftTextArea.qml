/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3

TextArea {
    id: textAreaRoot

    // By setting the draftKey property to a string, this TextArea will save the
    // current text as a draft when the view changes.
    property bool loaded: false
    property string draftKey: "" //refers to threadId in Messages.qml
    property string _oldDraftKey: ""
    property string draftStore: "{}"

    function _loadKey() {
        if (draftKey.length == 0 || draftKey === _oldDraftKey) return

        var draftTextAreaObj = JSON.parse(draftStore)
        var newText = ""
        if (draftTextAreaObj[draftKey]) {
            newText = draftTextAreaObj[draftKey]
        }

        text = newText
        cursorPosition = text.length
        _oldDraftKey = draftKey

    }

    function _saveKey() {
        if (draftKey.length == 0) return

        var draftTextAreaObj = JSON.parse(draftStore)
        var updated = false
        if (displayText.length == 0) {
            if (draftKey in draftTextAreaObj){
                delete draftTextAreaObj[draftKey]
                updated = true
            }
        }else{
            if (draftTextAreaObj[draftKey] !== displayText) {
                draftTextAreaObj[draftKey] = displayText
                updated = true
            }
        }

        if (updated){
            draftStore = JSON.stringify(draftTextAreaObj)
        }

    }

    onDraftKeyChanged: {
        //prevent from being fired before onCompleted signal
        if (loaded)  _loadKey()
    }

    Settings {
        property alias draftTextArea: textAreaRoot.draftStore
    }


    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state !== Qt.ApplicationActive) {
                _saveKey()
            }
        }
    }


    Component.onCompleted: {
        loaded = true
        _loadKey()
    }


    Component.onDestruction: {
        _saveKey()
    }



}
