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

import QtQuick 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import "dateUtils.js" as DateUtils

Item {
    id: threadsSectionDelegate

    function formatSectionTitle(title)
    {
        return title
    }

    anchors {
        left: parent.left
        right: parent.right
        margins: units.gu(2)
    }
    height: units.gu(3)
    Label {
        anchors.fill: parent
        elide: Text.ElideRight
        text: formatSectionTitle(section)
        verticalAlignment: Text.AlignVCenter
        fontSize: "small"
        color: Theme.palette.normal.backgroundTertiaryText
    }
    ListItem.ThinDivider {
        anchors.bottom: parent.bottom
    }
}
