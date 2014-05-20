/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
    Example:

    MainView {
        objectName: "mainView"

        applicationName: "com.ubuntu.developer.boiko.bottomedge"

        width: units.gu(100)
        height: units.gu(75)

        Component {
            id: pageComponent

            PageWithBottomEdge {
                id: mainPage
                title: i18n.tr("Main Page")

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                }

                bottomEdgePageComponent: Page {
                    title: "Contents"
                    anchors.fill: parent
                    //anchors.topMargin: contentsPage.flickable.contentY

                    ListView {
                        anchors.fill: parent
                        model: 50
                        delegate: ListItems.Standard {
                            text: "One Content Item: " + index
                        }
                    }
                }
                bottomEdgeTitle: i18n.tr("Bottom edge action")
            }
        }

        PageStack {
            id: stack
            Component.onCompleted: stack.push(pageComponent)
        }
    }

*/

import QtQuick 2.0
import Ubuntu.Components 0.1

Page {
    id: page

    property alias bottomEdgePageComponent: edgeLoader.sourceComponent
    property alias bottomEdgePageSource: edgeLoader.source
    property alias bottomEdgeTitle: tipLabel.text
    property alias bottomEdgeEnabled: bottomEdge.visible
    property int bottomEdgeExpandThreshold: page.height * 0.3
    property int bottomEdgeExposedArea: bottomEdge.state !== "expanded" ? (page.height - bottomEdge.y - tip.height) : _areaWhenExpanded
    property bool reloadBottomEdgePage: true

    readonly property alias bottomEdgePage: edgeLoader.item
    readonly property bool isReady: (tip.opacity === 0.0)
    readonly property bool isCollapsed: (tip.opacity === 1.0)
    readonly property bool bottomEdgePageLoaded: (edgeLoader.status == Loader.Ready)

    property bool _showEdgePageWhenReady: false
    property int _areaWhenExpanded: 0

    signal bottomEdgeReleased()
    signal bottomEdgeDismissed()

    function showBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
        _showEdgePageWhenReady = true
    }

    function setBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
    }

    function _pushPage()
    {
        if (edgeLoader.status === Loader.Ready) {
            edgeLoader.item.active = true
            page.pageStack.push(edgeLoader.item)
            if (edgeLoader.item.flickable) {
                edgeLoader.item.flickable.contentY = -page.header.height
                edgeLoader.item.flickable.returnToBounds()
            }
            if (edgeLoader.item.ready)
                edgeLoader.item.ready()
        }
    }

    Component.onCompleted: {
        // avoid a binding on the expanded height value
        var expandedHeight = height;
        _areaWhenExpanded = expandedHeight;
    }

    onActiveChanged: {
        if (active) {
            bottomEdge.state = "collapsed"
        }
    }

    onBottomEdgePageLoadedChanged: {
        if (_showEdgePageWhenReady && bottomEdgePageLoaded) {
            bottomEdge.state = "expanded"
            _showEdgePageWhenReady = false
        }
    }

    Item {
        id: bottomEdge
        objectName: "bottomEdge"

        z: 1
        height: (edgeLoader.item && edgeLoader.item.flickable) ? page.height + tip.height : page.height + tip.height - header.height
        y: page.height - tip.height
        clip: true
        anchors {
            left: parent.left
            right: parent.right
        }

        Item {
            id: tip
            objectName: "bottomEdgeTip"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: units.gu(4)
            z: 1

            opacity: state !== "expanded" ? 1.0 : 0

            Rectangle {
                id: shadow
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: units.gu(1)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                }
                opacity: bottomEdge.state != "collapsed" ? 1.0 : 0.0
                Behavior on opacity {
                    UbuntuNumberAnimation { }
                }
            }

            Rectangle {
                anchors {
                    fill: parent
                    topMargin: units.gu(1)
                }
                color: UbuntuColors.coolGrey
                Label {
                    id: tipLabel
                    anchors.centerIn: parent
                }
            }

            MouseArea {
                anchors.fill: parent
                drag.axis: Drag.YAxis
                drag.target: bottomEdge
                drag.minimumY: 0

                onReleased: {
                    page.bottomEdgeReleased()
                    if (bottomEdge.y < (page.height - bottomEdgeExpandThreshold - tip.height)) {
                        bottomEdge.state = "expanded"
                    } else {
                        bottomEdge.state = "collapsed"
                    }
                }

                onPressed: bottomEdge.state = "floating"
            }
        }

        state: "collapsed"
        states: [
            State {
                name: "collapsed"
                PropertyChanges {
                    target: bottomEdge
                    parent: page
                    y: page.height - tip.height
                }
            },
            State {
                name: "expanded"

                PropertyChanges {
                    target: bottomEdge
                    y: - tip.height + header.height
                }

                PropertyChanges {
                    target: tip
                    opacity: 0.0
                }
            }
        ]

        transitions: [
            Transition {
                to: "expanded"
                SequentialAnimation {
                    UbuntuNumberAnimation {
                        targets: [bottomEdge,tip]
                        properties: "y,opacity"
                        duration: 500
                    }

                    ScriptAction {
                        script: page._pushPage()
                    }
                }
            },
            Transition {
                from: "expanded"
                to: "collapsed"
                SequentialAnimation {
                    ScriptAction {
                        script: {
                            edgeLoader.item.parent = edgeLoader
                            edgeLoader.item.anchors.fill = edgeLoader
                            edgeLoader.item.active = false
                        }
                    }
                    UbuntuNumberAnimation {
                        targets: [bottomEdge,tip]
                        properties: "y,opacity"
                        duration: 500
                    }
                    ScriptAction {
                        script: {
                            // destroy current bottom page
                            if (page.reloadBottomEdgePage) {
                                edgeLoader.active = false
                            }
                            // FIXME: this is ugly, but the header is not updating the title correctly
                            var title = page.title
                            page.title = "Something else"
                            page.title = title
                            // fix for a bug in the sdk header
                            activeLeafNode = page

                            // notify
                            page.bottomEdgeDismissed()

                            // load a new bottom page in memory
                            edgeLoader.active = true
                        }
                    }
                }
            },
            Transition {
                from: "floating"
                to: "collapsed"
                UbuntuNumberAnimation {
                    targets: [bottomEdge,tip]
                    properties: "y,opacity"
                    duration: 500
                }
            }
        ]

        // this is necessary because the Page item is translucid
        Rectangle {
            id: edgePageBackground

            clip: true
            anchors {
                left: parent.left
                right: parent.right
                top: tip.bottom
                bottom: parent.bottom
            }

            color: Theme.palette.normal.background

            //WORKAROUND: The SDK move the page contents down to allocate space for the header we need to avoid that during the page dragging
            Binding {
                target: edgePageBackground
                property: "anchors.topMargin"
                value: edgeLoader.item && edgeLoader.item.flickable ? edgeLoader.item.flickable.contentY : 0
                when: (edgeLoader.status === Loader.Ready && !page.isReady)
            }

            Loader {
                id: edgeLoader

                active: true
                anchors.fill: parent
                asynchronous: true
                onLoaded: {
                    if (page.isReady && edgeLoader.item.active != true) {
                        page._pushPage()
                    }
                }
            }
        }
    }
}
