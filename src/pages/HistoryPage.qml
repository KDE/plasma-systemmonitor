import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.4 as Kirigami

import org.kde.ksgrd2 0.1 as KSGRD
import org.kde.quickcharts 1.0 as Charts

import "qrc:/components"

Kirigami.Page {
    title: i18n("History")

    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.gridUnit

    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None

    ColumnLayout {
        anchors.fill: parent

        spacing: Kirigami.Units.gridUnit

        LineChartCard {
            id: cpuCard

            title: i18n("CPU");

            yRange { automatic: false; from: 0; to: totalCores.value * 100 }

            stacked: true
            formatLabel: function(input) { return KSGRD.Formatter.formatValueShowNull(input, KSGRD.Units.UnitPercent) }

            nameSource: Charts.ModelSource { model: cpuModel; roleName: "Name"; indexColumns: true }

            Instantiator {
                model: totalCores.value
                Charts.ModelHistorySource {
                    model: cpuModel;
                    row: 0;
                    column: modelData;
                    roleName: "Value";
                    maximumHistory: 100
                    interval: 500
                }
                onObjectAdded: {
                    cpuCard.chart.insertValueSource(index, object)
                }
                onObjectRemoved: {
                    cpuCard.chart.removeValueSource(object)
                }
            }

            KSGRD.SensorDataModel {
                id: cpuModel
                sensors: {
                    var result = []
                    for(var i = 0; i < totalCores.value; i++) {
                        result.push("cpu/cpu%1/TotalLoad".arg(i));
                    }
                    return result;
                }
            }

            KSGRD.Sensor {
                id: totalCores
                sensorId: "cpu/system/cores"
            }

            axisLabels.delegate: Label { text: cpuCard.formatLabel(Charts.AxisLabels.label / totalCores.value); font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.7; opacity: 0.8 }
        }

        LineChartCard {
            title: i18n("Memory");

            yRange { automatic: false; from: 0; to: Math.max(usedPhysical.maximum, usedSwap.maximum) }
            formatLabel: function(input) { return KSGRD.Formatter.formatValueShowNull(input, usedPhysical.unit) }

            valueSources: [
                Charts.ValueHistorySource { value: usedPhysical.value; maximumHistory: 100; interval: 500 },
                Charts.ValueHistorySource { value: usedSwap.value; maximumHistory: 100; interval: 500 }
            ]
            nameSource: Charts.ArraySource { array: [usedPhysical.name, usedSwap.name] }

            KSGRD.Sensor { id: usedPhysical; sensorId: "mem/physical/allocated" }
            KSGRD.Sensor { id: usedSwap; sensorId: "mem/swap/used" }
            KSGRD.Sensor { id: freeSwap; sensorId: "mem/swap/free" }
        }

        LineChartCard {
            title: i18n("Network");

            valueSources: [
                Charts.ModelHistorySource {
                    model: networkModel;
                    row: 0;
                    column: 0;
                    roleName: "Value";
                    maximumHistory: 100
                    interval: 500
                },
                Charts.ModelHistorySource {
                    model: networkModel;
                    row: 0;
                    column: 1;
                    roleName: "Value";
                    maximumHistory: 100
                    interval: 500
                }
            ]
            nameSource: Charts.ModelSource { model: networkModel; roleName: "Name"; indexColumns: true }

            formatLabel: function(input) { return KSGRD.Formatter.formatValueShowNull(input, KSGRD.Units.UnitKiloByteRate) }

            KSGRD.SensorDataModel {
                id: networkModel
                sensors: [
                    "network/all/receivedDataRate",
                    "network/all/sentDataRate"
                ]
            }
        }
    }
}
