/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import org.kde.kirigami 2.11 as Kirigami
import org.kde.newstuff 1.81 as NewStuff

import org.kde.systemmonitor 1.0
import org.kde.ksysguard.page 1.0 as Page

Kirigami.ApplicationWindow {
    id: app

    minimumWidth: 700
    minimumHeight: 550

    title: (pageStack.currentItem ? pageStack.currentItem.title + " - " : "") + i18n("System Monitor")

    header: contentItem.GraphicsInfo.api == GraphicsInfo.Software ? degradedWarning.createObject(app) : null

    Loader {
        active: !Kirigami.Settings.isMobile
        source: Qt.resolvedUrl("qrc:/GlobalMenu.qml")
    }

    Kirigami.PagePool {
        id: pagePoolObject
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        handleVisible: false
        modal: false
        width: collapsed ? globalToolBar.Layout.minimumWidth + Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 10
        Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }
        showHeaderWhenCollapsed: true

        Kirigami.Theme.colorSet: Kirigami.Theme.View

        header: ToolBar {
            Layout.fillWidth: true
            Layout.preferredHeight: app.pageStack.globalToolBar.preferredHeight

            leftPadding: globalDrawer.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: globalDrawer.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            Kirigami.ActionToolBar {
                id: globalToolBar

                anchors.fill: parent

                overflowIconName: "application-menu"

                actions: [
                    Kirigami.Action {
                        id: toolsAction
                        text: i18nc("@action", "Tools")
                        icon.name: "tools-symbolic"
                    },
                    Kirigami.Action {
                        id: editPagesAction
                        icon.name: "handle-sort"
                        text: i18nc("@action", "Edit or Remove pages…")
                        onTriggered: pageSortDialog.open()
                    },
                     Kirigami.Action {
                        id: exportAction
                        text: i18nc("@action", "Export Current Page…")
                        icon.name: "document-export"
                        enabled: !app.pageStack.currentItem.edit
                        onTriggered: exportDialog.open()
                    },
                    Kirigami.Action {
                        icon.name: "document-import"
                        text: i18nc("@action", "Import Page…")
                        onTriggered: importDialog.open()
                    },
                    NewStuff.Action {
                        id: ghnsAction
                        text: i18nc("@action:inmenu", "Get New Pages…")
                        configFile: "plasma-systemmonitor.knsrc"
                        pageStack: app.pageStack.layers
                        onEntryEvent: {
                            if (event == NewStuff.Engine.StatusChangedEvent) {
                                pagesModel.ghnsEntryStatusChanged(entry)
                            }
                        }
                    },
                    Kirigami.Action {
                        id: collapseAction
                        icon.name: app.globalDrawer.collapsed ? "view-split-left-right" : "view-left-close"
                        text: app.globalDrawer.collapsed ? i18nc("@action", "Expand Sidebar") : i18nc("@action", "Collapse Sidebar")
                        onTriggered: app.globalDrawer.collapsed = !app.globalDrawer.collapsed
                    },
                    Kirigami.Action {
                        separator: true
                    },
                    Kirigami.Action {
                        icon.name: "tools-report-bug";
                        text: i18nc("@action", "Report Bug…");
                        onTriggered: Qt.openUrlExternally(CommandLineArguments.aboutData.bugAddress);
                    },
                    Kirigami.Action {
                        icon.name: "help-about-symbolic";
                        text: i18nc("@action", "About System Monitor");
                        onTriggered: app.pageStack.layers.push("AboutPage.qml")
                        enabled: app.pageStack.layers.depth <= 1
                    }
                ]
                Component.onCompleted: actions.push(app.quitAction)
            }

            Instantiator {
                model: ToolsModel { id: toolsModel }

                Kirigami.Action {
                    text: model.name
                    icon.name: model.icon
                    shortcut: model.shortcut
                    onTriggered: toolsModel.trigger(model.id)
                }

                onObjectAdded: { toolsAction.children.push(object) }
                onObjectRemoved: { }
            }
        }

        actions: [
            Kirigami.Action {
                text: i18nc("@action", "Add New Page…")
                icon.name: "list-add"
                onTriggered: pageDialog.open()
            }
        ]

        Instantiator {
            model: Page.PagesModel { id: pagesModel }

            Page.EditablePageAction {
                text: model.title
                icon.name: model.icon
                pagePool: pagePoolObject
                pageData: model.data
                visible: !model.hidden
                onTriggered: {
                    config.lastVisitedPage = model.fileName

                    if (app.pageStack.layers.depth > 0) {
                        app.pageStack.layers.clear()
                    }
                }

                Component.onCompleted: {
                    if (CommandLineArguments.pageId && model.fileName == CommandLineArguments.pageId) {
                        trigger()
                    } else if (CommandLineArguments.pageName && model.title == CommandLineArguments.pageName) {
                        trigger()
                    } else if (config.startPage == model.fileName) {
                        trigger()
                    } else if (config.startPage == "" && config.lastVisitedPage == model.fileName) {
                        trigger()
                    }
                }
            }

            onObjectAdded: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                actions.splice(index, 0, object)
                globalDrawer.actions = actions
            }

            onObjectRemoved: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                var actionIndex = actions.indexOf(object)
                actions.splice(actionIndex, 1)
                globalDrawer.actions = actions
            }
        }

        contentData: [
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: globalContextMenu.popup(eventPoint.scenePosition.x, eventPoint.scenePosition.y, globalDrawer)
            },
            Menu {
                id: globalContextMenu
                modal: true

                MenuItem { action: editPagesAction }
                MenuItem { action: ghnsAction }
                MenuItem { action: collapseAction }
            }
        ]
    }

    Page.DialogLoader {
        id: pageDialog

        sourceComponent: Page.PageDialog {
            title: i18nc("@window:title", "Add New Page")

            onAccepted: {
                var fileName = name.toLowerCase().replace(" ", "_");
                var newPage = pagesModel.addPage(fileName, {title: name, icon: iconName, margin: margin})
                var row = newPage.insertChild(0, {name: "row-0", isTitle: false, title: ""})
                var column = row.insertChild(0, {name: "column-0", showBackground: true})
                column.insertChild(0, {name: "section-0", isSeparator: false})
                newPage.savePage()

                const pageAction = Array.from(globalDrawer.actions).find(action => action.pageData.fileName == newPage.fileName)
                pageAction.trigger()
                app.pageStack.currentItem.edit = true
            }
        }
    }

    Page.DialogLoader {
        id: pageSortDialog

        sourceComponent: Page.PageSortDialog {
            title: i18nc("@window:title", "Edit Pages")
            model: pagesModel
            startPage: config.startPage
            onAccepted: {
                config.startPage = startPage
                const currentPage = pageStack.currentItem.pageData.fileName
                const indices = pagesModel.match(pagesModel.index(0, 0), Page.PagesModel.FileNameRole, currentPage, 1,  Qt.MatchExactly)
                if (indices.length == 0 || pagesModel.data(indices[0], Page.PagesModel.HiddenRole)) {
                    if (config.lastVisitedPage == currentPage) {
                        config.lastVisitedPage = "overview.page"
                    }
                    const startPage = config.startPage || config.lastVisitedPage
                    Array.prototype.find.call(globalDrawer.actions, action => action.pageData.fileName == startPage).trigger()
                }
            }
        }
    }

    Page.DialogLoader {
        id: exportDialog
        sourceComponent: FileDialog {
            selectExisting: false
            folder: shortcuts.home
            title: i18nc("@title:window %1 is the name of the page that is being exported", "Export %1", app.pageStack.currentItem.title)
            defaultSuffix: "page"
            nameFilters: [i18nc("Name filter in file dialog", "System Monitor page (*.page)")]
            onAccepted: app.pageStack.currentItem.pageData.saveAs(fileUrl)
        }
    }
    Page.DialogLoader {
        id: importDialog
        sourceComponent: FileDialog {
            selectExisting: true
            folder: shortcuts.home
            title: i18nc("@title:window", "Import Page")
            defaultSuffix: "page"
            nameFilters: [i18nc("Name filter in file dialog", "System Monitor page (*.page)")]
            onAccepted: {
                const newPage = pagesModel.importPage(fileUrl)
                if (!newPage) {
                    return;
                }
                const pageAction = Array.from(globalDrawer.actions).find(action => action.pageData.fileName == newPage.fileName)
                pageAction.trigger()
            }
        }
    }

    Configuration {
        id: config
        property alias width: app.width
        property alias height: app.height
        property alias sidebarCollapsed: globalDrawer.collapsed
        property alias pageOrder: pagesModel.pageOrder
        property alias hiddenPages: pagesModel.hiddenPages
        property string startPage
        property string lastVisitedPage
    }

    Component {
        id: degradedWarning

        ToolBar {
            Kirigami.InlineMessage {
                anchors.fill: parent
                visible: true
                type: Kirigami.MessageType.Warning
                text: i18n("System Monitor has fallen back to software rendering because hardware acceleration is not available, and visual glitches may appear. Please check your graphics drivers.")
            }
        }
    }

    pageStack.columnView.columnWidth: Kirigami.Units.gridUnit * 19
}
