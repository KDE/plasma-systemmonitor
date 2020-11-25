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
    property Page page

    implicitHeight: heading.height + topPadding + bottomPadding

    alwaysShowBackground: true

    function updateMinimumHeight() {
        if (rowData.isTitle) {
            minimumContentHeight = heading.implicitHeight
            minimumHeight = implicitHeight
            return
        }

        let minHeight = 0;
        let minContentHeight = 0;
        for (let i = 0; i < repeater.count; ++i) {
            let item = repeater.itemAt(i)
            if (item) {
                minContentHeight = Math.max(minContentHeight, item.minimumContentHeight)
                minHeight = Math.max(minHeight, item.minimumHeight)
            }
        }

        minimumContentHeight = minContentHeight
        minimumHeight = minHeight + control.topPadding + control.bottomPadding
    }

    onTopPaddingChanged: Qt.callLater(updateMinimumHeight)
    onBottomPaddingChanged: Qt.callLater(updateMinimumHeight)

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

            onItemAdded: Qt.callLater(control.updateMinimumHeight)
            onItemRemoved: Qt.callLater(control.updateMinimumHeight)

            ColumnControl {
                height: parent.height
                width: (parent.width - parent.spacing * (repeater.count - 1)) / repeater.count

                onMinimumContentHeightChanged: Qt.callLater(control.updateMinimumHeight)
                onMinimumHeightChanged: Qt.callLater(control.updateMinimumHeight)

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
            text: i18nc("@action", "Add Column")
            onTriggered: control.addColumn(control.rowData.children.length)
        }
    ]
    toolbar.addVisible: !control.rowData.isTitle
    toolbar.page: page

    function addColumn(index) {
        control.rowData.insertChild(index, {"name": "column-" + index, showBackground: true})
    }

    Component.onCompleted: {
        if (rowData.children.length == 0 && !rowData.isTitle) {
            addColumn(0)
        }
    }
}
