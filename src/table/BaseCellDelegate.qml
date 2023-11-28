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

    readonly property var __selection: TableView.view.selectionModel

    // Important: Don't remove this until QTBUG-84858 is resolved properly.
    Accessible.role: Accessible.Cell

    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

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
            root.TableView.view.hoveredRow = root.row
        }
    }

    hoverEnabled: true

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: (eventPoint, button) => {
            var modelIndex = root.TableView.view.model.index(row, column);

            root.TableView.view.forceActiveFocus(Qt.ClickFocus)

            // latest clicks sets current index
            root.__selection.setCurrentIndex(modelIndex, ItemSelectionModel.Current | ItemSelectionModel.Rows)

            if (root.__selection.isSelected(modelIndex) && button == Qt.RightButton) {
                root.TableView.view.contextMenuRequested(modelIndex, eventPoint.globalPressPosition)
                return
            }

            if (point.modifiers & Qt.ShiftModifier) {
                //TODO: Implement range selection
                root.__selection.select(modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else if (point.modifiers & Qt.ControlModifier) {
                root.__selection.select(modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else {
                root.__selection.select(modelIndex, ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
            }

            if (button == Qt.RightButton) {
                root.TableView.view.contextMenuRequested(modelIndex, eventPoint.globalPressPosition)
            }
        }
    }
}
