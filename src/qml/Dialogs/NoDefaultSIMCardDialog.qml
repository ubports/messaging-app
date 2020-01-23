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

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Telephony 0.1

Component {
    Dialog {
        id: dialogue
        title: i18n.tr("Welcome to your Messaging app!")
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight + units.gu(6)
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("If you wish to edit your SIM and other mobile preferences, please visit <a href=\"system_settings\">System Settings</a>.")
                wrapMode: Text.WordWrap
                onLinkActivated: {
                    PopupUtils.close(dialogue)
                    Qt.openUrlExternally("settings:///system/cellular")
                }
            }
            Button {
                objectName: "closeNoSimCardDefaultDialog"
                text: i18n.tr("Close")
                onClicked: {
                    settings.mainViewIgnoreFirstTimeDialog = true
                    PopupUtils.close(dialogue)
                    Qt.inputMethod.hide()
                }
            }
        }
    }
}
