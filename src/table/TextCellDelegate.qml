/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.2

import org.kde.kirigami 2.2 as Kirigami

BaseCellDelegate {
    id: delegate

    leftPadding: Kirigami.Units.smallSpacing

    property alias text: label.text

    contentItem: Label {
        id: label
        text:model.display != undefined ? model.display : ""
        maximumLineCount: 1
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    ToolTip.text: delegate.text
    ToolTip.delay: Kirigami.Units.toolTipDelay
    ToolTip.visible: hovered && label.truncated
}
