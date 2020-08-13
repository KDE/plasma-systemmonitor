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
                "task": "Coding",
                "emailAddress": "ahiemstra@heimr.nl"
            },
            {
                "name": "Uri Herrera",
                "task": "Design"
            },
            {
                "name": "Nate Graham",
                "task": "Design and QA"
            }
        ]
    }
}
