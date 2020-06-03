import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQml.Models 2.12

import org.kde.kirigami 2.2 as Kirigami

FocusScope {
    id: root

    property alias model: tableView.model
    property alias delegate: tableView.delegate

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

        onSort: {
            if (tableView.model) {
                var model = tableView.model
                if (model.hasOwnProperty("sort")) {
                    model.sort(sortColumn, sortOrder)
                } else if (model.hasOwnProperty("sortColumn")) {
                    model.sortColumn = sortColumn
                    model.sortOrder = sortOrder
                }
            }
        }

        onResize: root.setColumnWidth(column, width)

        onContextMenuRequested: root.headerContextMenuRequested(column, position)

        Component.onCompleted: {
            if (tableView.model && "sort" in tableView.model) {
                Qt.callLater(tableView.model.sort, sortColumn, sortOrder);
            }
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

            clip: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds

            columnWidthProvider: function(index) {
                var width = root.columnWidths[index]
                if (width === undefined || width === null) {
                    width = root.defaultColumnWidth
                } else {
                    width = width
                }

                width = Math.max(width * scrollView.innerWidth, root.minimumColumnWidth)
                return width
            }

            rowHeightProvider: (index) => root.rowHeight

            contentWidth: {
                var w = 0
                for (var i = 0; i < columns; i++) {
                    w += columnWidthProvider(i)
                }
                return Math.max(w, width)
            }
        }
    }
}

