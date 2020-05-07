import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.4 as Kirigami

import org.kde.quickcharts 1.0 as Charts

Kirigami.AbstractCard {
    id: root

    property alias pieChart: pieChart
    property alias lineChart: lineChart
    property alias legend: legend
    property alias applications: applications
    property alias applicationsHeaders: applicationsHeaderRepeater.model

    property var formatValue: function(input) { return input; }

    Layout.fillWidth: true
    Layout.preferredHeight: 0
    Layout.fillHeight: true

    property int dataColumnWidth: 80
    property var columnWidths: [_applicationsTableWidth - dataColumnWidth * (applications.columns - 1) - Kirigami.Units.smallSpacing * (applications.columns - 1), dataColumnWidth, dataColumnWidth]

    property real _applicationsTableWidth: width - pieChart.width - legend.width - Kirigami.Units.largeSpacing * 4

    RowLayout {
        anchors {
            left: parent.left
            leftMargin: Kirigami.Units.largeSpacing
            top: parent.top
            topMargin: Kirigami.Units.largeSpacing
            right: parent.right
            rightMargin: Kirigami.Units.largeSpacing
            bottom: parent.bottom
            bottomMargin: Kirigami.Units.largeSpacing
        }

        spacing: Kirigami.Units.largeSpacing

        Charts.PieChart {
            id: pieChart
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(parent.width / 4, height)

            backgroundColor: Qt.rgba(0.0, 0.0, 0.0, 0.2)
            continueColors: true
            thickness: Kirigami.Units.gridUnit

            Charts.LineChart {
                id: lineChart
                anchors.centerIn: parent;
                width: parent.width / 2
                height: width

                direction: Charts.XYChart.ZeroAtEnd
                lineWidth: 2
                fillOpacity: 0
                smooth: true

                colorSource: pieChart.colorSource
                nameSource: pieChart.nameSource
            }
        }

        Legend {
            id: legend

            Layout.preferredWidth: parent.width * 0.3
            Layout.alignment: Qt.AlignTop

            model: Charts.LegendModel { chart: pieChart; sourceIndex: 0 }
            flow: GridLayout.TopToBottom

            formatValue: root.formatValue
            valueWidth: root.dataColumnWidth
        }

        ColumnLayout {
            spacing: 0

            RowLayout {
                Repeater {
                    id: applicationsHeaderRepeater
                    model: [i18n("Application")]

                    Label {
                        Layout.preferredWidth: root.columnWidths[index]
                        text: modelData;
                        color: Kirigami.Theme.disabledTextColor;
                        horizontalAlignment: index == 0 ? Qt.AlignLeft : Qt.AlignRight
                    }
                }
            }

            TableView {
                id: applications

                Layout.fillWidth: true
                Layout.fillHeight: true

                interactive: false

                columnSpacing: Kirigami.Units.smallSpacing
                clip: true

                columnWidthProvider: function (column) { return root.columnWidths[column] }

                property bool _complete: false

                delegate: Label {
                    text: model.display != undefined ? model.display : ""
                    horizontalAlignment: model.alignment == (Text.AlignRight + Text.AlignVCenter) ? Text.AlignRight : Text.AlignLeft
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    color: column == 0 ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
                }

                // See https://codereview.qt-project.org/c/qt/qtdeclarative/+/262876
                onWidthChanged: Qt.callLater(function() {if (applications.columns > 0 && _complete) {
                    applications.forceLayout()
                }});

    //             Component.onCompleted: _complete = true;
            }
        }
    }
}
