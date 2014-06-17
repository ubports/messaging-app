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
import Ubuntu.Components 0.1
import Ubuntu.Content 0.1
import ".."

Page {
    title: ""
    property variant attachment
    signal actionTriggered
    tools: ToolbarItems {
        ToolbarButton {
            objectName: "saveButton"
            action: Action {
                text: i18n.tr("Save")
                iconSource: "image://theme/save"
                onTriggered: {
                    mainStack.push(picker, {"url": attachment.filePath, "handler": ContentHandler.Destination});
                    actionTriggered()
                }
            }
        }

        ToolbarButton {
            objectName: "shareButton"
            action: Action {
                iconSource: "image://theme/share"
                text: i18n.tr("Share")
                onTriggered: {
                    mainStack.push(picker, {"url": attachment.filePath, "handler": ContentHandler.Share});
                    actionTriggered()
                }
            }
        }
    }
}
