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

    property alias legendVisible: legend.visible

    padding: Kirigami.Units.smallSpacing

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Charts.GridLines {
        anchors.fill: chart
        direction: Charts.GridLines.Vertical

        major.visible: false

        minor.color: Kirigami.Theme.alternateBackgroundColor
        minor.frequency: 1
    }

    Charts.GridLines {
        anchors.fill: chart
        direction: Charts.GridLines.Horizontal

        major.visible: false

        minor.color: Kirigami.Theme.alternateBackgroundColor
        minor.frequency: 1
    }

    Charts.AxisLabels {
        id: axisLabels

        anchors {
            left: parent.left
            leftMargin: Kirigami.Units.smallSpacing
            top: parent.top
            topMargin: Kirigami.Units.largeSpacing * 2
            bottom: legend.top
            bottomMargin: Kirigami.Units.smallSpacing
        }

        direction: Charts.AxisLabels.VerticalBottomTop
        alignment: Qt.AlignRight | Qt.AlignBottom
        constrainToBounds: false

        delegate: Label { text: card.formatLabel(Charts.AxisLabels.label); font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.7; opacity: 0.8 }

        source: Charts.ChartAxisSource {
            chart: chart;
            axis: Charts.ChartAxisSource.YAxis;
            itemCount: (chart.height - Kirigami.Units.largeSpacing * 2) / Kirigami.Theme.defaultFont.pixelSize
        }
    }

    ChartsControls.Legend {
        id: legend

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        Layout.maximumWidth: parent.width
        height: visible ? implicitHeight : 0

        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8;

        chart: chart
        formatValue: card.formatLabel
        valueWidth: Kirigami.Units.gridUnit * 3
        valueVisible: true
        colorWidth: height
        spacing: Kirigami.Units.largeSpacing

        indicator: Rectangle { radius: height / 2; width: height; color: delegateColor }
    }

    Charts.LineChart {
        id: chart
        anchors {
            left: axisLabels.right
            leftMargin: Kirigami.Units.largeSpacing
            top: parent.top
            bottom: legend.top
            bottomMargin: Kirigami.Units.smallSpacing
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
