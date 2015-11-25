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
    Behavior on height {
        UbuntuNumberAnimation {}
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

        // FIXME: re-enable that once we have proper delegates
        /*TransparentButton {
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
        }*/

        // FIXME: enable generic file sharing if we ever support it
        /*TransparentButton {
            id: fileButton
            objectName: "fileButton"
            iconSource: Qt.resolvedUrl("assets/stock_document.svg")
            iconSize: grid.iconSize
            spacing: grid.buttonSpacing
            text: i18n.tr("File")
            Layout.alignment: Qt.AlignHCenter
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

