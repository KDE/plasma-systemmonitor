/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.4 as Kirigami

import org.kde.quickcharts 1.0 as Charts
import org.kde.quickcharts.controls 1.0 as ChartsControls
import org.kde.ksysguard.formatter 1.0 as Formatter

Kirigami.AbstractCard {
    id: card

    Layout.fillWidth: true
    Layout.preferredWidth: 0
    Layout.fillHeight: true
    Layout.preferredHeight: 0

    property alias chart: chart

    property alias colorSource: chart.colorSource
    property alias nameSource: chart.nameSource
    property alias valueSources: chart.valueSources

    property alias xRange: chart.xRange
    property alias yRange: chart.yRange

    property alias stacked: chart.stacked

    property alias axisLabels: axisLabels

    property var formatLabel: function(input) { return Formatter.Formatter.formatValueShowNull(input, card.unit) }
    property int unit

    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    contentItem: Item {
        Charts.GridLines {
            anchors.fill: chart
            direction: Charts.GridLines.Vertical

            major.visible: false

            minor.color: Kirigami.Theme.alternateBackgroundColor
            minor.count: 5
        }

        Charts.AxisLabels {
            id: axisLabels

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

            direction: Charts.AxisLabels.VerticalBottomTop
            alignment: Qt.AlignRight | Qt.AlignBottom
            constrainToBounds: true

            delegate: Label {
                text: card.formatLabel(Charts.AxisLabels.label);
                font: Kirigami.Theme.smallFont;
                opacity: 0.8
            }

            source: Charts.ChartAxisSource {
                chart: chart;
                axis: Charts.ChartAxisSource.YAxis;
                itemCount: 2
            }
        }

        Charts.LineChart {
            id: chart
            anchors {
                left: axisLabels.right
                leftMargin: Kirigami.Units.smallSpacing
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }

            xRange {
                automatic: false
                from: 0
                to: 100
            }
            yRange {
                automatic: true
                from: 0
                to: 100
            }

            fillOpacity: 1.0
            smooth: true
            stacked: false
            lineWidth: 1
            direction: Charts.XYChart.ZeroAtEnd

            colorSource: Charts.ColorGradientSource { baseColor: Kirigami.Theme.highlightColor; itemCount: chart.valueSources.length }
        }
    }
}
