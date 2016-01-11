/*
 * Copyright 2015 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.Layouts 1.0

Item {
    id: panel
    signal attachmentAvailable(var attachment)

    property bool expanded: false

    function show() {
        expanded = true
    }

    function hide() {
        expanded = false
    }

    height: expanded ? childrenRect.height + units.gu(3): 0
    opacity: expanded ? 1 : 0
    visible: opacity > 0
    Behavior on height {
        UbuntuNumberAnimation {}
    }
    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    enabled: expanded

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (Qt.inputMethod.visible) {
                panel.expanded = false
            }
        }
    }

    ContentImport {
        id: contentImporter

        onContentReceived: {
            var attachment = {}
            var filePath = String(contentUrl).replace('file://', '')
            attachment["contentType"] = application.fileMimeType(filePath)
            attachment["name"] = filePath.split('/').reverse()[0]
            attachment["filePath"] = filePath
            panel.attachmentAvailable(attachment)
            hide()
        }
    }

    ListItem.ThinDivider {
        id: divider
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
    }

    GridLayout {
        id: grid

        property int iconSize: units.gu(3)
        property int buttonSpacing: units.gu(2)
        anchors {
            top: parent.top
            topMargin: units.gu(3)
            left: parent.left
            right: parent.right
        }

        height: childrenRect.height
        columns: 4
        rowSpacing: units.gu(3)

        TransparentButton {
            id: pictureButton
            objectName: "pictureButton"
            iconName: "stock_image"
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("Image")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                contentImporter.requestPicture()
            }
        }

        TransparentButton {
            id: videoButton
            objectName: "videoButton"
            iconName: "stock_video"
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("Video")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                contentImporter.requestVideo()
            }
        }

        // FIXME: enable generic file sharing if we ever support it
        /*TransparentButton {
            id: fileButton
            objectName: "fileButton"
            iconSource: Qt.resolvedUrl("assets/stock_document.svg")
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("File")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                contentImporter.requestDocument()
            }
        }*/

        // FIXME: enable location sharing if we ever support it
        /*TransparentButton {
            id: locationButton
            objectName: "locationButton"
            iconName: "location"
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("Location")
            Layout.alignment: Qt.AlignHCenter
        }*/

        TransparentButton {
            id: contactButton
            objectName: "contactButton"
            iconName: "stock_contact"
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("Contact")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                contentImporter.requestContact()
            }
        }

        // FIXME: enable that once we add support for burn-after-read
        /*TransparentButton {
            id: burnAfterReadButton
            objectName: "burnAfterReadButton"
            iconSource: Qt.resolvedUrl("assets/burn-after-read.svg")
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("Burn after read")
            Layout.alignment: Qt.AlignHCenter
        }*/
    }
}

