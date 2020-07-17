import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Kirigami.Page {
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

    readonly property var actionsFace: contentLoader.item && contentLoader.item.actionsFace ? contentLoader.item.actionsFace : null
    onActionsFaceChanged: updateActions()
    Connections {
        target: page.actionsFace
        function onPrimaryActionsChanged() { page.updateActions() }
        function onSecondaryActionsChanged() { page.updateActions() }
    }

    function updateActions() {
        if (!actionsFace || page.edit) {
            actions.contextualActions = defaultActions
            return
        }

        let primary = page.actionsFace.primaryActions
        let secondary = page.actionsFace.secondaryActions

        if (primary.length == 0 && secondary.length == 0) {
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
            contextual.concat(Array.prototype.map.call(secondary, i => i))
            contextual.push(separator)
        }

        contextual.concat(defaultActions)

        actions.contextualActions = contextual
    }

    Kirigami.Action {
        id: separator
        separator: true
    }

    Kirigami.Action {
        id: editAction

        text: i18n("Edit Page")
        icon.name: "document-edit"

        displayHint: page.actionsFace ? Kirigami.Action.DisplayHint.AlwaysHide : Kirigami.Action.DisplayHint.NoPreference

        onTriggered: page.edit = !page.edit
    }
    Kirigami.Action {
        id: configureAction

        text: i18n("Configure Page...")
        icon.name: "configure"
        visible: page.edit

        onTriggered: pageDialog.open()
    }
    Kirigami.Action {
        id: addRowAction

        text: i18n("Add Row")
        icon.name: "edit-table-insert-row-under"
        visible: page.edit

        onTriggered: contentLoader.item.addRow(-1)
    }

    Kirigami.Action {
        id: addTitleAction
        text: i18n("Add Title")
        icon.name: "insert-text-frame"
        visible: page.edit

        onTriggered: contentLoader.item.addTitle(-1)
    }

    readonly property var defaultActions: [editAction, addRowAction, addTitleAction, configureAction]
    onEditChanged: updateActions()

    Loader {
        id: contentLoader
        anchors.fill: parent
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
                updateActions()
                loadOverlay.opacity = 0
            }
        }
    }

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

    Rectangle {
        id: loadOverlay

        anchors.fill: parent
        anchors.margins: -pageData.margin * Kirigami.Units.largeSpacing
        color: Kirigami.Theme.backgroundColor

        opacity: 1
        Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.shortDuration } }

        BusyIndicator {
            anchors.centerIn: parent
            running: loadOverlay.visible
        }
    }

    PageDialog {
        id: pageDialog
        title: i18n("Configure Page \"%1\"", pageData.title)

        acceptText: i18n("Save")
        acceptIcon: "document-save"

        onAboutToShow: {
            name = pageData.title
            iconName = pageData.icon
            margin = pageData.margin
            actionsFace = pageData.actionsFace
        }

        onAccepted: {
            pageData.title = name
            pageData.icon = iconName
            pageData.margin = margin
            pageData.actionsFace = actionsFace
        }
    }
}
