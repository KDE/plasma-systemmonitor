/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

import org.kde.ksysguard.formatter as Formatter

Kirigami.Padding {
    id: card

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 0
    Layout.preferredHeight: 0
    Layout.minimumHeight: Kirigami.Theme.smallFont.pixelSize * 2
    Layout.verticalStretchFactor: 1

    property string title

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

    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    TextMetrics {
        id: axisMetrics
        font: Kirigami.Theme.smallFont
        text: Formatter.Formatter.formatValueShowNull("0", card.unit)
    }

    contentItem: Item {
        ChartsControls.GridLines {
            anchors.fill: parent
            anchors.topMargin: axisMetrics.height / 2
            anchors.bottomMargin: axisMetrics.height / 2
            direction: ChartsControls.GridLines.Vertical

            major.color: Kirigami.Theme.alternateBackgroundColor
            major.count: Math.max(1, axisLabels.source.itemCount - 2)
            minor.visible: false
        }

        Charts.LineChart {
            id: chart
            anchors.fill: parent
            anchors.topMargin: axisMetrics.height / 2
            anchors.bottomMargin: axisMetrics.height / 2

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

            fillOpacity: 0.1
            interpolate: true
            stacked: false
            lineWidth: 1
            direction: Charts.XYChart.ZeroAtEnd

            colorSource: Charts.ColorGradientSource { baseColor: Kirigami.Theme.highlightColor; itemCount: chart.valueSources.length }
        }


        ChartsControls.AxisLabels {
            id: axisLabels

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: axisMetrics.height
            }

            direction: ChartsControls.AxisLabels.VerticalBottomTop
            alignment: Qt.AlignLeft | Qt.AlignBottom
            constrainToBounds: false

            delegate: Label {
                text: card.formatLabel(ChartsControls.AxisLabels.label);
                font: Kirigami.Theme.smallFont;
                color: Qt.alpha(Kirigami.Theme.textColor, 0.8)

                // Cover the background with an overlay to ensure the text remains readable.
                rightInset: -height / 4
                background: Rectangle { color: Kirigami.Theme.backgroundColor; radius: height / 2 }
            }

            source: Charts.ChartAxisSource {
                chart: chart;
                axis: Charts.ChartAxisSource.YAxis;
                itemCount: Math.max(2, Math.floor(axisLabels.height / (Kirigami.Units.gridUnit)))
            }
        }

        Label {
            anchors.top: parent.top
            anchors.right: parent.right
            text: card.title
        }
    }
}
