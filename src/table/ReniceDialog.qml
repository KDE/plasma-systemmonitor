/*
 * SPDX-FileCopyrightText: 2025 Matthieu Carteron <rubisetcie@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.process as Process

Dialog {
    id: dialog

    property int cpuPriority: 20
    property int ioPriority: 0
    property int cpuMode: 0
    property int ioMode: 0

    title: i18ndc("plasma-systemmonitor", "@title:window", "Set Priority")
    focus: true
    modal: true

    standardButtons: Dialog.Ok | Dialog.Cancel

    header: Kirigami.DialogHeader {
        dialog: dialog

        contentItem: Kirigami.DialogHeaderTopContent {
            dialog: dialog
            showCloseButton: false
        }
    }

    contentItem: GridLayout {
        columns: 4
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            Layout.preferredWidth: cpuModes.height
            Layout.preferredHeight: cpuModes.height
            source: "cpu"
        }

        ColumnLayout {
            id: cpuModes
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                level: 2
                text: i18ndc("plasma-systemmonitor", "@title:group", "CPU Scheduler")
            }

            component CpuModeItem: RowLayout {
                required property int cpuMode
                required property string text
                required property string toolTip

                spacing: Kirigami.Units.smallSpacing

                RadioButton {
                    checked: dialog.cpuMode == parent.cpuMode
                    text: parent.text

                    onToggled: dialog.cpuMode = parent.cpuMode
                }

                Item { Layout.fillWidth: true }

                Kirigami.ContextualHelpButton {
                    toolTipText: parent.toolTip
                }
            }

            CpuModeItem {
                cpuMode: Process.Scheduler.Other
                text: i18ndc("plasma-systemmonitor", "@option:radio for process scheduler mode", "Normal")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "The standard time-sharing scheduler for processes without special requirements.")
            }

            CpuModeItem {
                cpuMode: Process.Scheduler.Batch
                text: i18ndc("plasma-systemmonitor", "@option:radio for process scheduler mode", "Batch")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process is mildly disfavored in scheduling decisions, for CPU-intensive non-interactive processes.")
            }

            CpuModeItem {
                cpuMode: Process.Scheduler.RoundRobin
                text:  i18ndc("plasma-systemmonitor", "@option:radio for process scheduler mode", "Round robin")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process will run whenever runnable, with timeslicing.")
            }

            CpuModeItem {
                cpuMode: Process.Scheduler.Fifo
                text: i18ndc("plasma-systemmonitor", "@option:radio for process scheduler mode", "FIFO")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process will run whenever runnable, with no timeslicing.")
            }
        }

        Kirigami.Icon {
            Layout.preferredWidth: ioModes.height
            Layout.preferredHeight: ioModes.height
            source: "drive-harddisk"
        }

        ColumnLayout {
            id: ioModes
            spacing: Kirigami.Units.smallSpacing

            property int ioMode

            Kirigami.Heading {
                level: 2
                text: i18ndc("plasma-systemmonitor", "@title:group", "I/O Scheduler")
            }

            component IoModeItem: RowLayout {
                required property int ioMode
                required property string text
                required property string toolTip

                spacing: Kirigami.Units.smallSpacing

                RadioButton {
                    checked: dialog.ioMode == parent.ioMode
                    text: parent.text

                    onToggled: dialog.ioMode = parent.ioMode
                }

                Item { Layout.fillWidth: true }

                Kirigami.ContextualHelpButton {
                    toolTipText: parent.toolTip
                }
            }

            IoModeItem {
                ioMode: Process.IoPriority.None
                text: i18ndc("plasma-systemmonitor", "@option:radio for I/O scheduler mode", "Normal")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process' priority is based on the CPU priority.")
            }

            IoModeItem {
                ioMode: Process.IoPriority.Idle
                text: i18ndc("plasma-systemmonitor", "@option:radio for I/O scheduler mode", "Idle")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process can only use the hard disk when no other process has used it very recently.")
            }

            IoModeItem {
                ioMode: Process.IoPriority.BestEffort
                text: i18ndc("plasma-systemmonitor", "@option:radio for I/O scheduler mode", "Best Effort")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process is given higher priority to access the hard disk than normal.")
            }

            IoModeItem {
                ioMode: Process.IoPriority.RealTime
                text: i18ndc("plasma-systemmonitor", "@option:radio for I/O scheduler mode", "Real Time")
                toolTip: i18ndc("plasma-systemmonitor", "@info:tooltip from ContextualHelpButton", "Process gets immediate access to the hard disk whenever needed, regardless of what else is going on.")
            }
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.columnSpan: 2

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Slider {
                    id: cpuPrioritySlider
                    Layout.fillWidth: true

                    from: 1
                    to: 40
                    snapMode: Slider.NoSnap
                    value: dialog.cpuPriority

                    onMoved: {
                        dialog.cpuPriority = value;
                    }
                }

                SpinBox {
                    id: cpuPrioritySpinbox
                    spacing: Kirigami.Units.smallSpacing
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 3

                    from: 1
                    to: 40
                    stepSize: 1
                    editable: true
                    value: dialog.cpuPriority

                    onValueModified: {
                        dialog.cpuPriority = value;
                    }
                }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18ndc("plasma-systemmonitor", "Lower process priority", "Low priority")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.fillWidth: true
                }
                Label {
                    text: i18ndc("plasma-systemmonitor", "Higher process priority", "High priority")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.minimumWidth: cpuPrioritySpinbox.width
                }
            }
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Layout.columnSpan: 2

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Slider {
                    id: ioPrioritySlider
                    Layout.fillWidth: true

                    from: 0
                    to: 7
                    snapMode: Slider.NoSnap
                    value: dialog.ioPriority

                    onMoved: {
                        dialog.ioPriority = value;
                    }
                }

                SpinBox {
                    id: ioPrioritySpinbox
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 3

                    from: 0
                    to: 7
                    stepSize: 1
                    editable: true
                    value: dialog.ioPriority

                    onValueModified: {
                        dialog.ioPriority = value;
                    }
                }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Label {
                    text: i18ndc("plasma-systemmonitor", "Lower I/O priority", "Low priority")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.fillWidth: true
                }
                Label {
                    text: i18ndc("plasma-systemmonitor", "Higher I/O priority", "High priority")
                    textFormat: Text.PlainText
                }
                Item {
                    Layout.minimumWidth: ioPrioritySpinbox.width
                }
            }
        }
    }
}
