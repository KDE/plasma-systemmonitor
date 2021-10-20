/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtGraphicalEffects 1.0

import org.kde.kirigami 2.12 as Kirigami
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.page 1.0

ColumnLayout {
    id: root

    property PageDataObject pageData
    property var actionsFace

    spacing: rowSpacing // From parent Loader

    readonly property real balancedRowHeight: {
        let reservedSpace = 0;
        let minimumSpace = 0;
        let balancedCount = 0;
        let maximumCount = 0;

        for (let i in children) {
            let child = children[i]
            if (!child.hasOwnProperty("heightMode") || !child.hasOwnProperty("minimumContentHeight")) {
                continue
            }

            switch(child.heightMode) {
                case "minimum":
                    reservedSpace += child.minimumContentHeight
                    break;
                case "balanced":
                    minimumSpace = Math.max(child.minimumContentHeight, minimumSpace)
                    balancedCount += 1
                    break;
                case "maximum":
                    maximumCount += 1
                    break;
            }
        }

        // If there's nothing to balance, we can ignore the rest.
        if (balancedCount == 0) {
            return 0
        }

        // If there's any rows that are set to "maximum", use the largest
        // minimum size for balanced rows.
        if (maximumCount > 0) {
            return minimumSpace
        }

        // Note that "availableHeight" here comes from the parent loader and
        // represents the available size of the content area of the page.
        let balancedHeight = (availableHeight - reservedSpace - root.spacing * (children.length - 1)) / balancedCount
        return Math.max(balancedHeight, minimumSpace)
    }

    Repeater {
        model: PageDataModel { data: root.pageData }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: heightMode != "minimum"
            Layout.preferredHeight: 0
            Layout.minimumHeight: {
                if (heightMode == "minimum") {
                    return minimumContentHeight
                }

                if (heightMode == "balanced") {
                    return root.balancedRowHeight
                }

                return -1
            }
            Layout.maximumHeight: {
                if (heightMode == "minimum") {
                    return minimumContentHeight
                }

                if (heightMode == "balanced") {
                    return root.balancedRowHeight
                }

                return -1
            }

            readonly property real minimumContentHeight: {
                if (model.data.isTitle) {
                    return title.height
                }

                return rowContents.Layout.minimumHeight
            }

            readonly property string heightMode: {
                if (model.data.heightMode) {
                    return model.data.heightMode
                }

                if (model.data.isTitle) {
                    return "minimum"
                }

                return "balanced"
            }

            Kirigami.Heading {
                id: title
                anchors.left: parent.left
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
                        Layout.minimumHeight: columnContents.Layout.minimumHeight + columnContents.anchors.topMargin + columnContents.anchors.bottomMargin

                        Kirigami.AbstractCard {
                            anchors.fill: parent
                            visible: model.data.showBackground
                        }

                        RowLayout {
                            id: columnContents

                            anchors.fill: parent
                            anchors.margins: model.data.noMargins ? 0 : Kirigami.Units.largeSpacing

                            spacing: Kirigami.Units.largeSpacing

                            layer.enabled: model.data.showBackground && model.data.noMargins
                            layer.effect: OpacityMask {
                                maskSource: Kirigami.ShadowedRectangle {
                                    width: columnContents.width
                                    height: columnContents.height
                                    radius: Kirigami.Units.smallSpacing
                                }
                            }

                            Repeater {
                                model: PageDataModel { data: model.data }

                                Loader {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: model.data.isSeparator ? false : true
                                    Layout.preferredWidth: model.data.isSeparator ? 1 : 0
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
