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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Dialog {
    id: mmsDialog

    signal accepted(var message)

    property var message: null

    title: i18n.tr("MMS support required")
    text: i18n.tr("MMS support is required to send this message.\nDo you want to enable it?")

    Button {
        id: yesButton
        text: i18n.tr("Enable")
        color: theme.palette.normal.positive
        onClicked: {
            telepathyHelper.mmsEnabled = true
            mmsDialog.accepted(message)
            PopupUtils.close(mmsDialog)
        }
    }

    Button {
        id: noButton
        text: i18n.tr("Cancel")
        onClicked: PopupUtils.close(mmsDialog)
    }
}
