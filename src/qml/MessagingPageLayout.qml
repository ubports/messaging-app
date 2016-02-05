import QtQuick 2.0
import Ubuntu.Components 1.3

AdaptivePageLayout {
    id: layout
    property var _pagesToRemove: []

    function deleteInstances() {
        for (var i in _pagesToRemove) {
            if (_pagesToRemove[i].destroy) {
                _pagesToRemove[i].destroy()
            }
        }
        _pagesToRemove = []
    }

    function removePage(page) {
        // check if this page was allocated dynamically and then remove it
        for (var i in _pagesToRemove) {
            if (_pagesToRemove[i] == page) {
                _pagesToRemove[i].destroy()
                _pagesToRemove.splice(i, 1)
                break
            }
        }
        removePages(page)
    }

    function addFileToNextColumnSync(parentObject, resolvedUrl, properties) {
        addComponentToNextColumnSync(parentObject, Qt.createComponent(resolvedUrl), properties)
    }

    function addFileToCurrentColumnSync(parentObject, resolvedUrl, properties) {
        addComponentToCurrentColumnSync(parentObject, Qt.createComponent(resolvedUrl), properties)
    }

    function addComponentToNextColumnSync(parentObject, component, properties) {
        if (typeof(properties) === 'undefined') {
            properties = {}
        }
        var page = component.createObject(parentObject, properties)
        layout.addPageToNextColumn(parentObject, page)
        _pagesToRemove.push(page)
    }

    function addComponentToCurrentColumnSync(parentObject, component, properties) {
        if (typeof(properties) === 'undefined') {
            properties = {}
        }
        var page = component.createObject(parentObject, properties)
        layout.addPageToCurrentColumn(parentObject, page)
        _pagesToRemove.push(page)
    }
}
