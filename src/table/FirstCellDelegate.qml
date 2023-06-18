/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12

import org.kde.kirigami 2.2 as Kirigami

BaseCellDelegate {
    id: delegate

    property string iconName
    property string text: model.display != undefined ? model.display : ""
    property real iconSize: Kirigami.Units.iconSizes.small
    property bool treeDecorationVisible: false

    required property TreeView treeView 
    required property bool isTreeNode
    required property bool expanded
    required property bool hasChildren
    required property int depth

    leftPadding: Kirigami.Units.largeSpacing

    contentItem: RowLayout {
        id: row
        property Item treeDecoration
        Kirigami.Icon {
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
                    hasSiblings: Qt.binding(() => false ),//model.kDescendantHasSiblings),
                    level: Qt.binding(() => delegate.depth),
                    expandable: Qt.binding(() => delegate.hasChildren),
                    expanded: Qt.binding(() => delegate.expanded)
                })
                var finishCreation = () => {
                    row.treeDecoration = incubator.object
                    row.treeDecoration.clicked.connect(() => treeView.toggleExpanded(index))
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
    ToolTip.text: delegate.text
    ToolTip.delay: Kirigami.Units.toolTipDelay
    ToolTip.visible: delegate.hovered && label.truncated
}
