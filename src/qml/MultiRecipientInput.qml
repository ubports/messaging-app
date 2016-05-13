/*
 * Copyright 2012-2013 Canonical Ltd.
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
import Ubuntu.Contacts 0.1
import Ubuntu.Telephony 0.1
import QtContacts 5.0

StyledItem {
    id: multiRecipientWidget
    property int recipientCount: recipientModel.count-1
    property int selectedIndex: -1
    property variant recipients: []
    property string searchString: ""
    signal clearSearch()
    styleName: "TextFieldStyle"
    clip: true
    height: contactFlow.height
    focus: activeFocus
    property bool multimediaGroup: false
    function getMultimediaGroup () {
        if (recipients.length < 2) {
            return false
        }
        for (var i=0; i < recipients.length; i++) {
            var account = telepathyHelper.accountForId(presences.itemAt(i).accountId)
            console.log(account.type, presences.itemAt(i).accountId)
            if (!account || account.type != AccountEntry.MultimediaAccount) {
               return false
            }
            if (presences.itemAt(i).type == PresenceRequest.PresenceTypeUnknown || presences.itemAt(i).type == PresenceRequest.PresenceTypeUnset) {
                return false
            }
        }
        return true
    }

    Repeater {
        id: presences
        model: recipients
        Item {
            property alias accountId: presence.accountId
            property alias identifier: presence.identifier
            property alias type: presence.type
            PresenceRequest {
                id: presence
                accountId: finalAccountId(messages.accountsModel[headerSections.selectedIndex])
                identifier: modelData
                onTypeChanged: multiRecipientWidget.multimediaGroup = Qt.binding(getMultimediaGroup)
            }
        }
    }

    signal forceFocus()

    function finalAccountId(account) {
        if (!telepathyHelper.ready) {
            return ""
        }
        if (!account) {
            return ""
        }
        if (account.type == AccountEntry.PhoneAccount) {
            for (var i in telepathyHelper.accounts) {
                var tmpAccount = telepathyHelper.accounts[i]
                if (tmpAccount.type == AccountEntry.MultimediaAccount) {
                    return tmpAccount.accountId
                }
            }
            return ""
        }
        return account.accountId
    }

    MouseArea {
        anchors.fill: parent
        enabled: parent.focus === false
        onClicked: forceFocus()
        z: 1
    }

    function addRecipient(identifier) {
        for (var i = 0; i<recipientModel.count; i++) {
            // FIXME: replace by a phone number comparison method
            if (recipientModel.get(i).identifier === identifier) {
                // FIXME: we should warn the user about this duplicate
                return
            }
        }

        recipientModel.insert(recipientCount, { "identifier": identifier })
        scrollableArea.contentX = contactFlow.width
    }

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    ListModel {
        id: recipientModel
        objectName: "recipientModel"
        onCountChanged: {
            var i
            var tmp = []
            for(i = 0; i< recipientModel.count-1; i++) {
                tmp.push(recipientModel.get(i).identifier)
            }
            recipients = tmp
        }
        ListElement {
            identifier: ""
            searchItem: true
        }
    }

    Flickable {
        id: scrollableArea
        anchors.fill: parent
        contentWidth: contactFlow.width
        // force content to scroll as the user types the number
        onContentWidthChanged: {
            if (scrollableArea.contentWidth > multiRecipientWidget.width) {
                scrollableArea.contentX = scrollableArea.contentWidth - multiRecipientWidget.width
            }
        }
        flickableDirection: Flickable.HorizontalFlick
        Flow {
            id: contactFlow
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            anchors.top: parent.top
            move: Transition {
                UbuntuNumberAnimation { properties: "x,y";}
            }

            Component {
                id: contactDelegate
                Label {
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: units.gu(1)
                        anchors.bottomMargin: units.gu(1)
                        color: Theme.palette.selected.background
                        visible: selected
                        z: -1
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectedIndex == index ? selectedIndex = -1 : selectedIndex = index
                    }
                    property string contactName: {
                        if (contactWatcher.isUnknown) {
                            return contactWatcher.identifier
                        }
                        return contactWatcher.alias
                    }
                    property alias identifier: contactWatcher.identifier
                    property int index
                    property bool selected: selectedIndex == index
                    property string separator: index == recipientCount-1 ? "" : ","
                    height: units.gu(4)
                    visible: height != 0
                    text: contactName + separator
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    font.family: "Ubuntu"
                    font.weight: Font.Light
                    color: selected ? Theme.palette.selected.backgroundText :
                                      Theme.palette.normal.backgroundText
                    verticalAlignment: Text.AlignVCenter
                    ContactWatcher {
                        id: contactWatcher
                        addressableFields: messages.account.addressableVCardFields
                    }
                }
            }
            Component {
                id: searchDelegate
                TextField {
                    id: contactSearchInput
                    // the following items are used to calculate the text size of the hint and text entry
                    Label {
                        id: hintLabel 
                        visible: false
                        text: i18n.tr("To:")
                    }
                    Label {
                        id: textLabel
                        visible: false
                        text: contactSearchInput.text
                    }

                    objectName: "contactSearchInput"
                    focus: true
                    style: MultiRecipientFieldStyle {}
                    height: units.gu(4)
                    width: text != "" ? textLabel.paintedWidth + units.gu(3) : hintLabel.paintedWidth + units.gu(3)
                    hasClearButton: false
                    clip: false
                    placeholderText: multiRecipientWidget.recipientCount <= 0 ? hintLabel.text : ""
                    font.family: "Ubuntu"
                    font.weight: Font.Light
                    color: Theme.palette.normal.backgroundText
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== "") {
                            addRecipient(text)
                            text = ""
                        }
                    }
                    onTextChanged: {
                        if (text.substring(text.length -1, text.length) == ",") {
                            addRecipient(text.substring(0, text.length - 1))
                            text = ""
                            return
                        }
                        searchString = text
                    }
                    Keys.onReturnPressed: {
                        if (text == "")
                            return
                        addRecipient(text)
                        text = ""
                    }
                    Connections {
                        target: multiRecipientWidget
                        onClearSearch: text = ""
                    }
                    Connections {
                        target: multiRecipientWidget
                        onForceFocus: {
                            contactSearchInput.forceActiveFocus()
                        }
                    }
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Backspace && text == "" && recipientCount > 0) {
                            if (selectedIndex != -1) {
                                recipientModel.remove(selectedIndex)
                                selectedIndex = -1
                            } else {
                                recipientModel.remove(recipientCount-1)
                            }
                        } if (event.key === Qt.Key_Comma) {
                            if (text == "")
                                return
                            addRecipient(text)
                            text = ""
                            event.accepted = true
                        } else {
                            if (selectedIndex != -1) {
                                recipientModel.remove(selectedIndex)
                                selectedIndex = -1
                                if (event.key === Qt.Key_Backspace)
                                    event.accepted = true
                            }
                        }
                    }
                }
            }
            spacing: units.gu(0.5)
            Repeater {
                id: rpt
                model: recipientModel
                delegate: Loader {
                    sourceComponent: {
                        if (searchItem)
                            searchDelegate
                       else
                            contactDelegate
                    }
                    Binding {
                        target: item
                        property: "identifier"
                        value: identifier
                        when: (identifier && status == Loader.Ready)
                    }
                    Binding {
                        target: item
                        property: "index"
                        value: index
                        when: (index && status == Loader.Ready)
                    }
                }
            }
        }
    }
}
