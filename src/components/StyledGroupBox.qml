import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import org.kde.kirigami 2.12 as Kirigami

// GroupBox {
Kirigami.AbstractCard {
    id: control

//     property alias color: background.color

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 0
    Layout.preferredWidth: 0

    topPadding: title != "" ? label.height + Kirigami.Units.gridUnit : Kirigami.Units.smallSpacing
    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: Kirigami.Units.smallSpacing
    bottomPadding: Kirigami.Units.smallSpacing

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.View

//     background: Rectangle {
//         id: background
//         x: control.leftPadding - control.rightPadding
//         y: control.topPadding - control.bottomPadding
//         width: parent.width - control.leftPadding + control.rightPadding
//         height: parent.height - control.topPadding + control.bottomPadding
//
//         color: Kirigami.Theme.backgroundColor
//
//         border.width: Math.floor(Kirigami.Units.devicePixelRatio)
//         border.color: Qt.tint(Kirigami.Theme.textColor, Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.7))
//
//         radius: Kirigami.Units.smallSpacing
//     }

//     label: Kirigami.Heading {
//         text: control.title
//         level: 2
//         visible: control.title != ""
//
//         Kirigami.Theme.inherit: false
//         Kirigami.Theme.colorSet: Kirigami.Theme.View
//     }
}
