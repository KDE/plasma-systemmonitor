/*
 *   Copyright 2019 Marco Martin <mart@kde.org>
 *   Copyright 2019 Kai Uwe Broulik <kde@broulik.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces
import org.kde.ksysguard.table 1.0 as Table

Kirigami.FormLayout {
    id: root

    property alias cfg_askWhenKilling: confirmCheckbox.checked
    property int cfg_userFilterMode

    CheckBox {
        id: confirmCheckbox
        text: i18n("Confirm ending processes.")
    }

    ComboBox {
        id: showDefaultCombo
        Kirigami.FormData.label: i18n("By default show:")

        textRole: "key"
        valueRole: "value"

        onActivated: root.cfg_userFilterMode = currentValue
        Component.onCompleted: currentIndex = indexOfValue(root.cfg_userFilterMode)

        model: [
            { key: i18n("Own Processes"), value: Table.UserMode.Own },
            { key: i18n("User Processes"), value: Table.UserMode.User },
            { key: i18n("System Processes"), value: Table.UserMode.System },
            { key: i18n("All Processes"), value: Table.UserMode.All },
        ]
    }
}
