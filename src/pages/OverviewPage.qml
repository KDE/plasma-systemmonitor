import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import QtGraphicalEffects 1.0

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksgrd2 0.1 as KSGRD
import org.kde.quickcharts 1.0 as Charts
import org.kde.quickcharts.controls 1.0 as ChartsControls

import org.kde.kio 1.0 as KIO

import org.kde.kcoreaddons 1.0 as KCoreAddons

import "qrc:/components"
import "qrc:/components/table"
import org.kde.ksysguardqml 1.0

Kirigami.Page {
    id: page

    title: i18n("Overview")

    topPadding: Kirigami.Units.largeSpacing
    bottomPadding: Kirigami.Units.gridUnit

//     globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None

    readonly property real wideBreakpoint: Kirigami.Units.gridUnit * 30

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

//         StyledGroupBox {
//             title: i18n("Overview")

            RowLayout {
                Layout.preferredHeight: 34

                spacing: Kirigami.Units.largeSpacing
//                 anchors.fill: parent

//                 columns: 5
//                 rows: 2
//                 flow: GridLayout.TopToBottom

                Kirigami.AbstractCard {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    ChartsControls.PieChartControl {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        anchors.topMargin: Kirigami.Units.gridUnit * 2

                        text: memoryDisplay.visible ? "" : ((usedMemorySensor.value / totalMemorySensor.value) * 100).toFixed(0) + "%"

                        valueSources: Charts.SingleValueSource { value: usedMemorySensor.value }

                        color: Kirigami.Theme.positiveTextColor

                        chart.range { to: totalMemorySensor.value ? totalMemorySensor.value : 0; automatic: false }
                        chart.fromAngle: -180
                        chart.backgroundColor: Qt.rgba(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.5)
                        chart.thickness: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height) * 0.125)
                        chart.smoothEnds: true

                        KSGRD.Sensor { id: usedMemorySensor; sensorId: "mem/physical/allocated" }
                        KSGRD.Sensor { id: totalMemorySensor; sensorId: "mem/physical/total" }

                        UsedTotalDisplay {
                            id: memoryDisplay
                            anchors.centerIn: parent
                            visible: height < parent.height - Kirigami.Units.largeSpacing * 3
                            usedValue: usedMemorySensor.formattedValue
                            totalValue: totalMemorySensor.formattedValue
                        }
                    }

                    Kirigami.Heading {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: Kirigami.Units.smallSpacing
                        text: i18n("Memory");
                        level: 3
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

//                 Kirigami.Separator { Layout.fillHeight: true; Layout.rowSpan: 2 }

                Kirigami.AbstractCard {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Kirigami.Heading {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: Kirigami.Units.smallSpacing
                        text: i18n("Storage");
                        level: 3
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ChartsControls.PieChartControl {
    //                     Layout.fillWidth: true
    //                     Layout.fillHeight: true
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        anchors.topMargin: Kirigami.Units.gridUnit * 2

                        text: diskDisplay.visible ? "" : ((usedDiskSensor.value / totalDiskSensor.value) * 100).toFixed(0) + "%"

                        valueSources: Charts.SingleValueSource { value: usedDiskSensor.value }

                        color: Kirigami.Theme.activeTextColor

                        chart.range { to: totalDiskSensor.value; automatic: false }
                        chart.fromAngle: -180
                        chart.backgroundColor: Qt.rgba(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.5)
                        chart.thickness: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height) * 0.125)
                        chart.smoothEnds: true

                        KSGRD.Sensor { id: usedDiskSensor; sensorId: "partitions/all/usedspace" }
                        KSGRD.Sensor { id: totalDiskSensor; sensorId: "partitions/all/total" }

                        UsedTotalDisplay {
                            id: diskDisplay
                            anchors.centerIn: parent
                            visible: height < parent.height - Kirigami.Units.largeSpacing * 3
                            usedValue: usedDiskSensor.formattedValue
                            totalValue: totalDiskSensor.formattedValue
                        }
                    }
                }

//                 Kirigami.Separator { Layout.fillHeight: true; Layout.rowSpan: 2 }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ChartsControls.PieChartControl {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        anchors.topMargin: Kirigami.Units.gridUnit * 2

                        valueSources: Charts.SingleValueSource { value: cpuSensor.value }
                        text: height - Kirigami.Units.largeSpacing * 3 > diskDisplay.height ? cpuSensor.formattedValue : cpuSensor.shortened

                        color: Kirigami.Theme.negativeTextColor

                        chart.range { to: 100; automatic: false }
                        chart.fromAngle: -180
                        chart.backgroundColor: Qt.rgba(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.5)
                        chart.thickness: Math.max(Kirigami.Units.gridUnit * 0.75, Math.min(width, height) * 0.125)
                        chart.smoothEnds: true

                        KSGRD.Sensor {
                            id: cpuSensor;
                            sensorId: "cpu/system/TotalLoad"
                            property string shortened: value ? value.toFixed(0) + "%" : ""
                        }
                    }

                    Kirigami.Heading {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: Kirigami.Units.smallSpacing
                        text: i18n("CPU");
                        level: 3
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
//         }

        Kirigami.Heading { text: i18n("Network and System"); level: 2 }

        StyledGroupBox {
            id: networkStats

            Layout.preferredHeight: 33
//             title: i18n("Network Stats")

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing

                Loader {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    source: "qrc:/components/NetworkDetails.qml"

                    Label {
                        anchors.fill: parent
                        text: i18n("Connection details not available.")
                        visible: parent.status != Loader.Ready
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Kirigami.Separator { Layout.fillHeight: true }

                GridLayout {
                    Layout.preferredWidth: 0
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    columns: parent.height < Kirigami.Units.gridUnit * 6 && networkStats.width < page.wideBreakpoint ? 2 : 1

                    SensorLabel { sensorId: "os/system/hostname"; prefix: i18n("Host:") }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: width
                            source: "download"
                        }
                        Label { text: networkStats.width > page.wideBreakpoint ? i18n("Download") : i18n("Down") }
                    }

                    Kirigami.Heading {
                        Layout.alignment: Qt.AlignHCenter
//                         Layout.topMargin: networkStats.width > page.wideBreakpoint ? Kirigami.Units.gridUnit : 0
                        Layout.fillWidth: true
                        level: 2;
                        text: downSensor.formattedValue
                        horizontalAlignment: Qt.AlignHCenter
                        KSGRD.Sensor { id: downSensor; sensorId: "network/all/receivedDataRate" }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
//                         visible: networkStats.width < page.wideBreakpoint
                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: width
                            source: "cloud-upload"
                        }
                        Label { text: i18n("Upload") }
                    }

                    Kirigami.Heading {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
//                         visible: networkStats.width < page.wideBreakpoint
                        level: 2;
                        text: upSensor.formattedValue
                        horizontalAlignment: Qt.AlignHCenter

                        KSGRD.Sensor { id: upSensor; sensorId: "network/all/sentDataRate" }
                    }
                }

                Kirigami.Separator { Layout.fillHeight: true; visible: networkStats.width > page.wideBreakpoint }

                ColumnLayout {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true

                    Kirigami.Icon {
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        source: systemIcon.value
                        KSGRD.Sensor { id: systemIcon; sensorId: "os/system/logo" }

                        layer.enabled: true
                        layer.effect: DropShadow {
                            radius: Kirigami.Units.largeSpacing
                            samples: radius * 2 + 1
                        }
                    }

                    SensorLabel { sensorId: "os/system/name"; }
//                     SensorLabel { sensorId: "os/system/hostname"; prefix: i18n("Host:") }
                    SensorLabel {
                        sensorId: "uptime/system/uptime";
                        text: i18n("Uptime: %1", KCoreAddons.Format.formatDuration(sensor.value * 1000));
                    }

                    TextField {
                        Layout.fillWidth: true
                        horizontalAlignment: Qt.AlignHCenter

                        text: i18n("%1, %2 Memory", processorNames.value, totalMemorySensor.formattedValue)
                        wrapMode: Text.Wrap

                        visible: summary.width > Kirigami.Units.gridUnit * 40 && summary.height > Kirigami.Units.gridUnit * 10

                        readOnly: true
                        background: Item { }
                        padding: 0

                        KSGRD.Sensor { id: processorNames; sensorId: "system/hardware/processorNames" }
                    }

                    Kirigami.LinkButton {
                        Layout.fillWidth: true;
                        horizontalAlignment: Qt.AlignHCenter;
                        wrapMode: Text.WordWrap
                        text: i18n("View More Information")
                        onClicked: runner.openService("org.kde.kinfocenter")
                    }
                }

//                 ColumnLayout {
//                     Layout.preferredWidth: 0
//                     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
//                     visible: networkStats.width > page.wideBreakpoint
//
//                     RowLayout {
//                         Layout.alignment: Qt.AlignHCenter
//                         Kirigami.Icon {
//                             Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
//                             Layout.preferredHeight: width
//                             source: "cloud-upload"
//                         }
//                         Label { text: i18n("Upload") }
//                     }
//
//                     Kirigami.Heading {
//                         Layout.alignment: Qt.AlignHCenter
//                         Layout.topMargin: Kirigami.Units.gridUnit
//                         Layout.fillWidth: true
//                         level: 2;
//                         text: upSensor.formattedValue
//                         horizontalAlignment: Qt.AlignHCenter
//                         KSGRD.Sensor { id: upSensor; sensorId: "network/all/sentDataRate" }
//                     }
//                 }
            }
        }

