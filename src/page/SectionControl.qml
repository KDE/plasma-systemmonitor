import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Container {
    id: control
    moveAxis: Qt.XAxis
    property PageDataObject sectionData

    signal addSection()
    signal addSeparator()

    implicitWidth: (sectionData.isSeparator ? toolbar.Layout.minimumWidth : 0) + leftPadding + rightPadding

    Kirigami.Separator {
        anchors {
            top: parent.top
            topMargin: parent.topPadding
            bottom: parent.bottom
            bottomMargin: parent.bottomPadding
            horizontalCenter: parent.horizontalCenter
        }
        visible: modelData.isSeparator
    }

    contentItem: FaceControl {
        anchors {
            fill: parent
            topMargin: parent.topPadding
            bottomMargin: parent.bottomPadding
            leftMargin: parent.leftPadding
            rightMargin: parent.rightPadding
        }
        activeItem: control.activeItem
        visible: !modelData.isSeparator
        dataObject: control.sectionData

        onSelect: control.select(item)
    }

    toolbar.addActions: [
        Action {
            text: i18n("Add Section")
            onTriggered: control.addSection()
        },
        Action {
            text: i18n("Add Separator")
            onTriggered: control.addSeparator()
        }
    ]
}
