/*
 * Copyright 2012-2013 Canonical Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 0.1

Component {
    Dialog {
        id: dialogue
        title: i18n.tr("SIM Card is locked")
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: units.gu(2)

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight
                verticalAlignment: Text.AlignVCenter
                text: i18n.tr("Please unlock your SIM card to call or send a message. You can revisit your SIM card settings in <a href=\"system_settings\">System Settings &gt; Security &amp; Privacy</a>.")
                wrapMode: Text.WordWrap
                onLinkActivated: {
                    PopupUtils.close(dialogue)
                    Qt.openUrlExternally("settings:///system/security-privacy")
                }
            }
            Row {
                spacing: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                Button {
                    objectName: "okSimLockedDialog"
                    text: i18n.tr("Ok")
                    color: UbuntuColors.orange
                    onClicked: {
                        PopupUtils.close(dialogue)
                    }
                }
                // Please, reenable this once lp:1374215 gets fixed
                /*Button {
                    objectName: "unlockSimLockedDialog"
                    text: i18n.tr("Unlock")
                    color: UbuntuColors.orange
                    onClicked: {
                        PopupUtils.close(dialogue)
                        telepathyHelper.unlockSimCards()
                    }
                }*/
            }
        }
    }
}
