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
    property variant _popover: null

    signal selected(var participant)

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

    function showParticpantsStartWith(parent, prefix)
    {
        var result = []
        for(var i = 0; i < participants.length; i++) {
            var valid = true
            if (prefix.length !== 0) {
                valid = String(participants[i].identifier).indexOf(prefix) === 0
            }

            if (valid) {
                result.push(participants[i])
            }
        }

        if (result.length === 0)
        {
            return
        }

        if (result.length === 1)
        {
            selected(result[0])
            return
        }

        if (_popover === null) {
            _popover = PopupUtils.open(componentParticipantsPopover, parent)
        }
        result.sort(compareParticipants)
        _popover.model = result
    }

    onSelected: {
        if (_popover) {
            PopupUtils.close(_popover)
            root._popover = null
        }
    }

    Component {
        id: componentParticipantsPopover

        Popover {
            id: participantsPopover

            property alias model: view.model

            UbuntuListView {
                id: view

                width: root.width / 2
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
                onActiveFocusChanged: {
                    if (!activeFocus && root._popover)
                        root.selected(null)
                }
                Keys.onEscapePressed: root.selected(null)
            }

            Component.onDestruction: root._popover = null
        }
    }
}
