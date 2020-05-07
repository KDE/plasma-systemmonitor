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

    actions.contextualActions: [
        Kirigami.Action {
            id: editAction
            text: i18n("Edit Page")
            icon.name: "document-edit"
            checkable: true
        },
        Kirigami.Action {
            text: i18n("Configure Page...")
            icon.name: "configure"
            visible: page.edit
            onTriggered: pageDialog.open()
        }
    ]

    Loader {
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
        }

        onAccepted: {
            pageData.title = name
            pageData.icon = iconName
            pageData.margin = margin
        }
    }
}
