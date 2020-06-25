import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Column {
    id: root

    property PageDataObject pageData
    property Item activeItem
    property var actionsFace

    anchors.fill: parent

    spacing: Kirigami.Units.largeSpacing

    move: Transition {
        NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
    }

    function relayout() {
        let itemCount = repeater.count;
        let titlesHeight = 0;
        let titlesCount = 0;
        for (let i = 0; i < itemCount; ++i) {
            let item = repeater.itemAt(i)
            if (item && item.rowData.isTitle) {
                titlesHeight += item.height
                titlesCount += 1
            }
        }

        let rowHeight = (height - titlesHeight - (itemCount - 1) * root.spacing) / (itemCount - titlesCount)

        for (let i = 0; i < itemCount; ++i) {
            let item = repeater.itemAt(i)
            if (item && !item.rowData.isTitle) {
                item.height = rowHeight
            }
        }
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

            rowData: model.data

            activeItem: root.activeItem
            single: root.pageData.children.length == 1

            index: model.index

            onSelect: root.activeItem = item

            onAddTitle: pageData.insertChild(index + 1, {name: "row-" + (index + 1), isTitle: true, title: "New Title" })
            onAddRow: {
                var child = pageData.insertChild(index + 1, {name: "row-" + (index + 1), isTitle: false, title: ""})
                var column = child.insertChild(0, {"name": "column-0", showBackground: true})
                column.insertChild(0, {"name": "section-0", isSeparator: false})
            }
            onRemove: pageData.removeChild(index)
            onMove: pageData.moveChild(from, to)
        }
    }
}
