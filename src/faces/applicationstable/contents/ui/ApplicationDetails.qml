/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import Qt.labs.qmlmodels 1.0

import org.kde.kirigami 2.4 as Kirigami

import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.quickcharts 1.0 as Charts

import org.kde.ksysguard.formatter 1.0 as Formatter
import org.kde.ksysguard.process 1.0 as Process
import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.table 1.0 as Table

Page {
    id: root

    property var applications: []

    readonly property var firstApplication: applications.length > 0 ? applications[0] : null

    property real headerHeight: Kirigami.Units.gridUnit

    signal close()

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    background: Rectangle {
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    header: ToolBar {
        implicitHeight: root.headerHeight
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window

        Label {
            anchors.left: parent.left
            text: i18nc("@title:window", "Details")
        }

        ToolButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Math.min(root.headerHeight, implicitHeight)
            width: height
            icon.name: "dialog-close"
            onClicked: root.close()
        }
    }

    ColumnLayout {
        visible: root.firstApplication != null

        anchors {
            fill: parent
            leftMargin: Kirigami.Units.largeSpacing
            rightMargin: Kirigami.Units.largeSpacing
            topMargin: Kirigami.Units.smallSpacing
        }

        Label {
            text: i18nc("@title:group", "CPU")
        }

        LineChartCard {
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3

            yRange { from: 0; to: 100; automatic: false }
            xRange { from: 0; to: 50 }
            unit: Formatter.Units.UnitPercent

            colorSource: Charts.SingleValueSource { value: Kirigami.Theme.negativeTextColor }
            valueSources: [
                Charts.HistoryProxySource {
                    id: cpuHistory
                    source: Charts.SingleValueSource {
                        value: root.firstApplication ? root.firstApplication.cpu / cpuCountSensor.value : 0
                    }
                    maximumHistory: 50
                    interval: 2000
                }
            ]

            Sensors.Sensor { id: cpuCountSensor; sensorId: "system/cores/cores" }
        }
        Label {
            text: i18nc("@title:group", "Memory")
        }
        LineChartCard {
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3

            yRange { from: 0; to: totalMemorySensor.value ? totalMemorySensor.value : 0; automatic: false }
            xRange { from: 0; to: 50 }
            unit: totalMemorySensor.unit

            colorSource: Charts.SingleValueSource { value: Kirigami.Theme.positiveTextColor }
            valueSources: [
                Charts.HistoryProxySource {
                    id: memoryHistory
                    source: Charts.SingleValueSource {
                        // ProcessDataModel memory is in KiB but our y range is in B so convert memory correctly.
                        value: root.firstApplication ? root.firstApplication.memory * 1024 : 0
                    }
                    maximumHistory: 50
                    interval: 2000
                }
            ]

            Sensors.Sensor { id: totalMemorySensor; sensorId: "memory/physical/total" }
        }
        Label {
            text: i18nc("@title:group", "Network")
        }
        LineChartCard {
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3

            xRange { from: 0; to: 50 }
            unit: Formatter.Units.UnitKiloByteRate

            valueSources: [
                Charts.HistoryProxySource {
                    id: netInboundHistory
                    source: Charts.SingleValueSource { value: root.firstApplication ? root.firstApplication.netInbound : 0; }
                    maximumHistory: 50
                    interval: 2000
                },
                Charts.HistoryProxySource {
                    id: netOutboundHistory
                    source: Charts.SingleValueSource { value: root.firstApplication ? root.firstApplication.netOutbound : 0; }
                    maximumHistory: 50
                    interval: 2000
                }
            ]
        }
        Label {
            text: i18nc("@title:group", "Disk")
        }
        LineChartCard {
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3

            xRange { from: 0; to: 50 }
            unit: Formatter.Units.UnitKiloByteRate

            valueSources: [
                Charts.ValueHistorySource {
                    id: diskReadHistory
                    value: root.firstApplication ? root.firstApplication.diskRead : 0;
                    maximumHistory: 50
                    interval: 2000
                },
                Charts.ValueHistorySource {
                    id: diskWriteHistory
                    value: root.firstApplication ? root.firstApplication.diskWrite : 0;
                    maximumHistory: 50
                    interval: 2000
                }
            ]
        }

        Label {
            text: i18nc("@title:group", "Processes: %1", processTable.rows || " ")
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: -Kirigami.Units.largeSpacing;
            Layout.rightMargin: -Kirigami.Units.largeSpacing;

            color: Kirigami.Theme.backgroundColor
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            Table.BaseTableView {
                id: processTable

                anchors.fill: parent

                columnWidths: [0.5, 0.25, 0.25]
                sortName: "name"
                idRole: Process.ProcessDataModel.Attribute

                onSort: sortFilter.sort(column, order)

                model: Table.ProcessSortFilterModel {
                    id: sortFilter
                    sourceModel: processModel
                    hiddenAttributes: ["pid"]
                    filterPids: root.firstApplication ? root.firstApplication.pids : []
                }

                Process.ProcessDataModel {
                    id: processModel

                    enabled: root.visible && root.firstApplication != null

                    enabledAttributes: [
                        "name",
                        "usage",
                        "vmPSS",
                        "pid",
                    ]
                }

                delegate: DelegateChooser {
                    role: "Attribute"
                    DelegateChoice {
                        roleValue: "usage"
                        Table.BasicCellDelegate {
                            text: Formatter.Formatter.formatValue(parseInt(model.Value) / model.Maximum * 100, model.Unit)
                        }
                    }
                    DelegateChoice { Table.BasicCellDelegate { } }
                }
            }

            Kirigami.Separator { anchors.bottom: processTable.top; width: parent.width }
        }
    }

    Label {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        text: i18nc("@info:placeholder", "Select an application to see its details.")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        visible: root.firstApplication == null
    }

    onApplicationsChanged: {
        cpuHistory.clear()
        memoryHistory.clear()
        netInboundHistory.clear()
        netOutboundHistory.clear()
        diskReadHistory.clear()
        diskWriteHistory.clear()
    }
    onFirstApplicationChanged: {
        sortFilter.invalidate()
    }
}