//         StyledGroupBox {
//             id: summary
//
//             Layout.preferredHeight: 33
//
// //             title: i18n("System Summary")
//
//             Kirigami.Theme.colorSet: Kirigami.Theme.View
//
//             RowLayout {
//                 anchors.fill: parent
//
//                 ColumnLayout {
//                     Layout.preferredWidth: 0
//                     Layout.fillWidth: true
//
//                     Kirigami.Icon {
//                         Layout.fillHeight: true
//                         Layout.preferredWidth: height
//                         Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
//                         source: systemIcon.value
//                         KSGRD.Sensor { id: systemIcon; sensorId: "os/system/logo" }
//                     }
//
//                     SensorLabel { sensorId: "os/system/name"; }
//                     SensorLabel { sensorId: "os/system/hostname"; prefix: i18n("Host:") }
//                     SensorLabel {
//                         sensorId: "uptime/system/uptime";
//                         text: i18n("Uptime: %1", KCoreAddons.Format.formatDuration(sensor.value * 1000));
//                     }
//
//                     TextField {
//                         Layout.fillWidth: true
//                         horizontalAlignment: Qt.AlignHCenter
//
//                         text: i18n("%1, %2 Memory", processorNames.value, totalMemorySensor.formattedValue)
//                         wrapMode: Text.Wrap
//
//                         visible: summary.width > Kirigami.Units.gridUnit * 40 && summary.height > Kirigami.Units.gridUnit * 10
//
//                         readOnly: true
//                         background: Item { }
//                         padding: 0
//
//                         KSGRD.Sensor { id: processorNames; sensorId: "system/hardware/processorNames" }
//                     }
//                 }
//
//                 Kirigami.Separator { Layout.fillHeight: true }
//
//                 Item {
//                     Layout.preferredWidth: 0
//                     Layout.fillWidth: true
//                     Layout.fillHeight: true
//
//                     visible: summary.width > page.wideBreakpoint
//
//                     ColumnLayout {
//                         anchors.centerIn: parent
//
//                         SensorLabel {
//                             id: kernelLabel
//                             Layout.leftMargin: Math.max(0, (parent.width - parent.implicitWidth) / 2)
//                             horizontalAlignment: Qt.AlignLeft;
//                             sensorId: "os/kernel/version";
//                             prefix: i18n("Kernel:")
//                         }
//
//                         RowLayout {
//                             Layout.fillWidth: false
//                             Layout.leftMargin: kernelLabel.leftMargin
//
//                             visible: summary.width > Kirigami.Units.gridUnit * 40 && summary.height > Kirigami.Units.gridUnit * 10
//
//                             Label { Layout.alignment: Qt.AlignTop; text: i18n("Resolution:"); }
//                             TextArea {
//                                 text: {
//                                     if (Qt.application.screens.length == 1) {
//                                         return "%1x%2".arg(Qt.application.screens[0].width.toFixed()).arg(Qt.application.screens[0].height.toFixed());
//                                     }
//
//                                     var result = []
//                                     for (var i in Qt.application.screens) {
//                                         var screen = Qt.application.screens[i]
//                                         var name = screen.model !== "" ? screen.model : screen.name
//                                         result.push("%1: %2x%3".arg(name).arg(screen.width.toFixed()).arg(screen.height.toFixed()))
//                                     }
//
//                                     return result.join("\n")
//                                 }
//                                 readOnly: true
//                                 background: Item { }
//                                 padding: 0
//                             }
//                         }
//
//                         SensorLabel {
//                             Layout.leftMargin: Math.max(0, (parent.width - parent.implicitWidth) / 2)
//                             horizontalAlignment: Qt.AlignLeft;
//                             sensorId: "os/plasma/qtVersion";
//                             prefix: i18n("Qt:")
//                         }
//                         SensorLabel {
//                             Layout.leftMargin: Math.max(0, (parent.width - parent.implicitWidth) / 2)
//                             horizontalAlignment: Qt.AlignLeft;
//                             sensorId: "os/plasma/kfVersion";
//                             prefix: i18n("KDE Frameworks:")
//                         }
//                         SensorLabel {
//                             Layout.leftMargin: Math.max(0, (parent.width - parent.implicitWidth) / 2)
//                             horizontalAlignment: Qt.AlignLeft;
//                             sensorId: "os/plasma/plasmaVersion";
//                             prefix: i18n("KDE Plasma:")
//                         }
//                     }
//                 }
//
//                 Kirigami.Separator { Layout.fillHeight: true; visible: summary.width > page.wideBreakpoint }
//
//                 ColumnLayout {
//                     Layout.preferredWidth: 0
//                     Layout.fillWidth: true
//
//                     Kirigami.LinkButton {
//                         Layout.fillWidth: true;
//                         horizontalAlignment: Qt.AlignHCenter;
//                         wrapMode: Text.WordWrap
//                         text: i18n("View More Information")
//                         onClicked: runner.openService("org.kde.kinfocenter")
//                     }
//
//                     KIO.KRun { id: runner; }
//                 }
//             }
//         }
        Kirigami.Heading { level: 2; text: i18n("Applications") }

        Kirigami.AbstractCard {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredHeight: 33

            Kirigami.ShadowedTexture {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.devicePixelRatio
//                 clip: true
                radius: Kirigami.Units.smallSpacing
                source: table
            }

//             Rectangle {
//                 anchors.fill: parent
//                 clip: true
//                 radius: 49

            ProcessesTableView {
                id: table
                anchors.fill: parent

//                 anchors.leftMargin: Kirigami.Units.smallSpacing
//                 anchors.rightMargin: Kirigami.Units.smallSpacing


//                 anchors.margins: Kirigami.Units.smallSpacing

//                 viewMode: showGroup.checkedAction.mode

//                 onContextMenuRequested: {
//                     contextMenu.popup(applicationWindow(), position.x, position.y)
//                 }
//
//                 onHeaderContextMenuRequested: {
//                     headerContextMenu.popup(applicationWindow(), position)
//                 }

                enabledColumns: [
                    "name",
                    "usage",
                    "vmPSS",
                    "netInbound",
                    "netOutbound",
                    "ioCharactersActuallyReadRate",
                    "ioCharactersActuallyWrittenRate"
                ]

//                 enabledColumns: columnDialog.visibleColumns
//                 columnDisplay: columnDialog.columnDisplay

//                 visible: false
                opacity: 0
                layer.enabled: true
            }
//             }
        }
    }
}
