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

    readonly property bool rowHovered: root.TableView.view.hoveredRow == row

    text: model.display

    // Important: Don't remove this until QTBUG-84858 is resolved properly.
    Accessible.role: Accessible.Cell

    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    background: Item { }

    onHoveredChanged: {
        if (hovered) {
            root.TableView.view.hoveredRow = root.row
        }
    }

    hoverEnabled: true
}
