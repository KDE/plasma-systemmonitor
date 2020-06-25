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

    topPadding: control.active ? toolbar.height + Kirigami.Units.smallSpacing * 2 : 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

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

    Component.onCompleted: {
        loader.controller.fullRepresentation.formFactor = Faces.SensorFace.Constrained;
        contentItem = loader.controller.fullRepresentation;
    }
}
