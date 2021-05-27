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
import org.kde.ksysguard.table 1.0 as Table

Control
{
    id: root

    property int row: model.row
    property int column: model.column
    property bool selected: false

    readonly property bool rowHovered: root.__selection.currentIndex.row == row
    readonly property var __selection: TableView.view.selectionModel

    // We need to update:
    // if the selected indexes changes
    // if our delegate moves
    // if the model moves and the delegate stays in the same place
    function updateIsSelected() {
        selected = __selection.rowIntersectsSelection(row)
    }

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Connections {
        target: __selection
        function onSelectionChanged() {
            updateIsSelected();
        }
    }

    onRowChanged: updateIsSelected();

    Connections {
        target: root.TableView.view.model
        function onLayoutChanged() {
            updateIsSelected();
        }
    }

    Component.onCompleted: {
        updateIsSelected();
    }

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
            var modelIndex = root.TableView.view.model.index(row, column);
            root.__selection.setCurrentIndex(modelIndex, ItemSelectionModel.NoUpdate)
        }
        onExited: Qt.callLater(maybeClearCurrent)

        onClicked: {
            var modelIndex = root.TableView.view.model.index(row, column);
            root.TableView.view.forceActiveFocus(Qt.ClickFocus)
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

        function maybeClearCurrent() {
            var modelIndex = root.TableView.view.model.index(row, column);

            // We (ab)use currentIndex to indicate the currently hovered row. This means
            // we shouldn't just clear the current index when the mouse leaves this item
            // since it may just be hovering a different table cell. However, if the mouse
            // exited but the currentIndex is still the current cell, then we can be fairly
            // sure the mouse is no longer over a table cell and we can safely clear the
            // current index.
            if (__selection.currentIndex == modelIndex) {
                __selection.clearCurrentIndex()
            }
        }
    }
}
