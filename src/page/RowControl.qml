import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Container {
    id: control

    property PageDataObject rowData

    signal addTitle()
    signal addRow()
    signal remove()
    signal move(int from, int to)

    implicitHeight: heading.height + topPadding + bottomPadding

    Row {
        anchors.fill: parent
        anchors.topMargin: control.topPadding
        anchors.leftMargin: control.leftPadding
        anchors.rightMargin: control.rightPadding
        anchors.bottomMargin: control.bottomPadding

        spacing: Kirigami.Units.largeSpacing

        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
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
                position += repeater.itemAt(i).x
            }
            position += repeater.itemAt(index - 1).width + spacing

            return position
        }

        Kirigami.Heading {
            id: heading
            width: parent.width
            text: control.rowData.title
            visible: control.rowData.isTitle && !control.active
            level: 2
        }

        TextField {
            width: parent.width
            text: control.rowData.title
            visible: control.rowData.isTitle && control.active
            onTextEdited: control.rowData.title = text
        }

        Repeater {
            id: repeater
            model: PageDataModel { data: control.rowData }

            ColumnControl {
                height: parent.height
                width: (parent.width - parent.spacing * (repeater.count - 1)) / repeater.count

                activeItem: control.activeItem
                single: control.rowData.children.length == 1
                columnData: model.data
                index: model.index

                onSelect: control.select(item)
                onAddColumn: {
                    var column = control.rowData.insertChild(index + 1, {"name": "column-" + (index + 1), showBackground: true})
                    column.insertChild(0, {"name": "section-0", isSeparator: false})
                }
                onRemove: control.rowData.removeChild(index)
                onMove: control.rowData.moveChild(from, to)
            }
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Add")

            Kirigami.Action {
                text: i18n("Add Title")
                onTriggered: control.addTitle()
            }
            Kirigami.Action {
                text: i18n("Add Row")
                onTriggered: control.addRow()
            }
        },
        MoveAction {
            target: control
            onMove: control.move(from, to)
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Remove")
            enabled: !control.single
            onTriggered: control.remove()
        }
    ]
}
