import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

Control {
    id: control

    property bool raised: false
    property bool single: true

    property alias actions: toolbar.actions

    property Item activeItem
    readonly property bool active: activeItem == control

    property int index

    signal select(Item item)

    hoverEnabled: true

    z: raised ? 99 : 0

    leftPadding: Kirigami.Units.largeSpacing
    Behavior on leftPadding { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    rightPadding: Kirigami.Units.largeSpacing
    Behavior on rightPadding { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    bottomPadding: Kirigami.Units.largeSpacing
    Behavior on bottomPadding { NumberAnimation { duration: Kirigami.Units.shortDuration } }
    topPadding: control.active ? toolbar.height + Kirigami.Units.smallSpacing * 2 : Kirigami.Units.largeSpacing * 2
    Behavior on topPadding { NumberAnimation { duration: Kirigami.Units.shortDuration } }

    readonly property alias toolbar: toolbar

    background: Item {
        PlaceholderRectangle {
            id: backgroundRectangle
            anchors.fill: parent
            highlight: control.hovered
            onClicked: control.select(control)

            shadow.size: control.raised ? Kirigami.Units.gridUnit : 0
        }

        Kirigami.ActionToolBar {
            id: toolbar

            z: 1

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Kirigami.Units.smallSpacing
                leftMargin: Kirigami.Units.largeSpacing
                rightMargin: Kirigami.Units.largeSpacing
            }
            flat: false
            enabled: opacity >= 1
            opacity: control.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }
    }
}
