/*
 * Copyright 2022 Ubports Foundation
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

Dialog {
    id: dialog

    property int threadCount: 0

    title: i18n.tr("Delete thread", "Delete threads", threadCount)

    text: i18n.tr("Are you sure you want to delete this thread ?", "Are you sure you want to delete %1 threads ?", threadCount).arg(threadCount)

    signal accepted()
    signal canceled()

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(2)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(4)
            Button {
                text: i18n.tr("Cancel")
                onClicked: dialog.canceled()
            }
            Button {
                text: i18n.tr("Delete")
                color: theme.palette.normal.negative
                onClicked: dialog.accepted()
            }
        }
    }
}

