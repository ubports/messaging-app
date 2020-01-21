/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.9
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3


Rectangle {
    id: listItemDemo

    property bool enabled
    signal disable

    anchors.fill: parent
    color: "black"
    opacity: 0.0
    Behavior on opacity {
        UbuntuNumberAnimation {
            duration:  UbuntuAnimation.SlowDuration
        }
    }

    Button {
        id: gotItButton
        objectName: "gotItButton"

        anchors {
            bottom: dragTitle.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: units.gu(21)
        }
        width: units.gu(17)
        strokeColor: theme.palette.normal.positive
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
        spacing: units.gu(2)

        Image {
            visible: listItem.swipePosition < 0
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
            visible: listItem.swipePosition > 0
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

    MessageDelegate {
        id: listItem

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
        height: units.gu(4)

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

        trailingActions: ListItemActions {
            actions: [
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
        }
    }

    SequentialAnimation {
        id: slideAnimation

        readonly property real leadingActionsWidth: listItem.leadingActions.actions.length * units.gu(6) + units.gu(2)
        readonly property real trailingActionsWidth: listItem.trailingActions.actions.length * units.gu(6) + units.gu(2)


        loops: Animation.Infinite
        running: listItemDemo.enabled

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
                property: "swipePosition"
                from: 0
                to: -slideAnimation.trailingActionsWidth
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
                property: "swipePosition"
                from: -slideAnimation.trailingActionsWidth
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
                property: "swipePosition"
                from: 0
                to: slideAnimation.leadingActionsWidth
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
                property: "swipePosition"
                from: slideAnimation.leadingActionsWidth
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
            target: listItemDemo
            property: "opacity"
            to: 0.0
            duration:  UbuntuAnimation.SlowDuration
        }
        ScriptAction {
            script: listItemDemo.disable()
        }
    }

    Component.onCompleted: {
        opacity = 0.85
    }
}
