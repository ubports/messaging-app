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
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Component {
    id: emptyGroupWarningDialog

    Dialog {
        id: dialogue
        property int selectedIndex: -1;
        text: i18n.tr("There won't be active members after removal and the group could be cancelled");
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(4)
                Button {
                    objectName: "emptyGroupWarningDialogCancel"
                    text: i18n.tr("Cancel")
                    color: UbuntuColors.orange
                    onClicked: {
                        PopupUtils.close(dialogue)
                        Qt.inputMethod.hide()
                    }
                }
                Button {
                    objectName: "emptyGroupWarningDialogOk"
                    text: i18n.tr("Ok")
                    color: UbuntuColors.orange
                    onClicked: {
                        PopupUtils.close(dialogue)
                        Qt.inputMethod.hide()
                        dialogue.caller.removeParticipant(selectedIndex);
                    }
                }
            }
            Row {
                spacing: units.gu(1)
                CheckBox {
                    id: dontAskAgainCheckbox
                    checked: false
                    onCheckedChanged: settings.messagesDontShowEmptyGroupWarning = checked
                }
                Label {
                    text: i18n.tr("Don't ask again")
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
