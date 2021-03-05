/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.2

import org.kde.kirigami 2.2 as Kirigami

Label {
    id: delegate

    leftPadding: Kirigami.Units.smallSpacing
    rightPadding: leftPadding

    text: model.display != undefined ? model.display : ""

    Kirigami.Theme.colorSet: background.selected ? Kirigami.Theme.Selection : Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    maximumLineCount: 1
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter

    background: CellBackground { view: delegate.TableView.view; row: model.row; column: model.column }
}
