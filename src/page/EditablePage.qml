/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.page

Kirigami.ScrollablePage {
    id: page

    property PageController controller
    readonly property PageDataObject pageData: controller.data
    property bool edit: false
    onEditChanged: {
        if (edit) {
            contentLoader.setSource(Qt.resolvedUrl("PageEditor.qml"), {"parentPage": page, "controller": page.controller})
        } else {
            contentLoader.setSource(Qt.resolvedUrl("PageContents.qml"), {"controller": page.controller})
        }
    }

    title: pageData.title

    leftPadding: pageData.margin * Kirigami.Units.largeSpacing
    rightPadding: pageData.margin * Kirigami.Units.largeSpacing
    topPadding: pageData.margin * Kirigami.Units.largeSpacing
    bottomPadding: pageData.margin * Kirigami.Units.largeSpacing

    // Default pages to be invisible, to ensure that when they're being loaded
    // in the background they do not end up taking any rendering time.
    visible: false

    Kirigami.ColumnView.fillWidth: true
    Kirigami.ColumnView.reservedSpace: edit ? applicationWindow().pageStack.columnView.columnWidth : 0

    Binding {
        target: globalToolBarItem
        property: "enabled"
        value: contentLoader.status != Loader.Loading
    }

    Binding {
        target: flickable
        property: "interactive"
        value: false
    }

    Connections {
        target: page.Kirigami.PageStack.pageStack

        function onPageRemoved(removed) {
            if (page.edit && removed instanceof FaceConfigurationPage && page.Kirigami.PageStack.pageStack.depth == 1) {
                if (contentLoader.item.activeItem instanceof FaceControl) {
                    contentLoader.item.activeItem = null
                }
            }
        }
    }

    Connections {
        target: page.controller

        function onLoaded() {
            contentLoader.setSource(Qt.resolvedUrl("PageContents.qml"), {"controller": page.controller})
        }
    }

    Component.onCompleted: {
        contentLoader.setSource(Qt.resolvedUrl("PageContents.qml"), {"controller": page.controller})
    }

    readonly property real heightForContent: (parent?.height ?? 0) - topPadding - bottomPadding - (globalToolBarItem?.height ?? 0)

    readonly property var actionsFace: contentLoader.item && contentLoader.item.actionsFace ? contentLoader.item.actionsFace : null
    onActionsFaceChanged: Qt.callLater(updateActions)
    Connections {
        target: page.actionsFace
        function onActionsChanged() { Qt.callLater(page.updateActions) }
    }

    function updateActions() {
        actions = []

        if (!actionsFace || page.edit) {
            actions = defaultActions
            return
        }

        actions = actions.concat(page.actionsFace.actions).concat(defaultActions)
    }

    // Scroll the contents of the page based on the position of a rect (in scene
    // coordinates). If any part of the rect is above the visible area, contents
    // will be scrolled down. If any part of the rect is below the visible area,
    // contents will be scrolled up instead. This mimics dragging behaviour of
    // file managers and similar things.
    function scrollContents(rect) {
        let visibleRect = page.flickable.mapToItem(null, Qt.rect(page.flickable.x, page.flickable.y, page.flickable.width, page.flickable.height - page.bottomPadding))

        let minY = rect.y
        let maxY = rect.y + rect.height

        let visibleTop = visibleRect.y
        let visibleBottom = visibleRect.y + visibleRect.height

        if (minY >= visibleTop && maxY <= visibleBottom) {
            return
        }

        if (maxY > visibleBottom && !page.flickable.atYEnd) {
            page.flickable.contentY += (maxY - visibleBottom)
        } else if (minY < visibleTop && !page.flickable.atYBeginning) {
            page.flickable.contentY += (minY - visibleTop)
        }
        page.flickable.returnToBounds()
    }

    Kirigami.Action {
        id: editAction

        text: i18nc("@action", "Edit Page")
        icon.name: "document-edit"
        visible: !page.edit

        displayHint: page.actionsFace ? Kirigami.DisplayHint.AlwaysHide : Kirigami.DisplayHint.NoPreference

        onTriggered: page.edit = !page.edit
    }
    Kirigami.Action {
        id: saveAction
        text: i18nc("@action", "Save Changes")
        icon.name: "document-save"
        visible: page.edit
        onTriggered: {
            page.controller.save()
            page.edit = false
        }
    }
    Kirigami.Action {
        id: discardAction
        text: i18nc("@action", "Discard Changes")
        icon.name: "edit-delete-remove"
        visible: page.edit
        onTriggered: {
            page.controller.reset()
            page.edit = false
        }
    }
    Kirigami.Action {
        id: configureAction

        text: i18nc("@action", "Configure Page…")
        icon.name: "configure"
        visible: page.edit

        onTriggered: pageDialog.open()
    }
    Kirigami.Action {
        id: addRowAction

        text: i18nc("@action", "Add Row")
        icon.name: "edit-table-insert-row-under"
        visible: page.edit

        onTriggered: contentLoader.item.addRow(-1)
    }

    Kirigami.Action {
        id: addTitleAction
        text: i18nc("@action", "Add Title")
        icon.name: "insert-text-frame"
        visible: page.edit

        onTriggered: contentLoader.item.addTitle(-1)
    }

    readonly property var defaultActions: [editAction, saveAction, discardAction, addRowAction, addTitleAction, configureAction]

    data: [
        DialogLoader {
            id: pageDialog
            sourceComponent: PageDialog {
                title: i18nc("@title:window %1 is page title", "Configure Page \"%1\"", page.pageData.title)

                acceptText: i18nc("@action:button", "Save")
                acceptIcon: "document-save"

                onAboutToShow: {
                    name = page.pageData.title
                    iconName = page.pageData.icon
                    margin = page.pageData.margin
                    pageData = page.pageData
                    actionsFace = page.pageData.actionsFace ? page.pageData.actionsFace : ""
                    loadType = page.pageData.loadType ? page.pageData.loadType : "ondemand"
                }

                onAccepted: {
                    pageData.title = name
                    pageData.icon = iconName
                    pageData.margin = margin
                    pageData.actionsFace = actionsFace
                    pageData.loadType = loadType
                }
            }
        },
        DialogLoader {
            id: missingSensorsDialog

            sourceComponent: MissingSensorsDialog {
                missingSensors: contentLoader.item ? contentLoader.item.missingSensors : []

                onSensorReplacementChanged: {
                    contentLoader.item.replaceSensors(sensorReplacement)
                }
            }
        }
    ]

    Rectangle {
        id: loadOverlay

        z: 9999
        anchors.fill: parent
        // Make sure the overlay covers the parent and ignores its margins
        anchors.bottomMargin: -parent.anchors.bottomMargin
        anchors.topMargin: -parent.anchors.topMargin
        anchors.leftMargin: -parent.anchors.leftMargin
        anchors.rightMargin: -parent.anchors.rightMargin
        color: Kirigami.Theme.backgroundColor

        opacity: 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }

        BusyIndicator {
            anchors.centerIn: parent
            running: loadOverlay.visible
        }
    }

    Loader {
        id: contentLoader

        width: page.width
        height: item ? Math.max(item.Layout.minimumHeight, page.heightForContent) : page.heightForContent

        property real availableHeight: page.heightForContent

        asynchronous: true

        onStatusChanged: {
            if (status == Loader.Loading) {
                loadOverlay.opacity = 1
                visible = false
                if (!edit && applicationWindow().pageStack.columnView.containsItem(page)) {
                    // Pop any pages that might have been opened during editing
                    applicationWindow().pageStack.pop(page)
                }
            } else {
                Qt.callLater(updateActions)
                page.flickable.returnToBounds()
                visible = true
                loadOverlay.opacity = 0
            }
        }

        Connections {
            target: contentLoader.item

            function onShowMissingSensors() {
                missingSensorsDialog.open()
            }

            function onRowAdded() {
                page.flickable.flick(0, page.flickable.contentY - page.flickable.contentHeight * (page.flickable.flickDeceleration / 1250))
            }
        }
    }
}
