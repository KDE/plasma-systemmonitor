import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

ColumnLayout {
    id: root

    property PageDataObject pageData

    anchors.fill: parent

    spacing: Kirigami.Units.largeSpacing

    Repeater {
        model: PageDataModel { data: root.pageData }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !model.data.isTitle
            Layout.preferredHeight: model.data.isTitle ? title.height : 0

            Kirigami.Heading {
                id: title
                level: 2
                text: model.data.title
                visible: model.data.isTitle
            }

            GridLayout {
                anchors.fill: parent
                visible: !model.data.isTitle

                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: PageDataModel { data: model.data }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Kirigami.AbstractCard {
                            anchors.fill: parent
                            visible: model.data.showBackground
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: Kirigami.Units.largeSpacing

                            Repeater {
                                model: PageDataModel { data: model.data }

                                Loader {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: model.data.isSeparator ? false : true
                                    Layout.preferredWidth: model.data.isSeparator ? Kirigami.Units.devicePixelRatio : 0

                                    property var modelData: model

                                    sourceComponent: model.data.isSeparator ? separatorComponent : faceComponent
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: separatorComponent

        Kirigami.Separator { }
    }

    Component {
        id: faceComponent

        Control {
            contentItem: loader.controller.fullRepresentation

            FaceLoader {
                id: loader
                dataObject: modelData.data
            }
        }
    }
}
