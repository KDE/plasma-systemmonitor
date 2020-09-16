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
    property real iconSize: Kirigami.Units.iconSizes.smallMedium

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View

    background: CellBackground { view: delegate.TableView.view; row: model.row; column: model.column }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing

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
