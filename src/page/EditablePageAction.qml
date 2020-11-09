/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0

Kirigami.PagePoolAction {
    id: action

    property PageDataObject pageData

    page: Qt.resolvedUrl("EditablePage.qml") + "?page=" + pageData.fileName

    initialProperties: {
        "pageData": action.pageData
    }
}
