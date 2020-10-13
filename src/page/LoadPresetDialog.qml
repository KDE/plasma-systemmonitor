/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

Dialog {
    id: dialog

    property QtObject controller

    readonly property string selectedTitle: presetList.currentItem ? presetList.currentItem.title : ""
    readonly property string selectedFace: presetList.currentItem ? presetList.currentItem.chartFace : ""
    readonly property string selectedPreset: presetList.currentItem ? presetList.currentItem.preset : ""

    title: i18nc("@title:window", "Load Preset")

    modal: true
    parent: Overlay.overlay
    focus: true

    x: parent ? parent.width / 2 - width / 2 : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: 1 // Allow dialog background border to show
    rightPadding: 1 // Allow dialog background border to show
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    contentItem: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor

        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 30

        ColumnLayout {
            anchors.fill: parent

            Kirigami.Separator { Layout.fillWidth: true }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: presetList

                    currentIndex: -1

                    model: dialog.controller.availablePresetsModel
                    delegate: Kirigami.SwipeListItem {
                        highlighted: ListView.isCurrentItem

                        property string title: model.display
                        property string chartFace: model.config && model.config.chartFace !== undefined ? model.config.chartFace : ""
                        property string preset: model.pluginId

                        contentItem: Label {
                            Layout.fillWidth: true
                            text: model.display
                        }
                        actions: Kirigami.Action {
                            icon.name: "delete"
                            visible: model.writable
                            onTriggered: dialog.controller.uninstallPreset(model.pluginId);
                        }
                        onClicked: {
                            presetList.currentIndex = index
                        }
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }
        }
    }

    footer: DialogButtonBox {
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            text: i18nc("@action:button", "Load")
            icon.name: "document-open"
            enabled: presetList.currentIndex != -1
        }
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            text: i18nc("@action:button", "Cancel")
            icon.name: "dialog-cancel"
        }
    }
}
