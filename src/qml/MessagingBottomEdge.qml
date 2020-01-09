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

BottomEdge {
    id: bottomEdge

    height: parent ? parent.height : 0
    hint.text: i18n.tr("+")
    hint.visible: true
    contentUrl: Qt.resolvedUrl("Messages.qml")
    preloadContent: true

    onCommitCompleted: {
        layout.addPageToNextColumn(mainPage, bottomEdge.contentUrl)
        collapse()
    }

    Binding {
        target: contentItem
        property: "height"
        value: mainView.height
    }
}
