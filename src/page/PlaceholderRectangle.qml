import QtQuick 2.14

import org.kde.kirigami 2.12 as Kirigami

Kirigami.ShadowedRectangle {
    id: rectangle

    property bool highlight: false
    signal clicked()

    color: Qt.rgba(
            Kirigami.Theme.highlightColor.r,
            Kirigami.Theme.highlightColor.g,
            Kirigami.Theme.highlightColor.b,
            highlight ? 0.5 : 0.25)

    border.width: highlight ? 2 : 1
    border.color: Kirigami.Theme.highlightColor

    radius: Kirigami.Units.smallSpacing

    shadow.yOffset: 2
    shadow.color: Qt.rgba(0, 0, 0, 0.5)
    Behavior on shadow.size { NumberAnimation { duration: Kirigami.Units.shortDuration } }

    MouseArea {
        anchors.fill: parent;
        onClicked: rectangle.clicked()
    }
}
