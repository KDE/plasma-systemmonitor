/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.page 1.0

ColumnLayout {
    id: root

    property PageDataObject pageData
    property var actionsFace


    spacing: Kirigami.Units.largeSpacing

    readonly property real minimumRowHeight: {
        // If we just use the minimumHeight of a row for the row's minimum height
        // we end up with differently sized rows since some rows will be able to
        // be sized smaller than others. To avoid this, we determine the maximum
        // minimumHeight of all rows and use that value as minimumHeight for all
        // rows.
        let result = 0;
        for (let i in children) {
            let child = children[i]
            if (child.hasOwnProperty("minimumContentHeight")) {
                result = Math.max(result, child.minimumContentHeight)
            }
        }
        return result;
    }

    Repeater {
        model: PageDataModel { data: root.pageData }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !model.data.isTitle
            Layout.preferredHeight: model.data.isTitle ? title.height : 0
            Layout.minimumHeight: model.data.isTitle ? title.height : root.minimumRowHeight

            readonly property real minimumContentHeight: model.data.isTitle ? title.height : rowContents.Layout.minimumHeight

            Kirigami.Heading {
                anchors.left: parent.left
                id: title
                level: 2
                text: model.data.title ? model.data.title : ""
                visible: model.data.isTitle
            }

            GridLayout {
                id: rowContents

                anchors.fill: parent
                visible: !model.data.isTitle

                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: PageDataModel { data: model.data }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: columnContents.Layout.minimumHeight

                        Kirigami.AbstractCard {
                            anchors.fill: parent
                            visible: model.data.showBackground
                        }

                        RowLayout {
                            id: columnContents

                            anchors.fill: parent
                            anchors.margins: model.data.showBackground ? Kirigami.Units.smallSpacing : 0
                            spacing: Kirigami.Units.largeSpacing

                            Repeater {
                                model: PageDataModel { data: model.data }

                                Loader {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: model.data.isSeparator ? false : true
                                    Layout.preferredWidth: model.data.isSeparator ? Kirigami.Units.devicePixelRatio : 0
                                    Layout.minimumHeight: item ? item.Layout.minimumHeight : 0

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
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0

            Layout.minimumHeight: contentItem ? contentItem.Layout.minimumHeight : 0

            FaceLoader {
                id: loader
                dataObject: modelData.data
            }

            Component.onCompleted: {
                loader.controller.fullRepresentation.formFactor = Faces.SensorFace.Constrained;
                contentItem = loader.controller.fullRepresentation

                if (root.pageData.actionsFace == modelData.data.face) {
                    root.actionsFace = loader.controller.fullRepresentation
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: WidgetExporter.plasmashellAvailable
                onTapped: {
                    const point = parent.mapToItem(contextMenu.parent, eventPoint.position)
                    contextMenu.x = point.x
                    contextMenu.y = point.y
                    contextMenu.loader = loader
                    contextMenu.open()
                }
            }
        }
    }
    Menu {
        id: contextMenu
        property QtObject loader
        MenuItem {
            icon.name: "document-export"
            text: i18nc("@action", "Add Chart as Desktop Widget")
            onTriggered: {
                WidgetExporter.exportAsWidget(contextMenu.loader)
            }
        }
    }
}
