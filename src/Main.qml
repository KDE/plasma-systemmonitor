/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtCore
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.newstuff as NewStuff
import org.kde.config as KConfig
import org.kde.coreaddons as KCoreAddons

import org.kde.systemmonitor
import org.kde.ksysguard.page as Page

Kirigami.ApplicationWindow {
    id: app

    minimumWidth: Kirigami.Units.gridUnit * 34
    minimumHeight: Kirigami.Units.gridUnit* 27
    width: Kirigami.Units.gridUnit * 55
    height: Kirigami.Units.gridUnit * 39

    title: pageStack.currentItem?.title ?? ""

    header: contentItem.GraphicsInfo.api === GraphicsInfo.Software ? degradedWarning.createObject(app) : null

    Loader {
        active: !Kirigami.Settings.isMobile
        sourceComponent: GlobalMenu { }
    }

    Kirigami.PagePool {
        id: pagePoolObject
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        handleVisible: false
        modal: false
        collapsed: Page.Configuration.sidebarCollapsed
        onCollapsedChanged: Page.Configuration.sidebarCollapsed = collapsed
        interactiveResizeEnabled: true
        preferredSize: {
            if (Page.Configuration.sidebarWidth > 0) {
                return Page.Configuration.sidebarWidth
            } else {
                return Math.max(globalToolBar.implicitWidth + globalToolBar.Layout.minimumWidth + Kirigami.Units.smallSpacing * 3, Kirigami.Units.gridUnit * 10)
            }
        }
        onInteractiveResizingChanged: {
            if (!interactiveResizing) {
                Page.Configuration.sidebarWidth = preferredSize
            }
        }

        Behavior on width { NumberAnimation {id: collapseAnimation; duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }
        showHeaderWhenCollapsed: true

        Kirigami.Theme.colorSet: Kirigami.Theme.View

        header: ToolBar {
            implicitHeight: app.pageStack.globalToolBar.height

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
                        icon.name: "list-add"
                        text: i18nc("@action", "Add New Page…")
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: pageDialog.open()
                    },
                    Kirigami.Action {
                        id: editPagesAction
                        icon.name: "handle-sort"
                        text: i18nc("@action", "Edit or Remove pages…")
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: pageSortDialog.open()
                    },
                    Kirigami.Action {
                        id: exportAction
                        text: i18nc("@action", "Export Current Page…")
                        icon.name: "document-export"
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        enabled: !app.pageStack.currentItem?.edit ?? false
                        onTriggered: exportDialog.open()
                    },
                    Kirigami.Action {
                        icon.name: "document-import"
                        text: i18nc("@action", "Import Page…")
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: importDialog.open()
                    },
                    NewStuff.Action {
                        id: ghnsAction
                        text: i18nc("@action:inmenu", "Get New Pages…")
                        configFile: "plasma-systemmonitor.knsrc"
                        pageStack: app.pageStack.layers
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onEntryEvent: {
                            if (event === NewStuff.Engine.StatusChangedEvent) {
                                const result = Page.PageManager.ghnsEntryStatusChanged(entry)
                                if (result) {
                                    const pageAction = Array.from(globalDrawer.actions).find(action => action.controller.fileName === result.fileName)
                                    pageAction.trigger()
                                }
                            }
                        }
                    },
                    Kirigami.Action {
                        id: collapseAction
                        icon.name: app.globalDrawer.collapsed ? "view-split-left-right" : "view-left-close"
                        text: app.globalDrawer.collapsed ? i18nc("@action", "Expand Sidebar") : i18nc("@action", "Collapse Sidebar")
                        onTriggered: app.globalDrawer.collapsed = !app.globalDrawer.collapsed
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                    },
                    Kirigami.Action {
                        separator: true
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                    },
                    Kirigami.Action {
                        icon.name: "tools-report-bug";
                        text: i18nc("@action", "Report Bug…");
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: Qt.openUrlExternally(KCoreAddons.AboutData.bugAddress);
                    },
                    Kirigami.Action {
                        icon.name: "help-about-symbolic";
                        text: i18nc("@action", "About System Monitor");
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: app.pageStack.layers.push(Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutPage"))
                        enabled: app.pageStack.layers.depth <= 1
                    },
                    Kirigami.Action {
                        icon.name: "kde-symbolic";
                        text: i18nc("@action", "About KDE");
                        displayHint: Kirigami.DisplayHint.AlwaysHide
                        onTriggered: app.pageStack.layers.push(Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutKDEPage"))
                        enabled: app.pageStack.layers.depth <= 1
                    }
                ]
                Component.onCompleted: {
                    app.quitAction.displayHint = Kirigami.DisplayHint.AlwaysHide
                    actions.push(app.quitAction)
                }
            }

            Instantiator {
                model: ToolsModel { id: toolsModel }

                Kirigami.Action {
                    text: model.name
                    icon.name: model.icon
                    shortcut: model.shortcut
                    onTriggered: toolsModel.trigger(model.id)
                }

                onObjectAdded: (index, object) => {
                    toolsAction.children.push(object)
                }
            }
        }

        Instantiator {
            model: Page.PagesModel { id: pagesModel }

            Page.EditablePageAction {
                text: model.title
                icon.name: model.icon
                pagePool: pagePoolObject
                controller: model.data
                visible: !model.hidden
                onTriggered: {
                    Page.Configuration.lastVisitedPage = model.fileName

                    if (app.pageStack.layers.depth > 0) {
                        app.pageStack.layers.clear()
                    }
                }

                Component.onCompleted: {
                    if (CommandLineArguments.pageId && model.fileName === CommandLineArguments.pageId) {
                        trigger()
                    } else if (CommandLineArguments.pageName && model.title === CommandLineArguments.pageName) {
                        trigger()
                    } else if (Page.Configuration.startPage === model.fileName) {
                        trigger()
                    } else if (Page.Configuration.startPage == "" && Page.Configuration.lastVisitedPage === model.fileName) {
                        trigger()
                    }
                }
            }

            onObjectAdded: (index, object) => {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                actions.splice(index, 0, object)
                globalDrawer.actions = actions
            }

            onObjectRemoved: (index, object) => {
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
                var newPage = Page.PageManager.addPage(fileName, {title: name, icon: iconName, margin: margin})
                var row = newPage.data.insertChild(0, {name: "row-0", isTitle: false, title: "", heightMode: "balanced"})
                var column = row.insertChild(0, {name: "column-0", showBackground: true, noMargins: false})
                column.insertChild(0, {name: "section-0", isSeparator: false})
                newPage.savePage()

                const pageAction = Array.from(globalDrawer.actions).find(action => action.controller.fileName === newPage.fileName)
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
            startPage: Page.Configuration.startPage
            onAccepted: {
                Page.Configuration.startPage = startPage
                const currentPage = pageStack.currentItem.controller.fileName
                const indices = pagesModel.match(pagesModel.index(0, 0), Page.PagesModel.FileNameRole, currentPage, 1,  Qt.MatchExactly)
                if (indices.length === 0 || pagesModel.data(indices[0], Page.PagesModel.HiddenRole)) {
                    if (Page.Configuration.lastVisitedPage === currentPage) {
                        Page.Configuration.lastVisitedPage = "overview.page"
                    }
                    const startPage = Page.Configuration.startPage || Page.Configuration.lastVisitedPage
                    Array.prototype.find.call(globalDrawer.actions, action => action.controller.fileName === startPage).trigger()
                }
            }
        }
    }

    Page.DialogLoader {
        id: exportDialog
        sourceComponent: FileDialog {
            fileMode: FileDialog.SaveFile
            currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
            title: i18nc("@title:window %1 is the name of the page that is being exported", "Export %1", app.pageStack.currentItem.title)
            defaultSuffix: "page"
            nameFilters: [i18nc("Name filter in file dialog", "System Monitor page (*.page)")]
            onAccepted: app.pageStack.currentItem.controller.save(selectedFile)
        }
    }
    Page.DialogLoader {
        id: importDialog
        sourceComponent: FileDialog {
            currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
            title: i18nc("@title:window", "Import Page")
            defaultSuffix: "page"
            nameFilters: [i18nc("Name filter in file dialog", "System Monitor page (*.page)")]
            onAccepted: {
                const newPage = Page.PageManager.importPage(selectedFile)
                if (!newPage) {
                    return;
                }
                const pageAction = Array.from(globalDrawer.actions).find(action => action.controller.fileName === newPage.fileName)
                pageAction.trigger()
            }
        }
    }

    KConfig.WindowStateSaver {
        configGroupName: "MainWindow"
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

    pageStack.columnView.columnWidth: Kirigami.Units.gridUnit * 22

    onClosing: Page.PageManager.saveAll()
}
