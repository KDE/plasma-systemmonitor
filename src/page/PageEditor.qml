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

    property Page parentPage
    property PageDataObject pageData
    property Item activeItem
    property var actionsFace

    spacing: rowSpacing // From parent loader

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
    }

    function relayout() {
        let reservedHeight = 0;
        let minimumHeight = 0;
        let balancedCount = 0;
        let maximumCount = 0;

        for (let i = 0; i < repeater.count; ++i) {
            let child = repeater.itemAt(i)
            if (!child || !child.hasOwnProperty("heightMode")) {
                // Apparently not a RowControl, ignore it.
                continue;
            }

            switch(child.heightMode) {
                case "minimum":
                    reservedHeight += child.minimumHeight
                    break;
                case "balanced":
                    minimumHeight = Math.max(child.minimumHeight, minimumHeight)
                    balancedCount += 1
                    break;
                case "maximum":
                    maximumCount += 1
                    break;
            }
        }

        let layoutHeight = availableHeight - reservedHeight - root.spacing * (repeater.count - 1)

        let balancedHeight = balancedCount > 0 ? layoutHeight / balancedCount : 0
        let maximumHeight = maximumCount > 0 ? (layoutHeight - minimumHeight * balancedCount) / maximumCount : 0

        let minimumTotalHeight = 0

        for (let i = 0; i < repeater.count; ++i) {
            let child = repeater.itemAt(i)
            if (!child || !child.hasOwnProperty("heightMode")) {
                continue;
            }

            minimumTotalHeight += root.spacing;

            switch (child.heightMode) {
                case "minimum":
                    child.height = child.minimumHeight
                    break
                case "balanced":
                    if (maximumCount > 0) {
                        child.height = child.minimumHeight
                    } else {
                        child.height = Math.max(minimumHeight, balancedHeight)
                    }
                    break
                case "maximum":
                    // The last "balanced" here is to make sure if the user
                    // selects "maximum" it is visually distinct from "balanced".
                    child.height = Math.max(child.minimumHeight, maximumHeight, balancedHeight * 1.25)
                    break
            }

            minimumTotalHeight += child.height
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
            onHeightModeChanged: Qt.callLater(root.relayout)

            rowData: model.data

            activeItem: root.activeItem
            single: root.pageData.children.length == 1

            index: model.index

            page: root.parentPage

            onSelect: root.activeItem = item

            onRemove: pageData.removeChild(index)
            onMove: pageData.moveChild(from, to)
        }
    }

    function addTitle(index) {
        if (index < 0) {
            index = pageData.children.length
        }

        pageData.insertChild(index, {
            name: "row-" + index,
            isTitle: true,
            title: i18n("New Title"),
            heightMode: "minimum"
        })
    }

    function addRow(index) {
        if (index < 0) {
            index = pageData.children.length
        }

        pageData.insertChild(index, {
            name: "row-" + index,
            isTitle: false,
            title: "",
            heightMode: "balanced"
        })
    }

    Component.onCompleted: {
        if (pageData.children.length == 0) {
            addRow(0)
        }
    }
}
