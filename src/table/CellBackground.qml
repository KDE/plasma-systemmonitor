/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12

import org.kde.kirigami 2.2 as Kirigami

Rectangle {
    id: root

    property var view
    property int row
    property int column
    property bool selected: false

    property var __selection: view.selectionModel

    color: (row % 2 == 0) ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

    // We need to update:
    // if the selected indexes changes
    // if our delegate moves
    // if the model moves and the delegate stays in the same place
    function updateIsSelected() {
        selected = __selection.isSelected(view.model.index(row, column))
    }

    Connections {
        target: __selection
        function onSelectionChanged() {
            updateIsSelected();
        }
    }

    onRowChanged: updateIsSelected();

    Connections {
        target: view.model
        function onLayoutChanged() {
            updateIsSelected();
        }
    }

    Component.onCompleted: {
        updateIsSelected();
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Selection
        opacity: selected ? 1 : (root.__selection.currentIndex.row == root.row ? 0.3 : 0)
    }
}
