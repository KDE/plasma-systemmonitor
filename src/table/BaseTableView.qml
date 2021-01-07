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

FocusScope {
    id: root

    property alias model: tableView.model
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

        width: tableView.contentWidth + scrollView.rightPadding

        onSort: root.sort(column, order)

        onResize: root.setColumnWidth(column, width)

        onContextMenuRequested: root.headerContextMenuRequested(column, position)

        Component.onCompleted: {
            Qt.callLater(root.sort, sortColumn, sortOrder)
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.topMargin: heading.height

        property real innerWidth: width - rightPadding

        background: Rectangle { color: Kirigami.Theme.backgroundColor; Kirigami.Theme.colorSet: Kirigami.Theme.View }

        TableView {
            id: tableView

            property ItemSelectionModel selectionModel: ItemSelectionModel {
                id: selectionModel
                model: tableView.model
            }
            property int sortColumn: root.sortColumn
            signal contextMenuRequested(var index, point position)
            onContextMenuRequested: root.contextMenuRequested(index, position)

            onWidthChanged: forceLayout()

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
                var width = root.columnWidths[index]
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

