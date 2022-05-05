/*
 * SPDX-FileCopyrightText: 2022 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.15 as Kirigami

import org.kde.ksysguard.page 1.0
import org.kde.ksysguard.faces 1.0 as Faces

Dialog {
    id: dialog

    property var missingSensors: { }
    property var sensorReplacement: { }

    modal: true
    parent: Overlay.overlay
    focus: true

    x: parent ? Math.round(parent.width / 2 - width / 2) : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: 1 // Allow dialog background border to show
    rightPadding: 1 // Allow dialog background border to show
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    title: i18nc("@title", "Replace Missing Sensors")

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

    contentItem: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        implicitWidth: Kirigami.Units.gridUnit * 30
        implicitHeight: Kirigami.Units.gridUnit * 30

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; top: parent.top } }

        ScrollView {
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: columnView

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

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } }
    }

    footer: DialogButtonBox {
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            text: i18nc("@action:button", "Save")
            icon.name: "document-save"
        }
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            text: i18nc("@action:button", "Cancel")
            icon.name: "dialog-close"
        }
    }
}

