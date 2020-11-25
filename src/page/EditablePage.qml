/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Kirigami.ScrollablePage {
    id: page

    property PageDataObject pageData
    property bool edit: false

    title: pageData.title

    leftPadding: pageData.margin * Kirigami.Units.largeSpacing
    rightPadding: pageData.margin * Kirigami.Units.largeSpacing
    topPadding: pageData.margin * Kirigami.Units.largeSpacing
    bottomPadding: pageData.margin * Kirigami.Units.largeSpacing

    Kirigami.ColumnView.fillWidth: true
    Kirigami.ColumnView.reservedSpace: edit ? applicationWindow().pageStack.columnView.columnWidth : 0

    Binding {
        target: globalToolBarItem
        property: "enabled"
        value: contentLoader.status != Loader.Loading
    }

    readonly property real heightForContent: height - topPadding - bottomPadding - globalToolBarItem.height

    readonly property var actionsFace: contentLoader.item && contentLoader.item.actionsFace ? contentLoader.item.actionsFace : null
    onActionsFaceChanged: Qt.callLater(updateActions)
    Connections {
        target: page.actionsFace
        function onPrimaryActionsChanged() { Qt.callLater(page.updateActions) }
        function onSecondaryActionsChanged() { Qt.callLater(page.updateActions) }
    }

    function updateActions() {
        actions.main = null
        actions.left = null
        actions.right = null

        if (!actionsFace || page.edit) {
            actions.contextualActions = defaultActions
            return
        }

        let primary = page.actionsFace.primaryActions
        let secondary = page.actionsFace.secondaryActions

        if (primary.length == 0 && secondary.length == 0) {
            if (actions.contextualActions == defaultActions) {
                return;
            }

            actions.contextualActions = defaultActions
            return
        }

        if (primary.length >= 1) {
            actions.main = primary[0]
        }

        if (primary.length >= 2) {
            actions.left = primary[1]
        }

        if (primary.length >= 3) {
            actions.right = primary[2]
        }

        let contextual = []

        if (primary.length >= 4) {
            contextual = Array.prototype.map.call(primary, i => i).slice(4)
        }

        if (secondary.length > 0) {
            contextual = contextual.concat(Array.prototype.map.call(secondary, i => i))
        }

        actions.contextualActions = contextual.concat(defaultActions)
    }

    Kirigami.Action {
        id: editAction

        text: i18nc("@action", "Edit Page")
        icon.name: "document-edit"
        visible: !page.edit

        displayHint: page.actionsFace ? Kirigami.Action.DisplayHint.AlwaysHide : Kirigami.Action.DisplayHint.NoPreference

        onTriggered: page.edit = !page.edit
    }
    Kirigami.Action {
        id: saveAction
        text: i18nc("@action", "Save Changes")
        icon.name: "document-save"
        visible: page.edit
        onTriggered: {
            page.edit = false
            page.pageData.savePage()
        }
    }
    Kirigami.Action {
        id: discardAction
        text: i18nc("@action", "Discard Changes")
        icon.name: "edit-delete-remove"
        visible: page.edit
        onTriggered: {
            page.edit = false
            page.pageData.resetPage()
        }
    }
    Kirigami.Action {
        id: configureAction

        text: i18nc("@action", "Configure Page...")
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

    Component {
        id: pageEditor

        PageEditor {
            pageData: page.pageData
        }
    }

    Component {
        id: pageContents

        PageContents {
            pageData: page.pageData
        }
    }

    PageDialog {
        id: pageDialog
        title: i18nc("@title:window %1 is page title", "Configure Page \"%1\"", page.pageData.title)

        acceptText: i18nc("@action:button", "Save")
        acceptIcon: "document-save"

        onAboutToShow: {
            name = page.pageData.title
            iconName = page.pageData.icon
            margin = page.pageData.margin
            pageData = page.pageData
            actionsFace = page.pageData.actionsFace ? page.pageData.actionsFace : ""
        }

        onAccepted: {
            pageData.title = name
            pageData.icon = iconName
            pageData.margin = margin
            pageData.actionsFace = actionsFace
        }
    }

    Rectangle {
        id: loadOverlay

        parent: page.overlay
        anchors.fill: parent
        anchors.margins: -pageData.margin * Kirigami.Units.largeSpacing
        color: Kirigami.Theme.backgroundColor

        opacity: 1
        visible: opacity > 0
        Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.shortDuration } }

        BusyIndicator {
            anchors.centerIn: parent
            running: loadOverlay.visible
        }
    }

    Loader {
        id: contentLoader

        width: page.width
        height: item ? Math.max(item.Layout.minimumHeight, page.heightForContent) : page.heightForContent

        onHeightChanged: print("loader height", height)

        sourceComponent: page.edit ? pageEditor : pageContents
        asynchronous: true

        onStatusChanged: {
            if (status == Loader.Loading) {
                loadOverlay.opacity = 1
                if (!edit) {
                    // Pop any pages that might have been opened during editing
                    applicationWindow().pageStack.pop(page)
                }
            } else {
                Qt.callLater(updateActions)
                page.flickable.returnToBounds()
                loadOverlay.opacity = 0
            }
        }
    }
}
