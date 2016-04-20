import QtQuick 2.0
import Ubuntu.Components 1.3

BottomEdge {
    id: bottomEdge

    function commitWithProperties(properties) {
        _realPage.destroy()
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
        mainView.bottomEdge = bottomEdge
        _realPage = messagesComponent.createObject(null)
    }

    Component.onDestruction: {
        _realPage.destroy()
    }

    onCollapseCompleted: {
        _realPage.destroy()
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
