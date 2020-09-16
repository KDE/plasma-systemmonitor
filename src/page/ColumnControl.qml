/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Container {
    id: control

    property PageDataObject columnData

    signal addColumn()

    Kirigami.AbstractCard {
        parent: control.background
        anchors.fill: parent
        visible: control.columnData.showBackground
        showClickFeedback: true
        onClicked: control.select(control)
    }

    contentItem: Row {
        id: row

        anchors.fill: parent
        anchors.topMargin: control.topPadding
        anchors.bottomMargin: control.bottomPadding
        anchors.leftMargin: control.leftPadding
        anchors.rightMargin: control.rightPadding

        spacing: Kirigami.Units.largeSpacing

        move: Transition {
            NumberAnimation { properties: "x,y"; duration: Kirigami.Units.shortDuration }
        }

        function relayout() {
            let itemCount = repeater.count;
            let separatorsWidth = 0;
            let separatorsCount = 0;
            for (let i = 0; i < itemCount; ++i) {
                let item = repeater.itemAt(i)
                if (item && item.sectionData.isSeparator) {
                    separatorsWidth += item.width
                    separatorsCount += 1
                }
            }

            let sectionWidth = (row.width - separatorsWidth - (itemCount - 1) * spacing) / (itemCount - separatorsCount)

            for (let i = 0; i < itemCount; ++i) {
                let item = repeater.itemAt(i)
                if (item && !item.sectionData.isSeparator) {
                    item.width = sectionWidth
                }
            }
        }

        onWidthChanged: Qt.callLater(relayout)
        onHeightChanged: Qt.callLater(relayout)

        Repeater {
            id: repeater
            model: PageDataModel { data: control.columnData }

            onItemAdded: Qt.callLater(row.relayout)
            onItemRemoved: Qt.callLater(row.relayout)

            SectionControl {
                height: parent.height
                onWidthChanged: Qt.callLater(row.relayout)

                activeItem: control.activeItem
                single: control.columnData.children.length == 1
                sectionData: model.data
                index: model.index

                onSelect: control.select(item)
                onAddSection: control.addSection(index + 1)
                onAddSeparator: control.addSeparator(index + 1)
                onRemove: control.columnData.removeChild(index)
                onMove: control.columnData.moveChild(from, to)
            }
        }
    }

    toolbar.addActions: [
        Action {
            text: i18nc("@action:button", "Add Section")
            onTriggered: addSection(control.columnData.children.length)
        },
        Action {
            text: i18nc("@action:button", "Add Separator")
            onTriggered: addSeparator(control.columnData.children.length)
        }
    ]
    toolbar.moveAxis: Qt.XAxis

    toolbar.extraActions: Action {
        icon.name: "view-visible"
        text: i18n("Show Background")
        checkable: true
        checked: control.columnData.showBackground
        onTriggered: control.columnData.showBackground = !control.columnData.showBackground
    }

    function addSection(index) {
        control.columnData.insertChild(index, {name: "section-" + index, isSeparator: false})
    }

    function addSeparator(index) {
        control.columnData.insertChild(index, {name: "section-" + index, isSeparator: true})
    }

    Component.onCompleted: {
        if (columnData.children.length == 0) {
            addSection(0)
        }
    }
}
