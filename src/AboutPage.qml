/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.6 as Kirigami

import org.kde.systemmonitor 1.0

Kirigami.AboutPage {
    aboutData: CommandLineArguments.aboutData
}
