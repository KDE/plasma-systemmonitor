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

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            Layout.preferredWidth: affinitySection.height
            Layout.preferredHeight: affinitySection.height
            Layout.alignment: Qt.AlignTop
            source: "cpu"
        }

        ColumnLayout {
            id: affinitySection
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: i18ndc("plasma-systemmonitor", "@label", "Allow to run on:")
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GridLayout {
                id: cpuGrid
                columns: Math.ceil(Math.sqrt(cpuCountSensor.value))
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: cpuCountSensor.value

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
                        for (let i = 0; i < cpuCountSensor.value; i++) {
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
                        for (let i = 0; i < cpuCountSensor.value; i++) {
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

    Sensors.Sensor {
        id: cpuCountSensor
        sensorId: "cpu/all/coreCount"
    }
}
