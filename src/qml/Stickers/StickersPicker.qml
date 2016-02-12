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
import messagingapp.private 0.1

FocusScope {
    id: pickerRoot
    signal stickerSelected(string path)

    Component.onCompleted: {
        StickersHistoryModel.databasePath = dataLocation + "/stickers/stickers.sqlite"
        StickersHistoryModel.limit = 10
    }

    property bool expanded: false
    readonly property int packCount: stickerPacksModel.count

    // FIXME: try to get something similar to the keyboard height
    // FIXME: animate the displaying
    height: expanded ? units.gu(30) : 0
    opacity: expanded ? 1 : 0
    visible: opacity > 0

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (Qt.inputMethod.visible && oskEnabled) {
                pickerRoot.expanded = false
            }
        }
    }

    Behavior on height {
        UbuntuNumberAnimation { }
    }

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    ListView {
        id: setsList
        model: stickerPacksModel
        orientation: ListView.Horizontal
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: units.gu(6)

        header: HistoryButton {
            height: units.gu(6)
            width: height

            onTriggered: stickersGrid.model.packName = ""
            selected: stickersGrid.model.packName === ""
        }
        delegate: StickerPackDelegate {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.gu(6)

            path: filePath
            onTriggered: stickersGrid.model.packName = fileName
            selected: stickersGrid.model.packName === fileName
        }
    }

    Rectangle {
        anchors.fill: stickersGrid
        color: "#f5f5f5"
    }

    GridView {
        id: stickersGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: setsList.bottom
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: units.gu(10)
        cellHeight: units.gu(10)
        visible: stickersGrid.model.packName.length > 0

        model: stickersModel
        delegate: StickerDelegate {
            stickerSource: filePath
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onTriggered: {
                StickersHistoryModel.add("%1/%2".arg(stickersGrid.model.packName).arg(fileName))
                pickerRoot.stickerSelected(stickerSource)
            }
        }
    }

    GridView {
        id: historyGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: setsList.bottom
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: units.gu(10)
        cellHeight: units.gu(10)
        visible: stickersGrid.model.packName.length === 0

        model: StickersHistoryModel

        delegate: StickerDelegate {
            stickerSource: "%1/stickers/%2".arg(dataLocation).arg(sticker)
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onTriggered: {
                StickersHistoryModel.add(sticker)
                pickerRoot.stickerSelected(stickerSource)
            }
        }
    }
}
