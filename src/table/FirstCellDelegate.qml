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
import org.kde.qqc2desktopstyle.private 1.0 as StylePrivate

Control {
    id: delegate

    property string iconName
    property string text: model.display != undefined ? model.display : ""
    property real iconSize: Kirigami.Units.iconSizes.small
    property alias treeDecorationVisible: treeDecoration.visible

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View

    background: CellBackground { view: delegate.TableView.view; row: model.row; column: model.column }

    contentItem: RowLayout {
        RowLayout {
            id: treeDecoration
            Layout.topMargin: -delegate.topPadding
            Layout.bottomMargin: -delegate.bottomPadding
            Repeater {
                model: kDescendantLevel-1
                delegate: StylePrivate.StyleItem {
                    Layout.preferredWidth: controlRoot.width//Kirigami.Units.gridUnit
                    Layout.fillHeight: true
                    visible: true
                    control: controlRoot
                    elementType: "itembranchindicator"
                    properties: {
                        "isItem": false,
                        "hasSibling": kDescendantHasSiblings[modelData]
                    }
                }
            }
            Button {
                id: controlRoot
                Layout.preferredWidth: background.pixelMetric("treeviewindentation")
                visible: true
                Layout.fillHeight: true
                enabled: model.kDescendantExpandable
                text: model.kDescendantExpanded ? "-" : "+"
                onClicked: descendantsModel.toggleChildren(index)
                background: StylePrivate.StyleItem {
                    id: styleitem
                    control: controlRoot
                    hover: controlRoot.hovered
                    elementType: "itembranchindicator"
                    on: model.kDescendantExpanded
                    properties: {
                        "isItem": true,
                        "hasChildren": model.kDescendantExpandable,
                        "hasSibling": model.kDescendantHasSiblings[model.kDescendantHasSiblings.length - 1]
                    }
                }
            }
        }

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
    ToolTip.text: delegate.text
    ToolTip.delay: Kirigami.Units.toolTipDelay
    ToolTip.visible: delegate.hovered && label.truncated
}
