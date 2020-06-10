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

    readonly property real titlesHeight: {
        var height = 0;
        for (let i = 0; i < repeater.count; ++i) {
            let item = repeater.itemAt(i)
            if (item.rowData.isTitle) {
                height += item.height
            }
        }
        return height
    }

    function positionFor(index) {
        if (index < 0 || index >= repeater.count) {
            return -1
        }

        if (index == 0) {
            return 0
        }

        var position = 0
        var i = 0
        for (; i < index; ++i) {
            position = repeater.itemAt(i).y
        }
        position += repeater.itemAt(index - 1).height + spacing

        return position
    }

    Repeater {
        id: repeater
        model: PageDataModel { data: root.pageData }

        RowControl {
            width: parent.width
            height: {
                if (model.data.isTitle) {
                    return implicitHeight
                } else {
                    var titleCount = repeater.model.countObjects({isTitle: true})
                    return (parent.height - root.titlesHeight - (repeater.count - 1) * root.spacing) / (repeater.count - titleCount)
                }
            }

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
