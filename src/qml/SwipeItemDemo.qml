/*
 * Copyright 2012-2015 Canonical Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0

import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1


Loader {
    id: root

    property bool necessary: true
    property bool enabled: false


    function enable() {
        root.enabled = true;
    }

    function disable() {
        if (root.enabled) {
            root.necessary = false;
            root.enabled = false;
        }
    }

    sourceComponent: necessary && enabled ? listItemDemoComponent : null

    Settings {
        property alias hintNecessary: root.necessary
    }

    Component {
        id: listItemDemoComponent

        Rectangle {
            id: rectangleContents

            color: "black"
            opacity: 0.0
            anchors.fill: parent

            Behavior on opacity {
                UbuntuNumberAnimation {
                    duration:  UbuntuAnimation.SlowDuration
                }
            }

            Button {
                id: gotItButton
                objectName: "gotItButton"

                anchors {
                    bottom: dragTitle.top
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: units.gu(19)
                }
                width: units.gu(17)
                strokeColor: UbuntuColors.green
                text: i18n.tr("Got it")
                enabled: !dismissAnimation.running
                onClicked: dismissAnimation.start()

                InverseMouseArea {
                    anchors.fill: parent
                    topmostItem: false
                }
            }

            RowLayout {
                id: dragTitle

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: listItem.top
                    margins: units.gu(1)
                }
                height: units.gu(3)
                spacing: units.gu(2)

                Image {
                    visible: listItem.swipeState === "RightToLeft"
                    source: Qt.resolvedUrl("./assets/swipe_arrow.svg")
                    rotation: 180
                    Layout.preferredWidth: sourceSize.width
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    fillMode: Image.Pad
                    sourceSize {
                        width: units.gu(7)
                        height: units.gu(2)
                    }
                }

                Label {
                    id: dragMessage

                    Layout.fillWidth: true
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    wrapMode: Text.Wrap
                    fontSize: "large"
                    color: "#ffffff"
                }

                Image {
                    visible: listItem.swipeState === "LeftToRight"
                    source: Qt.resolvedUrl("./assets/swipe_arrow.svg")
                    Layout.preferredWidth: sourceSize.width
                    height: parent.height
                    verticalAlignment: Image.AlignVCenter
                    fillMode: Image.Pad
                    sourceSize {
                        width: units.gu(7)
                        height: units.gu(2)
                    }
                }
            }

            MessageDelegateFactory {
                id: listItem

                property int xPos: 0
                // message data
                property int index: 10
                property int textMessageStatus: 1
                property var textMessageAttachments: []
                property var messageData: null

                incoming: true
                accountLabel: ""
                enabled: false

                anchors {
                    bottom: parent.bottom
                    bottomMargin: units.gu(8)
                    left: parent.left
                    right: parent.right
                }

                Component.onCompleted: {
                    messageData = {
                    "textMessage": i18n.tr("Welcome to your Ubuntu messaging app."),
                    "timestamp": new Date(),
                    "textMessageStatus": 1,
                    "senderId": "self",
                    "textReadTimestamp": new Date(),
                    "textMessageAttachments": [],
                    "newEvent": false,
                    "accountId": "",
                    "accountLabel" : ""}
                }

                rightSideActions: [
                    Action {
                        id: infoAction

                        iconName: "info"
                        text: i18n.tr("Info")
                    },
                    Action {
                        iconName: "reload"
                        text: i18n.tr("Retry")
                    },
                    Action {
                        iconName: "edit-copy"
                        text: i18n.tr("Copy")
                    }
                ]

                animated: false
                onXPosChanged: listItem.updatePosition(xPos)

            }

            SequentialAnimation {
                id: slideAnimation

                readonly property real leftToRightXpos: (-3 * (listItem.actionWidth + units.gu(2)))
                readonly property real rightToLeftXpos: listItem.leftActionWidth

                loops: Animation.Infinite
                running: root.enabled

                PropertyAction {
                    target: dragMessage
                    property: "text"
                    value: i18n.tr("Swipe to reveal actions")
                }

                PropertyAction {
                    target: dragMessage
                    property: "horizontalAlignment"
                    value: Text.AlignLeft
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target:  listItem
                        property: "xPos"
                        from: 0
                        to: slideAnimation.leftToRightXpos
                        duration: 2000
                    }
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }

                PauseAnimation {
                    duration: UbuntuAnimation.SleepyDuration
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        to: 0
                        duration: UbuntuAnimation.SlowDuration
                    }

                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: slideAnimation.leftToRightXpos
                        to: 0
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }

                PropertyAction {
                    target: dragMessage
                    property: "text"
                    value: i18n.tr("Swipe to delete")
                }

                PropertyAction {
                    target: dragMessage
                    property: "horizontalAlignment"
                    value: Text.AlignRight
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: 0
                        to: slideAnimation.rightToLeftXpos
                        duration: UbuntuAnimation.SleepyDuration
                    }
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: UbuntuAnimation.SlowDuration
                    }
                }

                PauseAnimation {
                    duration: UbuntuAnimation.SleepyDuration
                }

                ParallelAnimation {
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        to: 0
                        duration: UbuntuAnimation.SlowDuration
                    }

                    PropertyAnimation {
                        target: listItem
                        property: "xPos"
                        from: slideAnimation.rightToLeftXpos
                        to: 0
                        duration: UbuntuAnimation.SleepyDuration
                    }
                }
            }

            SequentialAnimation {
                id: dismissAnimation

                alwaysRunToEnd: true
                running: false

                UbuntuNumberAnimation {
                    target: rectangleContents
                    property: "opacity"
                    to: 0.0
                    duration:  UbuntuAnimation.SlowDuration
                }
                ScriptAction {
                    script: root.disable()
                }
            }

            Component.onCompleted: {
                opacity = 0.85
            }
        }
    }
}
