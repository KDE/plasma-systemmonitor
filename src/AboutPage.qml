/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.6 as Kirigami

Kirigami.AboutPage {
    aboutData: {
        "displayName": i18n("System Monitor"),
        "componentName": "utilities-system-monitor",
        "shortDescription": i18n("An application to monitor system resources."),
        "homepage": "https://kde.org",
        "version": "2.19.08",
        "copyrightStatement" : "© 2018-2019 KSysGuard Development Team",
        "desktopFileName" : "org.kde.systemmonitor",
        "otherText": "",
        "authors": [
            {
                "name": "Arjen Hiemstra",
                "task": "Development",
                "emailAddress": "ahiemstra@heimr.nl"
            },
            {
                "name": "Uri Herrera",
                "task": "Design"
            },
            {
                "name": "Nate Graham",
                "task": "Design and QA"
            },
            {
                "name": "David Redondo",
                "task": "Development"
            },
            {
                "name": "Noah Davis",
                "task": "Design and QA"
            },
            {
                "name": "Marco Martin",
                "task": "Development"
            },
            {
                "name": "David Edmundson",
                "task": "Development"
            }
        ]
    }
}
