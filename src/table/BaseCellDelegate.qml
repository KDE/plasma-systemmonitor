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

Control
{
    id: root

    property int row: model.row
    property int column: model.column
    required property bool selected

    readonly property bool rowHovered: root.TableView.view.hoveredRow == row

    readonly property var __selection: TableView.view.selectionModel

    // Important: Don't remove this until QTBUG-84858 is resolved properly.
    Accessible.role: Accessible.Cell

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Kirigami.Theme.colorSet: selected ? Kirigami.Theme.Selection : Kirigami.Theme.View
    Kirigami.Theme.inherit: false

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

    hoverEnabled: true

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            root.TableView.view.hoveredRow = row
        }
        onExited: {
            root.TableView.view.hoveredRow = -1
        }

        onClicked: {
            var modelIndex = root.TableView.view.model.index(row, column);
            root.TableView.view.forceActiveFocus(Qt.ClickFocus)

            // latest clicks sets current index
            root.__selection.setCurrentIndex(modelIndex, ItemSelectionModel.Current | ItemSelectionModel.Rows)

            if (root.__selection.isSelected(modelIndex) && mouse.button == Qt.RightButton) {
                root.TableView.view.contextMenuRequested(modelIndex, mapToGlobal(mouse.x, mouse.y))
                return
            }

            if (mouse.modifiers & Qt.ShiftModifier) {
                //TODO: Implement range selection
                root.__selection.select(modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else if (mouse.modifiers & Qt.ControlModifier) {
                root.__selection.select(modelIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else {
                root.__selection.select(modelIndex, ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
            }

            if (mouse.button == Qt.RightButton) {
                root.TableView.view.contextMenuRequested(modelIndex, mapToGlobal(mouse.x, mouse.y))
            }
        }
    }
}
