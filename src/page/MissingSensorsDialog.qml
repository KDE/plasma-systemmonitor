/*
 * SPDX-FileCopyrightText: 2022 Arjen Hiemstra <ahiemstra@heimr.nl>
 * SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.20 as Kirigami

import org.kde.ksysguard.page 1.0
import org.kde.ksysguard.faces 1.0 as Faces

Kirigami.Dialog {
    id: dialog

    property var missingSensors: { }
    property var sensorReplacement: { }

    title: i18nc("@title", "Replace Missing Sensors")

    preferredWidth: Kirigami.Units.gridUnit * 30
    preferredHeight: Kirigami.Units.gridUnit * 30

    focus: true

    // We already have a cancel button in the footer
    showCloseButton: false

    standardButtons: Dialog.Save | Dialog.Cancel

    onAccepted: {
        let result = []

        for (let i = 0; i < sensorsModel.count; ++i) {
            let entry = sensorsModel.get(i)
            if (!entry.replacement) {
                continue
            }

            result.push({
                "face": entry.face,
                "sensor": entry.sensor,
                "replacement": entry.replacement
            })
        }

        sensorReplacement = result
    }

    onMissingSensorsChanged: {
        sensorsModel.clear();
        missingSensors.sort((first, second) => first.title.localeCompare(second.title))
        for (let entry of missingSensors) {
            entry.replacement = ""
            sensorsModel.append(entry)
        }
    }

    ListView {
        model: ListModel { id: sensorsModel }

        section.property: "title"
        section.delegate: Kirigami.ListSectionHeader {
            required property string section
            label: section
        }

        delegate: Kirigami.BasicListItem {
            id: delegate

            implicitHeight: Kirigami.Units.gridUnit * 2 + Kirigami.Units.smallSpacing * 2
            labelItem.textFormat: Text.MarkdownText
            label: model.sensor

            trailing: Faces.Choices {
                width: delegate.width * 0.5

                supportsColors: false
                maxAllowedSensors: 1
                labelsEditable: false
                labels: { }

                onSelectedChanged: {
                    if (selected.length > 0) {
                        sensorsModel.setProperty(index, "replacement", selected[0])
                    }
                }
            }
        }
    }
}

