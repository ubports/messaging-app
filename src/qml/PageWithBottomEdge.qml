import QtQuick 2.0
import Ubuntu.Components 0.1

Page {
    id: page

    property alias bottomEdgePageComponent: edgeLoader.sourceComponent
    property alias bottomEdgePageSource: edgeLoader.source
    property alias bottomEdgeTitle: tipLabel.text

    onActiveChanged: {
        if (active) {
            bottomEdge.state = "collapsed"
        }
    }

    Item {
        id: bottomEdge

        z: 1
        height: page.height + tip.height
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
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.3) }
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
                color: Theme.palette.normal.background
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
                    if (bottomEdge.y < (page.height * 0.7)) {
                        bottomEdge.state = "expanded"
                    } else {
                        bottomEdge.state = "collapsed"
                    }
                }

                onPressed: {
                    bottomEdge.state = "floating"
                    edgeLoader.active = false
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
                            page.pageStack.push(edgeLoader.item)
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
                            //edgeLoader.item.anchors.topMargin = 0
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
            }
        }
    }
}
