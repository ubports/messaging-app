/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
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

Component {
    Dialog {
        id: dialogue
        title: i18n.tr("File size warning")
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("You are trying to send big files (over 300Kb). Some operators might not be able to send it.")
                wrapMode: Text.WordWrap
            }
            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    objectName: "okFileSizeWarningDialog"
                    text: i18n.tr("Ok")
                    onClicked: {
                        PopupUtils.close(dialogue)
                    }
                }
            }

            Row {
                CheckBox {
                    id: dontAskAgainCheckbox
                    checked: false
                    onCheckedChanged: settings.messagesDontShowFileSizeWarning = checked
                }
                Label {
                    text: i18n.tr("Don't show again")
                    anchors.verticalCenter: dontAskAgainCheckbox.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: dontAskAgainCheckbox.checked = !dontAskAgainCheckbox.checked
                    }
                }
            }
        }
    }
}
