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
    property var draftKey: null
    property var _oldDraftKey: null
    readonly property var coolDown: 2000

    onDraftKeyChanged: {
        coolDownTimer.stop()
        _saveKey(_oldDraftKey)
        _loadKey(draftKey)
    }

    Component.onCompleted: _loadKey(draftKey)
    Component.onDestruction: {
        coolDownTimer.stop()
        _saveKey(draftKey)
    }
    onTextChanged: _saveKey(draftKey)

    function _loadKey(draftKey) {
        if (draftKey === null || draftKey === "") return
        var draftTextAreaObj = _getStore()
        var newText = ""
        if (draftTextAreaObj[draftKey]) {
            newText = draftTextAreaObj[draftKey]
        }
        text = newText
        cursorPosition = text.length
        _oldDraftKey = draftKey
    }

    function _saveKey(draftKey) {
        if (draftKey === null || draftKey === "" || coolDownTimer.running) return
        var draftTextAreaObj = _getStore()
        if (draftTextAreaObj[draftKey] === displayText) return
        console.log("================== SAVED ==================");
        draftTextAreaObj[draftKey] = displayText
        store.draftTextArea = JSON.stringify(draftTextAreaObj)
        coolDownTimer.start()
    }

    function _getStore() {
        var draftTextAreaObj = {}
        try {
            draftTextAreaObj = JSON.parse(store.draftTextArea)
        }
        catch(e) {
            store.draftTextArea = "{}"
        }
        return draftTextAreaObj
    }

    Timer {
        id: coolDownTimer
        interval: coolDown
        onTriggered: _saveKey(draftKey)
    }

    Settings {
        id: store
        property string draftTextArea: "{}"
    }
}
