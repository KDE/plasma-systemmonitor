import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.page 1.0

Kirigami.Page {
    id: page

    property FaceLoader loader

    property int activeSection: 0

    title: i18n("Configure %1", loader.controller.title)

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Kirigami.ColumnView.fillWidth: false

    actions.main: Kirigami.Action {
        icon.name: "dialog-close"
        text: i18n("Close")
        onTriggered: applicationWindow().pageStack.pop()
    }

    actions.contextualActions: [
        Kirigami.Action {
            text: i18n("Load Preset...")
        },
        Kirigami.Action {
            text: i18n("Get new presets...")
        },
        Kirigami.Action {
            text: i18n("Save Preset...")
        },
        Kirigami.Action { separator: true },
        Kirigami.Action {
            text: i18n("Get new display styles...")
        }
    ]

    ScrollView {
        id: scrollView
        anchors.fill: parent

        Item {
            width: scrollView.width - scrollView.leftPadding - scrollView.rightPadding
            implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing

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
                    contentItem: loader.controller.faceConfigUi
                }

                Label { text: "Total Sensors"; visible: loader.controller.supportsTotalSensors }

                Choices {
                    Layout.fillWidth: true
                    visible: loader.controller.supportsTotalSensors
                }

                Label { text: "Sensors" }

                Choices {
                    Layout.fillWidth: true
                }

                Label { text: "Text-Only Sensors"; visible: loader.controller.supportsLowPrioritySensors }

                Choices {
                    Layout.fillWidth: true
                    visible: loader.controller.supportsLowPrioritySensors
                }

                Item { Layout.fillHeight: true; width: 1 }
            }
        }
    }
}
