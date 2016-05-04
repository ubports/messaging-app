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

AdaptivePageLayout {
    id: layout
    property var _pagesToRemove: []

    layouts: PageColumnsLayout {
        when: mainStack.width >= units.gu(90)
        PageColumn {
            maximumWidth: units.gu(50)
            minimumWidth: units.gu(40)
            preferredWidth: units.gu(40)
        }
        PageColumn {
            fillWidth: true
        }
    }


    function deleteInstances() {
        for (var i in _pagesToRemove) {
            if (_pagesToRemove[i].destroy) {
                _pagesToRemove[i].destroy()
            }
        }
        _pagesToRemove = []
    }

    function removePage(page) {
        // check if this page was allocated dynamically and then remove it
        for (var i in _pagesToRemove) {
            if (_pagesToRemove[i] == page) {
                _pagesToRemove[i].destroy()
                _pagesToRemove.splice(i, 1)
                break
            }
        }
        removePages(page)
    }

    function addFileToNextColumnSync(parentObject, resolvedUrl, properties) {
        addComponentToNextColumnSync(parentObject, Qt.createComponent(resolvedUrl), properties)
    }

    function addFileToCurrentColumnSync(parentObject, resolvedUrl, properties) {
        addComponentToCurrentColumnSync(parentObject, Qt.createComponent(resolvedUrl), properties)
    }

    function addComponentToNextColumnSync(parentObject, component, properties) {
        if (typeof(properties) === 'undefined') {
            properties = {}
        }
        var page = component.createObject(parentObject, properties)
        layout.addPageToNextColumn(parentObject, page)
        _pagesToRemove.push(page)
    }

    function addComponentToCurrentColumnSync(parentObject, component, properties) {
        if (typeof(properties) === 'undefined') {
            properties = {}
        }
        var page = component.createObject(parentObject, properties)
        layout.addPageToCurrentColumn(parentObject, page)
        _pagesToRemove.push(page)
    }
}
