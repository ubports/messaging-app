/*
 * Copyright 2016 Canonical Ltd.
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

Item {
    id: emptyStateScreen

    property alias labelVisible: emptyStateLabel.visible

    anchors {
        left: parent.left
        leftMargin: units.gu(6)
        right: parent.right
        rightMargin: units.gu(6)
        verticalCenter: parent.verticalCenter
    }
    height: childrenRect.height
    Icon {
        id: emptyStateIcon
        anchors.top: emptyStateScreen.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: units.gu(5)
        width: height
        opacity: 0.3
        name: "message"
    }
    Label {
        id: emptyStateLabel
        anchors.top: emptyStateIcon.bottom
        anchors.topMargin: units.gu(2)
        anchors.left: parent.left
        anchors.right: parent.right
        text: i18n.tr("Compose a new message by swiping up from the bottom of the screen.")
        color: Theme.palette.normal.backgroundSecondaryText
        fontSize: "x-large"
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
