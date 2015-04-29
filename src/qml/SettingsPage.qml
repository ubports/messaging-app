/*
 * Copyright 2012-2015 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import GSettings 1.0

Page {
    id: settingsPage
    title: i18n.tr("Settings")
    head.sections.model: [ i18n.tr("General") ]
    property var settingsModel: [
        { "name": "mmsGroupChatEnabled",
          "description": i18n.tr("Enable MMS group chat")
        }
    ]

    GSettings {
        id: gsettings
        schema.id: "com.ubuntu.phone"
    }

    Component {
        id: settingDelegate
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(6)
            Label {
                id: descriptionLabel
                text: modelData.description
                anchors.left: parent.left
                anchors.right: checkbox.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: units.gu(2)
            }
            Switch {
                id: checkbox
                anchors.right: parent.right
                anchors.rightMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                checked: eval("gsettings."+modelData.name) 
                onCheckedChanged: {
                    if (eval("gsettings."+modelData.name) != checked) {
                        eval("gsettings."+modelData.name+ "= checked")
                    }
                }
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: settingsModel
        delegate: settingDelegate
    }
}

