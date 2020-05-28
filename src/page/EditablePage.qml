import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Kirigami.Page {
    id: page

    property PageDataObject pageData
    property alias edit: editAction.checked

    title: pageData.title

    leftPadding: pageData.margin * Kirigami.Units.largeSpacing
    rightPadding: pageData.margin * Kirigami.Units.largeSpacing
    topPadding: pageData.margin * Kirigami.Units.largeSpacing
    bottomPadding: pageData.margin * Kirigami.Units.largeSpacing

    Kirigami.ColumnView.fillWidth: true
    Kirigami.ColumnView.reservedSpace: edit ? applicationWindow().pageStack.columnView.columnWidth : 0

    readonly property var actionsFace: contentLoader.item ? contentLoader.item.actionsFace : null

    actions.main: page.actionsFace && page.actionsFace.primaryActions.length >= 1 ? page.actionsFace.primaryActions[0] : null
    actions.left: page.actionsFace && page.actionsFace.primaryActions.length >= 2 ? page.actionsFace.primaryActions[1] : null
    actions.right: page.actionsFace && page.actionsFace.primaryActions.length >= 3 ? page.actionsFace.primaryActions[2] : null

    actions.contextualActions: {
        var result = []
        if (page.actionsFace && page.actionsFace.secondaryActions.length > 0) {
            result = Array.prototype.map.call(page.actionsFace.secondaryActions, i => i)
            result.push(separator)
        }
        result.push(editAction)
        result.push(configureAction)
        return result
    }

    Kirigami.Action {
        id: separator
        separator: true
    }

    Kirigami.Action {
        id: editAction

        text: i18n("Edit Page")
        icon.name: "document-edit"
        checkable: true

        displayHint: page.actionsFace ? Kirigami.Action.DisplayHint.AlwaysHide : Kirigami.Action.DisplayHint.NoPreference
    }
    Kirigami.Action {
        id: configureAction

        text: i18n("Configure Page...")
        icon.name: "configure"
        visible: page.edit
        onTriggered: pageDialog.open()

        displayHint: page.actionsFace ? Kirigami.Action.DisplayHint.AlwaysHide : Kirigami.Action.DisplayHint.NoPreference
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        sourceComponent: page.edit ? pageEditor : pageContents
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
