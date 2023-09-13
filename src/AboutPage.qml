/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import org.kde.kirigamiaddons.formcard 1 as FormCard
import org.kde.systemmonitor

FormCard.AboutPage {
    aboutData: CommandLineArguments.aboutData
}
