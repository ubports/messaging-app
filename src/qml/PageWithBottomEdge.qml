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

                    // WORKAROUND: SKD changes the page header as soon as the page get created
                    // setting active false will avoid that
                    active: false

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
    property int bottomEdgeExposedArea: page.height - bottomEdge.y - tip.height
    property bool reloadBottomEdgePage: true

    readonly property alias bottomEdgePage: edgeLoader.item
    readonly property bool isReady: (tip.opacity === 0.0)

    signal bottomEdgeReleased()
    signal bottomEdgeDismissed()

    function showBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
        bottomEdge.state = "expanded"
    }

    function setBottomEdgePage(source, properties)
    {
        edgeLoader.setSource(source, properties)
    }

    onActiveChanged: {
        if (active) {
            bottomEdge.state = "collapsed"
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
                        script: {
                            edgeLoader.item.active = true
                            page.pageStack.push(edgeLoader.item)
                            if (edgeLoader.item.ready)
                                edgeLoader.item.ready()
                            edgeLoader.item.forceActiveFocus()
                            if (edgeLoader.item.flickable) {
                                edgeLoader.item.flickable.contentY = -page.header.height
                                edgeLoader.item.flickable.returnToBounds()
                            }
                        }
                    }
                }
            },
            Transition {
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

                onLoaded: item.active = false
            }
        }
    }
}
