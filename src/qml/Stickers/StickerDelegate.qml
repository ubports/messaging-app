/*
 * Copyright 2015 Canonical Ltd.
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

import QtQuick 2.3
import Ubuntu.Components 1.3


AbstractButton {
    id: root
    property alias stickerSource: image.source
    width: units.gu(10)
    height: units.gu(10)
    visible: image.status == Image.Ready

    signal notFound()

    Image {
        id: image
        anchors.fill: parent
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        anchors.margins: units.gu(0.5)
        fillMode: Image.PreserveAspectFit
        smooth: true
        onStatusChanged: if (image.status == Image.Error) root.notFound()
        scale: root.pressed ? 1.5 : 1
        Behavior on scale {
            UbuntuNumberAnimation {}
        }
    }

}
