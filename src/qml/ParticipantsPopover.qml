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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.Telephony 0.1

import "dateUtils.js" as DateUtils


Item {
    id: root

    property variant participants: []
    readonly property bool active: (_popover != null)
    readonly property bool popupVisible: active && _popover.isPopup

    property variant _popover: null
    property var _sortedParticipants: []

    function compareParticipants(p0, p1)
    {
        var i0 = String(p0.identifier).toLocaleLowerCase()
        var i1 = String(p1.identifier).toLocaleLowerCase()

        if (i0 < i1)
            return -1
        if (i0 > i1)
            return 1
          return 0
    }

    function close()
    {
        if (_popover) {
            if (_popover.isPopup)
                PopupUtils.close(_popover)
            else
                root._popover.destroy()
            root._popover = null
        }
    }

    function showParticpantsStartWith(parent, prefix, showPopup)
    {
        var filter = []
        for(var i = 0; i < participants.length; i++) {
            var valid = true
            if (prefix.length !== 0) {
                valid = String(participants[i].identifier).indexOf(prefix) === 0
            }

            if (valid) {
                filter.push(participants[i])
            }
        }

        root._sortedParticipants = filter
        if (filter.length === 0 && popupVisible)
        {
            return ""
        }

        if ((filter.length === 1) && popupVisible)
        {
            return filter[0].identifier
        }

        if (_popover === null) {
            if (showPopup)
                _popover = PopupUtils.open(componentParticipantsPopover, parent)
            else
                _popover = nonVisualPopover.createObject(root, {"currentIndex": 0})

        }

        _popover.model = _sortedParticipants
        return (filter.length > 0 ? filter[0].identifier : "")
    }

    function nextItem()
    {
        if (_popover === null)
            return ""

        var newIndex = -1
        if (_popover.currentIndex < (_sortedParticipants.length - 1))
            newIndex = _popover.currentIndex + 1
        else
            newIndex =  0

        _popover.currentIndex = newIndex
        return (_sortedParticipants[newIndex].identifier)
    }

    Component {
        id: nonVisualPopover

        QtObject {
            property var model: view.model
            property int currentIndex: -1
            readonly property bool isPopup: false

            Component.onDestruction: root._popover = null
        }
    }

    Component {
        id: componentParticipantsPopover

        Popover {
            id: participantsPopover

            property alias model: view.model
            property alias currentIndex: view.currentIndex
            readonly property bool isPopup: true

            UbuntuListView {
                id: view

                width: root.width
                height: Math.min(contentHeight, root.height / 2)
                model: []

                delegate: ListItem {
                    objectName: "participant%1".arg(index)

                    width: view.width
                    height: layout.height
                    onClicked: root.selected(modelData)

                    ListItemLayout {
                        id: layout
                        title.text: modelData.identifier
                    }
                }
                Keys.onEscapePressed: root.selected(null)
            }

            Component.onDestruction: root._popover = null
        }
    }
}
