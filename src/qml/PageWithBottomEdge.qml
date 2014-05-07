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

    readonly property alias bottomEdgePage: edgeLoader.item

    signal bottomEdgeReleased()

    onActiveChanged: {
        if (active) {
            bottomEdge.state = "collapsed"
        }
    }

    Item {
        id: bottomEdge

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

                onPressed: {
                    bottomEdge.state = "floating"
                    edgeLoader.active = true
                }
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
                            edgeLoader.active = false
                            // FIXME: this is ugly, but the header is not updating the title correctly
                            var title = page.title
                            page.title = "Something else"
                            page.title = title
                            // fix for a bug in the sdk header
                            activeLeafNode = page
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

            Loader {
                id: edgeLoader

                active: false
                anchors.fill: parent
                anchors.topMargin: (edgeLoader.status === Loader.Ready ? edgeLoader.item.flickable.contentY : 0)

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.active = false;
                    }
                }
            }
        }
    }
}
