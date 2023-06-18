/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.qqc2desktopstyle.private 1.0 as StylePrivate

RowLayout {
    id: root
    required property var hasSiblings
    required property int level
    property alias expandable : controlRoot.enabled
    required property bool expanded
    signal clicked
    Layout.topMargin: -delegate.topPadding
    Layout.bottomMargin: -delegate.bottomPadding
    readonly property siblings : {
        const index = model.index(row, column)
    }
    Repeater {
        model: root.level
        delegate: StylePrivate.StyleItem {
            Layout.preferredWidth: controlRoot.Layout.preferredWidth
            Layout.fillHeight: true
            visible: true
            control: controlRoot
            elementType: "itembranchindicator"
            properties: {
                "isItem": false,
                "hasSibling": true
            }
        }
    }
    Button {
        id: controlRoot
        Layout.preferredWidth: background.pixelMetric("treeviewindentation")
        visible: true
        Layout.fillHeight: true
        text: root.expanded ? "-" : "+"
        onClicked: root.clicked()
        background: StylePrivate.StyleItem {
            id: styleitem
            control: controlRoot
            hover: controlRoot.hovered
            elementType: "itembranchindicator"
            on: root.expanded
            properties: {
                "isItem": true,
                "hasChildren": root.expandable,
                "hasSibling": root.hasSiblings[root.hasSiblings.length - 1]
            }
        }
    }
}
