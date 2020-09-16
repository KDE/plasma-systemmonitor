/*
 *   SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
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
            { key: i18n("Own Processes"), value: Table.ProcessSortFilterModel.ViewOwn },
            { key: i18n("User Processes"), value: Table.ProcessSortFilterModel.ViewUser },
            { key: i18n("System Processes"), value: Table.ProcessSortFilterModel.ViewSystem },
            { key: i18n("All Processes"), value: Table.ProcessSortFilterModel.ViewAll },
        ]
    }
}
