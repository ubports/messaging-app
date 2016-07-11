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

    function commitWithProperties(properties) {
        if (_realPage) {
            _realPage.destroy()
        }
        _realPage = messagesComponent.createObject(null, properties)
        commit()
    }

    property bool showingConversation: _realPage && _realPage.state !== "newMessage"

    property var _realPage: null

    height: parent ? parent.height : 0
    hint.text: i18n.tr("+")
    contentComponent: Item {
        id: pageContent
        implicitWidth: bottomEdge.width
        implicitHeight: bottomEdge.height
        children: bottomEdge._realPage
    }

    Component.onCompleted: {
        if (!_realPage) {
            _realPage = messagesComponent.createObject(null)
        }
        mainView.setBottomEdge(bottomEdge)
    }

    Component.onDestruction: {
        mainView.unsetBottomEdge(bottomEdge)
        if (_realPage) {
            _realPage.destroy()
        }
    }

    onCollapseCompleted: {
        if (_realPage) {
            _realPage.destroy()
        }
        _realPage = messagesComponent.createObject(null)
    }

    Component {
        id: messagesComponent

        Messages {
            anchors.fill: parent
            onCancel: bottomEdge.collapse()
            basePage: bottomEdge.parent
            startedFromBottomEdge: true
        }
    }

}
