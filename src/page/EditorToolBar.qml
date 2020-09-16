/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

Kirigami.ActionToolBar {
    id: control

    property alias addActions: addAction.children
    property list<Action> extraActions

    property bool single: false
    property bool addVisible: true

    property int moveAxis: Qt.YAxis
    property Item moveTarget

    signal moved(int from, int to)
    signal removeClicked()

    actions: [addAction, moveAction, removeAction].concat(Array.prototype.map.call(extraActions, i => i))

    flat: false

    Kirigami.Action {
        id: addAction
        text: i18nc("@action", "Add")
        icon.name: "list-add"
        visible: control.addVisible
    }

    Kirigami.Action {
        id: moveAction

        displayComponent: MoveButton {
            axis: control.moveAxis
            target: control.moveTarget
            onMoved: control.moved(from, to)
            enabled: !control.single
        }
    }

    Kirigami.Action {
        id: removeAction
        enabled: !control.single
        text: i18nc("@action:button", "Remove")
        icon.name: "edit-delete"
        onTriggered: control.removeClicked()
    }
}
