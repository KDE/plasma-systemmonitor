/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

import org.kde.kirigami 2.8 as Kirigami


Kirigami.FormLayout {
    id: root

    property alias cfg_showDetails: showDetailsCheckbox.checked
    property alias cfg_askWhenKilling: confirmCheckbox.checked

    CheckBox {
        id: showDetailsCheckbox
        text: i18nc("@option:check", "Show details panel")
    }

    CheckBox {
        id: confirmCheckbox
        text: i18nc("@option:check", "Confirm when quitting applications")
    }
}
