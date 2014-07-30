/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem

Item {
    id: root

    property alias text: title.text

    height: visible ? units.gu(3) : 0

    Row {
        anchors.fill: parent
        ListItem.ThinDivider {
            id: div
            width: ((root.width / 2)  - (title.width / 2))
            anchors{
                left: undefined
                right: undefined
                verticalCenter: parent.verticalCenter
            }
        }
        Label {
            id: title
            width: paintedWidth + units.gu(2)
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        ListItem.ThinDivider {
            width: div.width
            anchors{
                left: undefined
                right: undefined
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
