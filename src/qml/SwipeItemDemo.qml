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

    // Display the hint only once after taking the very first photo
    Settings {
        property alias hintNecessary: root.necessary
    }

    Component {
        id: listItemDemoComponent

        Rectangle {
            color: "black"
            opacity: 0.85
            anchors.fill: parent


            MessageDelegateFactory {
                id: listItem

                property int xPos: 0
                // message data
                property int index: 10
                property int textMessageStatus: 1
                property var textMessageAttachments: []
                property string accountLabel: ""
                property var messageData: null

                Component.onCompleted: {
                    messageData = {
                    "textMessage": i18n.tr("You recevied a new message"),
                    "timestamp": (new Date()).getTime(),
                    "textMessageStatus": 1,
                    "senderId": "self",
                    "textReadTimestamp": (new Date()).getTime(),
                    "textMessageAttachments": [],
                    "newEvent": false,
                    "accountId": "0001" }
                }
                incoming: false

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
                anchors {
                    top: parent.top
                    topMargin: units.gu(14)
                    left: parent.left
                    right: parent.right
                }
            }

            RowLayout {
                id: dragTitle

                anchors {
                    left: parent.left
                    right: parent.right
                    top: listItem.bottom
                    margins: units.gu(1)
                    //topMargin: units.gu(1)
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

            SequentialAnimation {
                id: slideAnimation

                readonly property real leftToRightXpos: (-3 * (listItem.actionWidth + units.gu(2)))
                readonly property real rightToLeftXpos: listItem.leftActionWidth

                loops: Animation.Infinite
                running: root.enabled

                PropertyAction {
                    target: dragMessage
                    property: "text"
                    value: i18n.tr("Swipe to reveal more actions")
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
                        duration: 1000
                    }
                }

                PauseAnimation {
                    duration: 1000
                }

                PropertyAction {
                    target: dragTitle
                    property: "opacity"
                    value: 0
                }

                PropertyAnimation {
                    target: listItem
                    property: "xPos"
                    from: slideAnimation.leftToRightXpos
                    to: 0
                    duration: 1000
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
                        duration: 1000
                    }
                    PropertyAnimation {
                        target: dragTitle
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 500
                    }
                }

                PauseAnimation {
                    duration: 1000
                }

                PropertyAction {
                    target: dragTitle
                    property: "opacity"
                    value: 0
                }

                PropertyAnimation {
                    target: listItem
                    property: "xPos"
                    from: slideAnimation.rightToLeftXpos
                    to: 0
                    duration: 1000
                }
            }

            Button {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: units.gu(9)
                }
                width: units.gu(17)
                strokeColor: UbuntuColors.green
                text: i18n.tr("Got it")
                onClicked: root.disable()
            }
        }
    }
}
