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

FocusScope {
    id: multiRecipientWidget
    property bool expanded: activeFocus
    property int recipientCount: recipientModel.count-2
    property int selectedIndex: -1
    property variant recipients: []
    property string searchString: ""
    signal clearSearch()
    height: !visible ? 0 : expanded ? contactFlow.height : units.gu(4)
    z: 1
    onExpandedChanged: {
        if(!expanded)
            selectedIndex = -1
    }
    onActiveFocusChanged: {
        expanded = activeFocus
    }

    function addRecipient(phoneNumber) {
        for (var i = 0; i<recipientModel.count; i++) {
            // FIXME: replace by a phone number comparison method
            if (recipientModel.get(i).phoneNumber === phoneNumber) {
                // FIXME: we should warn the user about this duplicate
                return
            }
        }

        recipientModel.insert(recipientCount+1, { "phoneNumber": phoneNumber })
    }

    MouseArea {
        anchors.fill: parent
        enabled: !expanded
        onClicked: expanded = !expanded
        z: 2
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
            expanderItem: true
        }
        ListElement {
            phoneNumber: ""
            searchItem: true
        }
    }

    Flow {
        id: contactFlow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        move: Transition {
            UbuntuNumberAnimation { properties: "x,y";}
        }

        Component {
            id: expanderDelegate
            Item {
                height: units.gu(4)
                width: units.gu(3)
                Icon {
                    height: units.gu(2)
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(1)
                    name: "chevron"
                    color: "white"
                    rotation: expanded ? 90 : 0
                    Behavior on rotation {
                        UbuntuNumberAnimation { }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            expanded = !expanded
                        }
                    }
                }
            }
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
                height: {
                    if (!expanded && index != 1)
                        0
                    else
                        units.gu(4)
                }
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
                focus: expanded
                style: null
                height: units.gu(4)
                width: units.gu(12)
                hasClearButton: false
                placeholderText: i18n.tr("Add contacts..")
                color: UbuntuColors.warmGrey
                font.pixelSize: FontUtils.sizeToPixels("large")
                font.family: "Ubuntu"
                Component.onCompleted: forceActiveFocus()
                inputMethodHints: Qt.ImhNoPredictiveText
                onActiveFocusChanged: {
                    if (!activeFocus && text !== "") {
                        addRecipient(text)
                        text = ""
                        expanded = false
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
                Keys.onPressed: {
                    if (event.key === Qt.Key_Backspace && text == "" && recipientCount > 0) {
                        if (selectedIndex != -1) {
                            recipientModel.remove(selectedIndex)
                            selectedIndex = -1
                        } else {
                            recipientModel.remove(recipientCount)
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
        Component {
            id: numberRecipientsDelegate
            Label {
                height: units.gu(4)
                verticalAlignment: Text.AlignVCenter
                color: recipientCount == 0 ? Theme.palette.normal.backgroundText : Theme.palette.normal.foregroundText
                text: {
                    if (recipientCount > 1) {
                        return "+"+ String(recipientCount-1)
                    }
                    else if (recipientCount == 0) {
                        return i18n.tr("Add contacts...")
                    } else {
                        return ""
                    }
                }
            }
        }
        spacing: units.gu(1)
        Repeater {
            id: rpt
            model: recipientModel
            delegate: Loader {
                sourceComponent: {
                    if (searchItem)
                        if (expanded)
                            searchDelegate
                        else
                            numberRecipientsDelegate
                    else if (expanderItem)
                        expanderDelegate
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

    ContactSearchListView {
        id: contactSearch
        property string searchTerm: {
            if(multiRecipientWidget.searchString !== "" && multiRecipientWidget.expanded) {
                return multiRecipientWidget.searchString
            }
            return "some value that won't match"
        }
        clip: false
        anchors {
            top: multiRecipientWidget.bottom
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            bottomMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        states: [
            State {
                name: "empty"
                when: contactSearch.count == 0
                PropertyChanges {
                    target: contactSearch
                    height: 0
                }
            }
        ]

        Behavior on height {
            UbuntuNumberAnimation { }
        }

        filter: UnionFilter {
            DetailFilter {
                detail: ContactDetail.Name
                field: Name.FirstName
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

            DetailFilter {
                detail: ContactDetail.Name
                field: Name.LastName
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

            DetailFilter {
                detail: ContactDetail.PhoneNumber
                field: PhoneNumber.Number
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchPhoneNumber
            }

            DetailFilter {
                detail: ContactDetail.PhoneNumber
                field: PhoneNumber.Number
                value: contactSearch.searchTerm
                matchFlags: DetailFilter.MatchContains
            }

        }

        onDetailClicked: {
            multiRecipientWidget.addRecipient(detail.number)
            multiRecipientWidget.clearSearch()
        }
    }

    Rectangle {
        anchors.fill: contactSearch
        anchors.leftMargin: -units.gu(2)
        anchors.rightMargin: -units.gu(2)
        color: "black"
        opacity: 0.6
        z: -1
    }
}
