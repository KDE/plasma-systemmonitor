/*
 * SPDX-FileCopyrightText: 2025 Vladimir Pakhomchik <v.pahomchik@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import org.kde.ksysguard.process as Process

TextCellDelegate {
    id: delegate

    horizontalAlignment: {
        if (!treeView || !treeView.model) {
            return Text.AlignHCenter
        }
        const attribute = treeView.model.headerData(model.column, Qt.Horizontal, Process.ProcessDataModel.Attribute)
        if (attribute === "command") {
            return Text.AlignLeft
        }
        return Text.AlignHCenter
    }
}
