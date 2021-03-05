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

Control {
    id: delegate

    property string iconName
    property string text: model.display != undefined ? model.display : ""
    property alias truncated: label.truncated
    property real iconSize: Kirigami.Units.iconSizes.small
    property bool treeDecorationVisible: false

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    topPadding: 0
    bottomPadding: 0
    rightPadding: 0
    leftPadding: Kirigami.Units.largeSpacing

    background: CellBackground { view: delegate.TableView.view; row: model.row; column: model.column }

    contentItem: RowLayout {
        id: row
        property Item treeDecoration
        Kirigami.Icon {
            id:blah
            Layout.preferredWidth: delegate.iconName != "" ? delegate.iconSize : 0
            Layout.preferredHeight: Layout.preferredWidth
            source: delegate.iconName
            fallback: ""
        }
        Label {
            id: label

            padding: Kirigami.Units.smallSpacing

            Layout.fillWidth: true
            Layout.fillHeight: true
            text: delegate.text
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    hoverEnabled: true

    onTreeDecorationVisibleChanged: {
        if (treeDecorationVisible) {
            var component = Qt.createComponent("TreeDecoration.qml")
            if (component.status == Component.Ready) {
                var incubator = component.incubateObject(null, {
                    hasSiblings: Qt.binding(() => model.kDescendantHasSiblings),
                    level: Qt.binding(() => model.kDescendantLevel),
                    expandable: Qt.binding(() => model.kDescendantExpandable),
                    expanded: Qt.binding(() => model.kDescendantExpanded)
                })
                var finishCreation = () => {
                    row.treeDecoration = incubator.object
                    row.treeDecoration.clicked.connect(() => descendantsModel.toggleChildren(index))
                    var children = Array.from(row.children)
                    children.unshift(row.treeDecoration)
                    row.children = children
                }
                if (incubator.status == Component.Ready) {
                    finishCreation()
                } else {
                    incubator.onStatusChanged = (status) => {
                        if (status == Component.Ready) {
                            finishCreation()
                        }
                    }
                }
            }
        } else {
            if (row.treeDecoration) {
                row.treeDecoration.destroy()
            }
        }
    }
}
