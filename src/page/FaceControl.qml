/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami
import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.page 1.0

Container {
    id: control

    property alias dataObject: loader.dataObject

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    minimumContentHeight: contentItem ? contentItem.Layout.minimumHeight : 0
    minimumHeight: minimumContentHeight + topPadding + bottomPadding

    toolbar.visible: false

    onActiveChanged: {
        if (active) {
            applicationWindow().pageStack.push(Qt.resolvedUrl("FaceConfigurationPage.qml"), {"loader": loader})
        } else {
            if (activeItem instanceof FaceControl) {
                return
            } else {
                if (applicationWindow().pageStack.depth > 1) {
                    applicationWindow().pageStack.pop()
                }
            }
        }
    }

    FaceLoader {
        id: loader
    }

    MouseArea {
        anchors.fill: parent
        z: 99
        onClicked: control.select(control)
    }

    Component.onCompleted: updateContentItem()

    Connections {
        target: loader.controller
        function onFaceIdChanged() {
            control.updateContentItem()
        }

        function onMissingSensorsChanged() {
            control.missingSensorsChanged(dataObject.face, controller.title, loader.controller.missingSensors)
        }
    }

    function updateContentItem() {
        loader.controller.fullRepresentation.formFactor = Faces.SensorFace.Constrained;
        control.contentItem = loader.controller.fullRepresentation;

        if (loader.controller.missingSensors.length > 0) {
            control.missingSensorsChanged(dataObject.face, loader.controller.title, loader.controller.missingSensors)
        }
    }
}
