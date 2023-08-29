/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import org.kde.kirigami as Kirigami

BaseCellDelegate {
    id: delegate

    property string iconName
    property string text: model.display != undefined ? model.display : ""
    property real iconSize: Kirigami.Units.iconSizes.small
    property bool treeDecorationVisible: false

    leftPadding: Kirigami.Units.largeSpacing

    contentItem: RowLayout {
        id: row
        property Item treeDecoration
        Kirigami.Icon {
            Layout.preferredWidth: delegate.iconSize
            Layout.preferredHeight: Layout.preferredWidth
            source: delegate.iconName
            fallback: ""
            animated: false
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
    ToolTip.text: delegate.text
    ToolTip.delay: Kirigami.Units.toolTipDelay
    ToolTip.visible: delegate.hovered && label.truncated
}
