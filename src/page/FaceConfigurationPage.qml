import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import Qt.labs.platform 1.1 as Platform

import org.kde.kirigami 2.12 as Kirigami
import org.kde.newstuff 1.62 as NewStuff

import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.page 1.0

Kirigami.ScrollablePage {
    id: page

    property FaceLoader loader

    property int activeSection: 0

    title: i18n("Configure %1", loader.controller.title)

    Kirigami.ColumnView.fillWidth: false

    actions.main: Kirigami.Action {
        icon.name: "dialog-close"
        text: i18n("Close")
        onTriggered: applicationWindow().pageStack.pop()
    }

    actions.contextualActions: [
        Kirigami.Action {
            text: i18n("Load Preset...")
            onTriggered: loadPresetDialog.open()
        },
        Kirigami.Action {
            text: i18n("Get new presets...")
            onTriggered: newPresetDialog.open()
        },
        Kirigami.Action {
            text: i18n("Save Settings as Preset")
            onTriggered: {
                loader.controller.savePreset()
                message.text = i18n("Saved settings as preset %1.", loader.controller.title)
                message.visible = true
            }
        },
        Kirigami.Action { separator: true },
        Kirigami.Action {
            text: i18n("Get new display styles...")
            onTriggered: newFaceDialog.open()
        }
    ]

    Platform.ColorDialog {
        id: colorDialog
        property string destinationSensor

        currentColor: destinationSensor != "" ? loader.controller.sensorColors[destinationSensor] : ""
        onAccepted: {
            var colors = loader.controller.sensorColors
            colors[destinationSensor] = color
            loader.controller.sensorColors = colors
        }
    }

    LoadPresetDialog {
        id: loadPresetDialog

        controller: loader.controller

        onAccepted: {
            loader.controller.title = selectedTitle;
            if (selectedFace) {
                loader.controller.faceId = selectedFace
            }
            loader.controller.loadPreset(selectedPreset);
            message.text = i18n("Loaded preset %1.", selectedTitle);
            message.visible = true
        }
    }

    NewStuff.Dialog {
        id: newPresetDialog
        downloadNewWhat: i18nc("@title", "Presets")
        configFile: "systemmonitor-presets.knsrc"
        onChangedEntriesChanged: loader.controller.availablePresetsModel.reload();
    }

    NewStuff.Dialog {
        id: newFaceDialog
        downloadNewWhat: i18nc("@title", "Display Styles")
        configFile: "systemmonitor-faces.knsrc"
        onChangedEntriesChanged: loader.controller.availableFacesModel.reload();
    }

    ColumnLayout {
        id: layout

        Kirigami.InlineMessage {
            id: message
            Layout.fillWidth: true
            showCloseButton: true
        }

        Label {
            Layout.fillWidth: true
            text: i18n("Title")

            CheckBox {
                id: showTitleCheckbox
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("Display")
                checked: true
            }
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: i18n("Title:")

            text: page.loader.controller.title

            Layout.fillWidth: true

            onTextEdited: page.loader.controller.title = text
        }

        ComboBox {
            id: faceCombo

            property string faceId: page.loader.controller.faceId

            model: page.loader.controller.availableFacesModel
            textRole: "display"
            currentIndex: {
                // TODO just make an indexOf invokable on the model?
                for (var i = 0; i < count; ++i) {
                    if (model.pluginId(i) === faceId) {
                        return i;
                    }
                }
                return -1;
            }
            onActivated: {
                page.loader.controller.faceId = model.pluginId(index);
            }

            Kirigami.FormData.label: i18n("Display Style:")
            Layout.fillWidth: true
        }

        Control {
            Layout.fillWidth: true
            contentItem: loader.controller.faceConfigUi

            Connections {
                target: loader.controller.faceConfigUi

                function onConfigurationChanged() {
                    loader.controller.faceConfigUi.saveConfig()
                    loader.dataObject.markDirty()
                }
            }
        }

        Label { text: "Total Sensors"; visible: loader.controller.supportsTotalSensors }

        Choices {
            Layout.fillWidth: true
            visible: loader.controller.supportsTotalSensors

            selected: loader.controller.totalSensors
            onSelectedChanged: loader.controller.totalSensors = selected

            colors: loader.controller.sensorColors
            onSelectColor: {
                colorDialog.destinationSensor = sensorId
                colorDialog.open()
            }
        }

        Label { text: "Sensors" }

        Choices {
            Layout.fillWidth: true

            selected: loader.controller.highPrioritySensorIds
            onSelectedChanged: loader.controller.highPrioritySensorIds = selected

            colors: loader.controller.sensorColors
            onSelectColor: {
                colorDialog.destinationSensor = sensorId
                colorDialog.open()
            }
        }

        Label { text: "Text-Only Sensors"; visible: loader.controller.supportsLowPrioritySensors }

        Choices {
            Layout.fillWidth: true
            visible: loader.controller.supportsLowPrioritySensors

            selected: loader.controller.lowPrioritySensors
            onSelectedChanged: loader.controller.lowPrioritySensorIds = selected

            colors: loader.controller.sensorColors
            onSelectColor: {
                colorDialog.destinationSensor = sensorId
                colorDialog.open()
            }
        }

        Item { Layout.fillHeight: true; width: 1 }
    }
}
