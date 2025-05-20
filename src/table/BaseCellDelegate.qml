/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import org.kde.kirigami as Kirigami
import org.kde.ksysguard.table as Table

TreeViewDelegate
{
    id: root

    readonly property bool rowHovered: treeView.hoveredRow == row
    Kirigami.Theme.colorSet: selected ? Kirigami.Theme.Selection : Kirigami.Theme.View
    text: model.display

    // Important: Don't remove this until QTBUG-84858 is resolved properly.
    Accessible.role: Accessible.Cell

    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    leftInset: 0
    bottomInset: 0
    rightInset: 0
    topInset: 0

    background: Rectangle {
        color: (row % 2 == 0 || selected) ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

        Rectangle {
            anchors.fill: parent
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Selection
            color: Kirigami.Theme.backgroundColor
            opacity: 0.3
            visible: root.rowHovered
        }
    }

    onHoveredChanged: {
        if (hovered) {
            treeView.hoveredRow = row
        }
    }

    hoverEnabled: true
}
