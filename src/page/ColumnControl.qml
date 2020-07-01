import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Container {
    id: control

    property PageDataObject columnData

    signal addColumn()
    signal remove()
    signal move(int from, int to)

    readonly property real separatorsWidth: {
        var width = 0;
        for (let i = 0; i < repeater.count; ++i) {
            let item = repeater.itemAt(i)
            if (item.sectionData.isSeparator) {
                width += item.width
            }
        }
        return width
    }

    Kirigami.AbstractCard {
        parent: control.background
        anchors.fill: parent
        visible: control.columnData.showBackground
        showClickFeedback: true
        onClicked: control.select(control)
    }

    contentItem: Row {
        anchors.fill: parent
        anchors.topMargin: control.topPadding
        anchors.bottomMargin: control.bottomPadding
        anchors.leftMargin: control.leftPadding
        anchors.rightMargin: control.rightPadding

        spacing: Kirigami.Units.largeSpacing

        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
        }

        Repeater {
            id: repeater
            model: PageDataModel { data: control.columnData }

            SectionControl {
                height: parent.height
                width: {
                    if (model.data.isSeparator) {
                        return implicitWidth
                    } else {
                        var sectionCount = repeater.count - repeater.model.countObjects({isSeparator: true})
                        return (parent.width - control.separatorsWidth - (repeater.count - 1) * parent.spacing) / sectionCount
                    }
                }

                activeItem: control.activeItem
                single: control.columnData.children.length == 1
                sectionData: model.data
                index: model.index

                onSelect: control.select(item)
                onAddSection: control.columnData.insertChild(index + 1, {name: "section-" + (index + 1), isSeparator: false})
                onAddSeparator: control.columnData.insertChild(index + 1, {name: "section-" + (index + 1), isSeparator: true})
                onRemove: control.columnData.removeChild(index)
                onMove: control.columnData.moveChild(from, to)
            }
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add"
            text: i18n("Add")

            Kirigami.Action {
                text: i18n("Add Column")
                onTriggered: control.addColumn()
            }
        },
        MoveAction { target: control; axis: Qt.XAxis; onMove: control.move(from, to) },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Remove")
            enabled: !control.single
            onTriggered: control.remove()
        },
        Kirigami.Action {
            icon.name: "view-visible"
            text: i18n("Show Background")
            checkable: true
            checked: control.columnData.showBackground
            onTriggered: control.columnData.showBackground = !control.columnData.showBackground
        }
    ]
}
