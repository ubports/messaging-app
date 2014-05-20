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

import QtQuick 2.0
import Ubuntu.Components 0.1
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
    style: Theme.createStyleComponent("TextFieldStyle.qml", multiRecipientWidget)
    clip: true
    height: contactFlow.height
    focus: activeFocus

    signal forceFocus()

    MouseArea {
        anchors.fill: parent
        enabled: parent.focus === false
        onClicked: forceFocus()
        z: 1
    }

    function addRecipient(phoneNumber) {
        for (var i = 0; i<recipientModel.count; i++) {
            // FIXME: replace by a phone number comparison method
            if (recipientModel.get(i).phoneNumber === phoneNumber) {
                // FIXME: we should warn the user about this duplicate
                return
            }
        }

        recipientModel.insert(recipientCount, { "phoneNumber": phoneNumber })
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
            for(i = 1; i< recipientModel.count-1; i++) {
                tmp.push(recipientModel.get(i).phoneNumber)
            }
            recipients = tmp
        }
        ListElement {
            phoneNumber: ""
            searchItem: true
        }
    }
    Flickable {
        id: scrollableArea
        anchors.fill: parent
        contentWidth: contactFlow.width
        flickableDirection: Flickable.HorizontalFlick
        Flow {
            id: contactFlow
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1)
            //anchors.right: parent.right
            anchors.top: parent.top
            move: Transition {
                UbuntuNumberAnimation { properties: "x,y";}
            }

            Component {
                id: contactDelegate
                Button {
                    property string contactName: {
                        if (contactWatcher.isUnknown) {
                            return contactWatcher.phoneNumber
                        }
                        return contactWatcher.alias
                    }
                    property alias phoneNumber: contactWatcher.phoneNumber
                    property int index
                    property bool selected: selectedIndex == index
                    height: units.gu(4)
                    visible: height != 0
                    color: selected ? UbuntuColors.warmGrey : UbuntuColors.orange
                    text: contactName
                    onClicked: selectedIndex == index ? selectedIndex = -1 : selectedIndex = index

                    ContactWatcher {
                        id: contactWatcher
                    }
                }
            }
            Component {
                id: searchDelegate
                TextField {
                    id: contactSearchInput
                    objectName: "contactSearchInput"
                    focus: true
                    style: MultiRecipientFieldStyle {}
                    height: units.gu(4)
                    // FIXME: this size should be variable
                    width: units.gu(20)
                    hasClearButton: false
                    clip: false
                    placeholderText: i18n.tr("Add contacts..")
                    color: UbuntuColors.warmGrey
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    font.family: "Ubuntu"
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onActiveFocusChanged: {
                        if (!activeFocus && text !== "") {
                            addRecipient(text)
                            text = ""
                        }
                    }
                    onTextChanged: searchString = text
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
                        property: "phoneNumber"
                        value: phoneNumber
                        when: (phoneNumber && status == Loader.Ready)
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
