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

FocusScope {
    id: root

    property var model
    property alias delegate: tableView.delegate

    property alias headerModel: heading.sourceModel

    property alias sortColumn: heading.sortColumn
    property alias sortOrder: heading.sortOrder
    property alias sortName: heading.sortName
    property alias idRole: heading.idRole

    // Column widths in fractions of the entire view width
    // Since column sizes are relative to a given view width, the widths of individual
    // columns need to be expressed as a fraction of the entire width. columnWidths
    // and defaultColumnWidth both store these fractions. Note that minimumColumnWidth
    // is expressed as a pixel value since we do not want that to scale with view width.
    property var columnWidths: []
    property real defaultColumnWidth: 0.1
    property real minimumColumnWidth: Kirigami.Units.gridUnit * 4
    property real rowHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing * 2

    readonly property alias headerHeight: heading.height

    readonly property alias selection: tableView.selectionModel
    readonly property alias rows: tableView.rows
    readonly property alias columns: tableView.columns

    signal contextMenuRequested(var index, point position)
    signal headerContextMenuRequested(int column, point position)
    signal sort(int column, int order)

    Layout.minimumHeight: heading.height + root.rowHeight * 3

    clip: true

    function setColumnWidth(index, width) {
        if (index < 0 || index >= tableView.columns || width < minimumColumnWidth) {
            return
        }

        while (index >= columnWidths.length) {
            columnWidths.push(defaultColumnWidth)
        }

        columnWidths[index] = width / scrollView.innerWidth
        columnWidthsChanged();
    }

    onColumnWidthsChanged: tableView.forceLayout()

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    TableViewHeader {
        id: heading

        view: tableView

        width: scrollView.width
        onSort: root.sort(column, order)

        onResize: root.setColumnWidth(column, width)

        onContextMenuRequested: root.headerContextMenuRequested(column, position)

        Component.onCompleted: {
            Qt.callLater(root.sort, sortColumn, sortOrder)
        }
    }


    MouseArea {
        id: tableViewMouseArea
        z: 1000

        property Item delegateUnderMouse: null

        onDelegateUnderMouseChanged: function() {
            ToolTip.hide();

            if (delegateUnderMouse) {
                var currentIndex = tableView.model.index(delegateUnderMouse.background.row, delegateUnderMouse.background.column)
                tableView.selectionModel.setCurrentIndex(currentIndex, ItemSelectionModel.NoUpdate);
            } else {
                tableView.selectionModel.clearCurrentIndex()
            }

            if (delegateUnderMouse && delegateUnderMouse.truncated){
                tooltipTimer.restart()
            } else {
                tooltipTimer.stop()
            }
        }

        hoverEnabled: true

        // effectively anchors.fill: scrollView.contentItem
        // but Flickable cannot have multiple children
        x: scrollView.contentItem.x
        y: scrollView.contentItem.y + heading.height
        width: scrollView.contentItem.width
        height: scrollView.contentItem.height

        onExited: delegateUnderMouse = null

        onPositionChanged: function(mouse) {
            var viewportPos = tableView.contentItem.mapFromItem(tableViewMouseArea, mouse.x, mouse.y)
            delegateUnderMouse = tableView.contentItem.childAt(viewportPos.x, viewportPos.y)
        }

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: {
            var viewportPos = tableView.contentItem.mapFromItem(tableViewMouseArea, mouse.x, mouse.y)
            delegateUnderMouse = tableView.contentItem.childAt(viewportPos.x, viewportPos.y)

            if (!delegateUnderMouse) {
                return;
            }

            tableView.forceActiveFocus(Qt.MouseFocusReason)

            var currentIndex = tableView.model.index(delegateUnderMouse.background.row, delegateUnderMouse.background.column)

            if (tableView.selectionModel.isSelected(currentIndex) && mouse.button == Qt.RightButton) {
                tableView.contextMenuRequested(currentIndex, mapToGlobal(mouse.x, mouse.y))
                return;
            }

            if (mouse.modifiers & Qt.ShiftModifier) {
                //TODO: Implement range selection
                tableView.selectionModel.select(currentIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else if (mouse.modifiers & Qt.ControlModifier) {
                tableView.selectionModel.select(currentIndex, ItemSelectionModel.Toggle | ItemSelectionModel.Rows)
            } else {
                tableView.selectionModel.select(currentIndex, ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
            }

            if (mouse.button == Qt.RightButton) {
                tableView.contextMenuRequested(currentIndex, mapToGlobal(mouse.x, mouse.y))
            }
        }

        Timer {
            id: tooltipTimer
            interval: Kirigami.Units.toolTipDelay
            onTriggered: function() {
                var pos = tableViewMouseArea.delegateUnderMouse.mapToItem(tableView, 0, 0)
                tableViewMouseArea.ToolTip.toolTip.x = pos.x;
                tableViewMouseArea.ToolTip.toolTip.y = pos.y - tableViewMouseArea.delegateUnderMouse.height;
                tableViewMouseArea.ToolTip.show(tableViewMouseArea.delegateUnderMouse.text)
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.topMargin: heading.height

        property real innerWidth: LayoutMirroring.enabled ? width - leftPadding : width - rightPadding

        background: Rectangle { color: Kirigami.Theme.backgroundColor; Kirigami.Theme.colorSet: Kirigami.Theme.View }

        TableView {
            id: tableView
            anchors.left: parent.left
            property ItemSelectionModel selectionModel: ItemSelectionModel {
                id: selectionModel
                model: tableView.model
            }
            property int sortColumn: root.sortColumn
            signal contextMenuRequested(var index, point position)
            onContextMenuRequested: root.contextMenuRequested(index, position)

            onWidthChanged: forceLayout()

            // FIXME Until Tableview correctly reverses its columns, see QTBUG-90547
            model: root.model
            Binding on model {
                when: scrollView.LayoutMirroring.enabled
                value: Table.ReverseColumnsProxyModel {
                    sourceModel: root.model
                }
            }

            activeFocusOnTab: true

            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Keys.onPressed: {
                switch (event.key) {
                    case Qt.Key_Up:
                        selectRelative(-1)
                        if (!atYBeginning) {
                            contentY -= root.rowHeight
                            returnToBounds()
                        }
                        event.accepted = true
                        break
                    case Qt.Key_Down:
                        selectRelative(1)
                        if (!atYEnd) {
                            contentY += root.rowHeight
                            returnToBounds()
                        }
                        event.accepted = true
                        break
                    case Qt.Key_Menu:
                        contextMenuRequested(selectionModel.currentIndex, mapToGlobal(0, 0))
                    default:
                        break;
                }
            }

            onActiveFocusChanged: {
                if (activeFocus && !selectionModel.hasSelection) {
                    selectionModel.setCurrentIndex(model.index(0, 0), ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
                }
            }

            function selectRelative(delta) {
                var nextRow = selectionModel.currentIndex.row + delta
                if (nextRow < 0) {
                    nextRow = 0
                }
                if (nextRow >= rows) {
                    nextRow = rows - 1
                }
                var index = model.index(nextRow, selectionModel.currentIndex.column)
                selectionModel.setCurrentIndex(index, ItemSelectionModel.ClearAndSelect | ItemSelectionModel.Rows)
            }

            columnWidthProvider: function(index) {
                // FIXME Until Tableview correctly reverses its columns, see QTBUG-90547
                if (scrollView.LayoutMirroring.enabled) {
                    var width = root.columnWidths[root.columnWidths.length - index - 1]
                } else {
                    var width = root.columnWidths[index]
                }
                if (width === undefined || width === null) {
                    width = root.defaultColumnWidth
                } else {
                    width = width
                }
                width = Math.max(Math.floor(width * scrollView.innerWidth), root.minimumColumnWidth)
                return width
            }

            rowHeightProvider: (index) => root.rowHeight

            contentWidth: {
                var w = 0
                for (var i = 0; i < columns; i++) {
                    w += columnWidthProvider(i)
                }
                return Math.max(w, scrollView.innerWidth)
            }
            // FIXME: because of the delay populating the model, TableView seems to not calculate a proper contentHeight automatically
            contentHeight : root.rowHeight * rows
        }
    }
}

