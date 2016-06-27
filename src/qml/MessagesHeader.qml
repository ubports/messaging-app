/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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


import QtQuick 2.2
import Ubuntu.Components 1.3

Item {
    id: header

    property string title: ""
    property string subtitle: ""

    height: units.gu(8)

    anchors {
        verticalCenter: parent.verticalCenter
    }

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    Item {
        height: Math.min(titleText.height + (subtitleText.height ? subtitleText.height + subtitleText.anchors.topMargin : 0), header.height)
        width: header.width
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: units.gu(1)
        }
 
        Label {
            id: titleText
            width: Math.min(implicitWidth, parent.width)
            anchors {
                top: parent.top
                left: parent.left
            }
            verticalAlignment: Text.AlignVCenter

            font.pixelSize: FontUtils.sizeToPixels("large")
            elide: Text.ElideRight
            text: title
        }

        Label {
            id: subtitleText
            width: Math.min(implicitWidth, parent.width)
            height: header.subtitle.length > 0 ? implicitHeight : 0
            anchors {
                left: parent.left
                top: titleText.bottom
                topMargin: units.gu(0.2)
            }
            verticalAlignment: Text.AlignVCenter

            fontSize: "small"
            elide: Text.ElideRight
            text: subtitle

            Connections {
                target: header
                onSubtitleChanged: {
                    subtitleText.opacity = 0;
                    subtitleTextTimer.start();
                }
            }

            Timer {
                id: subtitleTextTimer
                interval: UbuntuAnimation.FastDuration
                onTriggered: {
                    subtitleText.text = header.subtitle;
                    subtitleText.opacity = 1;
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: UbuntuAnimation.FastDuration
                }
            }
        }
    }
}

