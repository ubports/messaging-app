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

import QtQuick 2.2
import Ubuntu.Components 1.3
import Ubuntu.Content 0.1
import ".."

Previewer {
    property string contactName: {
        var info = application.contactNameFromVCard(attachment.filePath)
        if (info["count"] > 1) {
            return info["name"] + " (+%1)".arg(info["count"]-1)
        } else {
            return info["name"]
        }
    }

    title: contactName !== "" ? contactName : i18n.tr("Unknown contact")
    clip: true
}
