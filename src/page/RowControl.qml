/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Container {
    id: control

    property PageDataObject rowData

    signal addTitle()
    signal addRow()

    implicitHeight: heading.height + topPadding + bottomPadding

    alwaysShowBackground: true

    contentItem: Row {
        anchors.fill: parent
        anchors.topMargin: control.topPadding
        anchors.leftMargin: control.leftPadding
        anchors.rightMargin: control.rightPadding
        anchors.bottomMargin: control.bottomPadding

        spacing: Kirigami.Units.largeSpacing

        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
        }

        Kirigami.Heading {
            id: heading
            width: parent.width
            text: control.rowData.title
            visible: control.rowData.isTitle && !control.active
            level: 2
        }

        TextField {
            width: parent.width
            text: control.rowData.title
            visible: control.rowData.isTitle && control.active
            onTextEdited: control.rowData.title = text
        }

        Repeater {
            id: repeater
            model: PageDataModel { data: control.rowData }

            ColumnControl {
                height: parent.height
                width: (parent.width - parent.spacing * (repeater.count - 1)) / repeater.count

                activeItem: control.activeItem
                single: control.rowData.children.length == 1
                columnData: model.data
                index: model.index

                onSelect: control.select(item)
                onRemove: control.rowData.removeChild(index)
                onMove: control.rowData.moveChild(from, to)
            }
        }
    }

    toolbar.addActions: [
        Kirigami.Action {
            text: i18nc("@action:button", "Add Column")
            onTriggered: control.addColumn(control.rowData.children.length)
        }
    ]
    toolbar.addVisible: !control.rowData.isTitle

    function addColumn(index) {
        control.rowData.insertChild(index, {"name": "column-" + index, showBackground: true})
    }

    Component.onCompleted: {
        if (rowData.children.length == 0 && !rowData.isTitle) {
            addColumn(0)
        }
    }
}
