/*
 * SPDX-FileCopyrightText: 2025 Matthieu Carteron <rubisetcie@gmail.com>
 * SPDX-FileCopyrightText: 2026 Taras Oleksyn <taras.oleksyn@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.process as Process
import org.kde.ksysguard.sensors as Sensors

Dialog {
    id: dialog

    property var affinity: []
    readonly property int cpuCount: cpuCountSensor.value
    property string labelText

    title: i18ndc("plasma-systemmonitor", "@title:window", "Set Affinity")
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

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Label {
            text: dialog.labelText
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            Layout.fillWidth: true
            // so long process/application names don't stretch the dialog
            Layout.preferredWidth: 0

            ToolTip.visible: truncated && labelHoverHandler.hovered
            ToolTip.text: dialog.labelText

            HoverHandler {
                id: labelHoverHandler
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                // match the height of CPU grid and buttons, don't get too small with few CPUs
                Layout.preferredWidth: Math.max(affinitySection.height, Kirigami.Units.gridUnit * 6)
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignTop
                source: "cpu"
            }

            ColumnLayout {
                id: affinitySection
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                GridLayout {
                    id: cpuGrid
                    columns: Math.ceil(Math.sqrt(dialog.cpuCount))
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    Repeater {
                        model: dialog.cpuCount

                        CheckBox {
                            id: cpuCheckbox
                            required property int index

                            text: i18ndc("plasma-systemmonitor", "@option:check CPU core number", "CPU %1", index + 1)

                            Connections {
                                target: dialog
                                function onAffinityChanged() {
                                    cpuCheckbox.checked = dialog.affinity ? dialog.affinity.indexOf(cpuCheckbox.index) !== -1 : false
                                }
                            }

                            Component.onCompleted: {
                                checked = dialog.affinity ? dialog.affinity.indexOf(index) !== -1 : false
                            }

                            onClicked: {
                                let newAffinity = dialog.affinity ? dialog.affinity.slice() : []
                                const currentIndex = newAffinity.indexOf(index)

                                if (checked && currentIndex === -1) {
                                    newAffinity.push(index)
                                    newAffinity.sort((a, b) => a - b)
                                } else if (!checked && currentIndex !== -1) {
                                    newAffinity.splice(currentIndex, 1)
                                }

                                dialog.affinity = newAffinity
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        Layout.fillWidth: true
                        text: i18ndc("plasma-systemmonitor", "@action:button", "Select All")
                        onClicked: {
                            let allCpus = []
                            for (let i = 0; i < dialog.cpuCount; i++) {
                                allCpus.push(i)
                            }
                            dialog.affinity = allCpus
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18ndc("plasma-systemmonitor", "@action:button", "Clear All")
                        onClicked: {
                            dialog.affinity = []
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18ndc("plasma-systemmonitor", "@action:button", "Invert")
                        onClicked: {
                            let inverted = []
                            for (let i = 0; i < dialog.cpuCount; i++) {
                                if (!dialog.affinity.includes(i)) {
                                    inverted.push(i)
                                }
                            }
                            dialog.affinity = inverted
                        }
                    }
                }
            }
        }
    }

    Sensors.Sensor {
        id: cpuCountSensor
        sensorId: "cpu/all/coreCount"
    }
}
