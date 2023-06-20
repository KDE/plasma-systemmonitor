/*
 *   SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
 *   SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
 *   SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *   SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>
 *
 *   SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.8 as Kirigami

import org.kde.ksysguard.faces 1.0 as Faces


Faces.SensorFace {
    id: root
    contentItem: Kirigami.Icon {
        source: "view-process-system"
    }
}
