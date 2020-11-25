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

Column {
    id: root

    property PageDataObject pageData
    property Item activeItem
    property var actionsFace

    spacing: Kirigami.Units.largeSpacing

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
    }

    function relayout() {
        let itemCount = repeater.count;
        let titlesHeight = 0;
        let titlesCount = 0;
        let minimumContentHeight = 0;
        let minimumHeight = 0;

        for (let i = 0; i < itemCount; ++i) {
            let item = repeater.itemAt(i)
            if (item) {
                if (item.rowData.isTitle) {
                    titlesHeight += item.height
                    titlesCount += 1
                } else {
                    minimumContentHeight = Math.max(minimumContentHeight, item.minimumContentHeight)
                    minimumHeight = Math.max(minimumHeight, item.minimumHeight)
                }
            }
        }

        let rowHeight = (height - titlesHeight - (itemCount - 1) * root.spacing) / (itemCount - titlesCount)

        let minimumTotalHeight = 0;

        for (let i = 0; i < itemCount; ++i) {
            let item = repeater.itemAt(i)
            if (item) {
                minimumTotalHeight += root.spacing
                if (item.rowData.isTitle) {
                    minimumTotalHeight += item.height
                } else {
                    let correctedMinimumHeight = Math.max(item.minimumHeight, (item.minimumHeight - item.minimumContentHeight) + minimumContentHeight)
                    item.height = Math.max(rowHeight, correctedMinimumHeight)
                    minimumTotalHeight += correctedMinimumHeight
                }
            }
        }

        Layout.minimumHeight = minimumTotalHeight
    }

    onWidthChanged: Qt.callLater(relayout)
    onHeightChanged: Qt.callLater(relayout)

    Repeater {
        id: repeater
        model: PageDataModel { data: root.pageData }

        onItemAdded: Qt.callLater(root.relayout)
        onItemRemoved: Qt.callLater(root.relayout)

        RowControl {
            width: parent.width

            onHeightChanged: Qt.callLater(root.relayout)
            onMinimumContentHeightChanged: Qt.callLater(root.relayout)
            onMinimumHeightChanged: Qt.callLater(root.relayout)

            rowData: model.data

            activeItem: root.activeItem
            single: root.pageData.children.length == 1

            index: model.index

            onSelect: root.activeItem = item

            onRemove: pageData.removeChild(index)
            onMove: pageData.moveChild(from, to)
        }
    }

    function addTitle(index) {
        if (index < 0) {
            index = pageData.children.length
        }

        pageData.insertChild(index, {name: "row-" + index, isTitle: true, title: i18n("New Title") })
    }

    function addRow(index) {
        if (index < 0) {
            index = pageData.children.length
        }

        pageData.insertChild(index, {name: "row-" + index, isTitle: false, title: ""})
    }

    Component.onCompleted: {
        if (pageData.children.length == 0) {
            addRow(0)
        }
    }
}
