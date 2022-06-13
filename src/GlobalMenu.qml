/*
 * SPDX-FileCopyrightText: 2021 Felipe Kinoshita <kinofhek@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.15
import Qt.labs.platform 1.1 as Labs
import org.kde.newstuff 1.81 as NewStuff

import org.kde.systemmonitor 1.0

Labs.MenuBar {
    Labs.Menu {
        title: i18nc("@menu", "File")

        Labs.MenuItem {
            text: i18nc("@menu-action", "Add New Page…")
            icon.name: "list-add"
            onTriggered: pageDialog.open()
        }

        Labs.MenuItem {
            text: i18nc("@menu-action", "Import Page…")
            icon.name: "document-import"
            onTriggered: importDialog.open()
        }

        Labs.MenuItem {
            text: i18nc("@menu-action", "Export Current Page…")
            icon.name: "document-export"
            enabled: !app.pageStack.currentItem.edit
            onTriggered: exportDialog.open()
        }

        Labs.MenuItem {
            text: i18nc("@menu-action", "Get New Pages…")
            icon.name: "get-hot-new-stuff"
            onTriggered: ghnsAction.showHotNewStuff()
        }

        NewStuff.Action {
            id: ghnsAction
            configFile: "plasma-systemmonitor.knsrc"
            pageStack: app.pageStack.layers
            onEntryEvent: {
                if (event === NewStuff.Engine.StatusChangedEvent) {
                    pagesModel.ghnsEntryStatusChanged(entry)
                }
            }
        }

        Labs.MenuItem {
            text: i18nc("@menu-action", "Quit")
            icon.name: "gtk-quit"
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
    }

    Labs.Menu {
        title: i18nc("@menu", "View")

        Labs.MenuItem {
            text: app.globalDrawer.collapsed ? i18nc("@menu-action", "Expand Sidebar") : i18nc("@menu-action", "Collapse Sidebar")
            icon.name: app.globalDrawer.collapsed ? "view-split-left-right" : "view-left-close"
            onTriggered: app.globalDrawer.collapsed = !app.globalDrawer.collapsed
        }
    }

    Labs.Menu {
        title: i18nc("@menu", "Settings")

        Labs.MenuItem {
            text: i18nc("@menu-action", "Edit or Remove pages…")
            icon.name: "handle-sort"
            onTriggered: pageSortDialog.open()
        }
    }

    Labs.Menu {
        title: i18nc("@menu", "Help")

        Labs.MenuItem {
            text: i18nc("@menu-action", "Report Bug…")
            icon.name: "tools-report-bug"
            onTriggered: Qt.openUrlExternally(CommandLineArguments.aboutData.bugAddress);
        }

        Labs.MenuItem {
            text: i18nc("@menu-action", "About System Monitor")
            icon.name: "help-about"
            onTriggered: pageStack.layers.push("qrc:/AboutPage.qml")
            enabled: app.pageStack.layers.depth <= 1
        }
    }
}
