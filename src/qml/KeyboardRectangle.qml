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

import QtQuick 2.2
import GSettings 1.0

Item {
    id: keyboardRect
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0

    property bool oskEnabled: !gsettings.stayHidden

    function recursiveFindFocusedItem(parent) {
        if (parent.activeFocus) {
            return parent;
        }

        for (var i in parent.children) {
            var child = parent.children[i];
            if (child.activeFocus) {
                return child;
            }

            var item = recursiveFindFocusedItem(child);

            if (item != null) {
                return item;
            }
        }

        return null;
    }

    Connections {
        target: Qt.inputMethod

        onVisibleChanged: {
            if (!Qt.inputMethod.visible) {
                var focusedItem = recursiveFindFocusedItem(keyboardRect.parent);
                if (focusedItem != null) {
                    focusedItem.focus = false;
                }
            }
        }
    }

    GSettings {
        id: gsettings
        schema.id: "com.canonical.keyboard.maliit"
    }
}
