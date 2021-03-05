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
import org.kde.quickcharts 1.0 as Charts

Control {
    id: delegate

    property string text: model.display != undefined ? model.display : ""
    property real maximum: 100
    property alias valueSources: chart.valueSources

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    property int _row: model.row
    property int _column: model.column

    background: CellBackground { view: delegate.TableView.view; row: _row; column: _column }


    contentItem: Item {
        anchors.fill: parent
        Charts.LineChart {
            id: chart
            anchors.fill: parent

            xRange {
                from: 0
                to: 10
                automatic: false
            }

            yRange {
                from: 0
                to: delegate.maximum
                automatic: delegate.maximum <= 0
            }

            direction: Charts.XYChart.ZeroAtEnd

            opacity: 0.5
            fillOpacity: 1
            lineWidth: 0

            colorSource: Charts.SingleValueSource { value: delegate.background.selected ? Kirigami.Theme.highlightedTextColor :  Kirigami.Theme.highlightColor }
        }

        Label {
            id: label

            anchors.centerIn: parent

            padding: Kirigami.Units.smallSpacing

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

