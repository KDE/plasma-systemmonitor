/*
 *   SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.table as Table

Kirigami.FormLayout {
    id: root

    property alias cfg_showToolBar: showToolBarCheckbox.checked
    property alias cfg_askWhenKilling: confirmCheckbox.checked
    property int cfg_userFilterMode

    CheckBox {
        id: showToolBarCheckbox
        text: i18nc("@option:check", "Show toolbar")
    }

    CheckBox {
        id: confirmCheckbox
        text: i18nc("@option:check", "Confirm ending processes")
    }

    ComboBox {
        id: showDefaultCombo
        Kirigami.FormData.label: i18nc("@label:listbox", "By default show:")

        textRole: "key"
        valueRole: "value"

        onActivated: root.cfg_userFilterMode = currentValue
        Component.onCompleted: currentIndex = indexOfValue(root.cfg_userFilterMode)

        model: [
            { key: i18nc("@item:inlistbox", "Own processes"), value: Table.ProcessSortFilterModel.ViewOwn },
            { key: i18nc("@item:inlistbox", "User processes"), value: Table.ProcessSortFilterModel.ViewUser },
            { key: i18nc("@item:inlistbox", "System processes"), value: Table.ProcessSortFilterModel.ViewSystem },
            { key: i18nc("@item:inlistbox", "All processes"), value: Table.ProcessSortFilterModel.ViewAll },
        ]
    }
}
